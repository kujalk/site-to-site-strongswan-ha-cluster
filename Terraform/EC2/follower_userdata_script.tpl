#!/usr/bin/env bash

echo "Going to sleep for 300s, to avoid race condition"
sleep 300s

echo "Strongswan installation started"
sudo apt update && sudo apt upgrade -y
sudo apt install strongswan -y
sudo apt install keepalived -y 
sudo apt  install awscli -y
sudo apt install jq -y 

echo "${current_privateip} ${secondary_master_ip} : PSK \"${psk}\"" >> /etc/ipsec.secrets 

echo "
config setup
        charondebug=\"all\"
        uniqueids=yes
        strictcrlpolicy=no

# connection to siteB datacenter
conn siteA-to-siteB
  authby=secret
  left=%defaultroute
  leftid=${current_privateip}
  leftsubnet=${primarycidr}
  right=${secondary_master_ip}
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

# Please not that restart/start/stop of ipsec service with in this notifiy script causing keepalived dameon not to work properly

if [ \$3 = \"MASTER\" ]; then

  region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

  # Disassociate Elastic IP from current instance
  current_instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

  if [ -n \$current_instance_id ]; then

    echo \"Updating the RouteTable\"

    # Updating the private route table
    pri_routetable=${pri_routetablename}
    pri_routetableid=\$(aws ec2 describe-route-tables --query \"RouteTables[?RouteTableId && Tags[?Key=='Name' && Value=='\$pri_routetable']].{RouteTableId:RouteTableId}\" --output text --region \$region)
    aws ec2 replace-route --route-table-id \$pri_routetableid --destination-cidr-block ${secondarycidr} --instance-id \$current_instance_id --region \$region
    
    # Updating the public route table
    pub_routetable=${pub_routetablename}
    pub_routetableid=\$(aws ec2 describe-route-tables --query \"RouteTables[?RouteTableId && Tags[?Key=='Name' && Value=='\$pub_routetable']].{RouteTableId:RouteTableId}\" --output text --region \$region)
    aws ec2 replace-route --route-table-id \$pub_routetableid --destination-cidr-block ${secondarycidr} --instance-id \$current_instance_id --region \$region
    
    # Updating the other site route table for pcx 
    site2_routetable=${site2_routetablename}
    site2_routetableid=\$(aws ec2 describe-route-tables --query \"RouteTables[?RouteTableId && Tags[?Key=='Name' && Value=='\$site2_routetable']].{RouteTableId:RouteTableId}\" --output text --region \$region)

    # Query the existing route and check if it exists
    aws ec2 describe-route-tables --route-table-ids \$site2_routetableid --query \"RouteTables[0].Routes[?DestinationCidrBlock=='${peer_privateip}/32']\" --output text --region \$region | grep -q '${peer_privateip}/32'

    # Check the exit status of the previous command
    if [ \$? -eq 0 ]; then
        # Route exists, delete it
        aws ec2 delete-route --route-table-id \$site2_routetableid --destination-cidr-block ${peer_privateip}/32 --region \$region
    fi

    # Create a new route in other site
    aws ec2 create-route --route-table-id \$site2_routetableid --destination-cidr-block ${current_privateip}/32 --vpc-peering-connection-id ${peering_id} --region \$region

    ssmid=\$(aws ssm send-command --document-name \"AWS-RunShellScript\" --query \"Command.CommandId\" --output text --parameters commands=\"sh /etc/keepalived/ssmscript.sh ${peer_privateip} ${current_privateip}\" --targets \"Key=tag:SiteName,Values=${secondary_tag}\" --region \$region)
    echo \"SSM document triggered with id \$ssmid\"

  else
    echo \"Current instance ID failed to obtain\"
  fi

elif [ \$3 = \"BACKUP\" ]; then
  # sudo ipsec start
  echo \"IPsec service stopped.\"
  exit 0

else
  echo \"Invalid argument. Use 'master' or 'slave'.\"
  # sudo ipsec start
  exit 0
fi

" > /etc/keepalived/failover.sh

sudo sed -i '1{/^$/d}' /etc/keepalived/failover.sh
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
    priority 10
    advert_int 5
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

echo "
#!/bin/bash

# Update /etc/ipsec.conf
sed -i \"s/\$1/\$2/\" /etc/ipsec.conf

# Update /etc/ipsec.secrets
sed -i \"s/\$1/\$2/\" /etc/ipsec.secrets

# Restart the service
sudo ipsec restart            
" > /etc/keepalived/ssmscript.sh

sudo sed -i '1{/^$/d}' /etc/keepalived/ssmscript.sh
sudo chmod +x /etc/keepalived/ssmscript.sh

sudo systemctl enable keepalived
sudo systemctl enable ipsec

echo "Going to sleep, 180s and will restart the keepalived service"
sleep 180s
sudo systemctl restart keepalived

echo "All init script done"