#!/usr/bin/env bash

echo "Going to sleep for 1 mins"
sleep 60s

echo "Strongswan installation started"
sudo apt update && sudo apt upgrade -y
sudo apt install strongswan -y
sudo apt install keepalived -y 
sudo apt  install awscli -y
sudo apt install jq -y 

echo "${primarysitepublicip} ${secondarysitepublicip} : PSK \"${psk}\"" >> /etc/ipsec.secrets 

echo "
config setup
        charondebug=\"all\"
        uniqueids=yes
        strictcrlpolicy=no

# connection to siteB datacenter
conn siteA-to-siteB
  authby=secret
  left=%defaultroute
  leftid=${primarysitepublicip}
  leftsubnet=${primarycidr}
  right=${secondarysitepublicip}
  rightsubnet=${secondarycidr}
  ike=aes256-sha2_256-modp1024!
  esp=aes256-sha2_256!
  keyingtries=%forever
  closeaction=restart
  ikelifetime=1h
  lifetime=8h
  dpddelay=30
  dpdtimeout=1800
  dpdaction=restart
  auto=start
" > /etc/ipsec.conf

ipsec restart
ipsec status 
ipsec statusall

# Add the IP forwarding configuration to sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
echo "IP forwarding has been enabled and will persist across reboots."

#notify script
echo "
#!/bin/bash

if [ \$3 = \"MASTER\" ]; then

  region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

  # Disassociate Elastic IP from current instance
  current_instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

  if [ -n \$current_instance_id ]; then
    aws ec2 disassociate-address --public-ip ${primarysitepublicip} --region \$region
    aws ec2 associate-address --public-ip ${primarysitepublicip} --instance-id \$current_instance_id --region \$region
    echo \"Elastic IP disassociated from previous instance and associated with current instance.\"

    echo \"Updating the RouteTable\"
    routetableid=$(aws ec2 describe-route-tables --query "RouteTables[?RouteTableId && Tags[?Key=='Name' && Value=='${routetablename}']].{RouteTableId:RouteTableId}" --output text --region \$region)
    aws ec2 replace-route --route-table-id \$routetableid --destination-cidr-block ${secondarycidr} --instance-id \$current_instance_id --region \$region

    echo \"Restarting ipsec service\" 
    sudo ipsec start
    sudo ipsec restart

  else
    echo \"Current instance ID failed to obtain\"
  fi

elif [ \$3 = \"BACKUP\" ]; then
  # Stop IPsec service
  sudo ipsec stop
  echo \"IPsec service stopped.\"

else
  echo \"Invalid argument. Use 'master' or 'slave'.\"
  exit 1
fi

" > /etc/keepalived/failover.sh

sudo chmod +x /etc/keepalived/failover.sh

echo "
vrrp_script check_strongswan
{
    script \"pgrep charon\"
    interval 2
}

vrrp_instance VI_1
{
    debug 2
    interface eth0
    state BACKUP
    virtual_router_id 1
    priority 100
    unicast_src_ip ${current_privateip}

    unicast_peer
    {
        ${peer_privateip}
    }

    track_script
    {
        check_strongswan
    }

    notify \"/etc/keepalived/failover.sh\"
}
" > /etc/keepalived/keepalived.conf

sudo systemctl restart keepalived