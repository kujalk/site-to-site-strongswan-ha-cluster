#!/usr/bin/env bash

echo "Going to sleep for 1 mins"
sleep 60s

echo "Strongswan installation started"
sudo apt update && sudo apt upgrade -y
sudo apt install strongswan -y
sudo apt  install awscli -y
sudo apt install jq -y 

region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
# Get the values from AWS Parameter Store
echo "Querying the paramter store"
primarycidr=$(aws ssm get-parameter --name "/strongswan/config/${primarysite}_cidr" --query "Parameter.Value" --output text --region $region)
primarysitepublicip=$(aws ssm get-parameter --name "/strongswan/config/${primarysite}_publicip" --query "Parameter.Value" --output text --region $region)
primarysiteprivateip=$(aws ssm get-parameter --name "/strongswan/config/${primarysite}_privateip" --query "Parameter.Value" --output text --region $region)

secondarycidr=$(aws ssm get-parameter --name "/strongswan/config/${secondarysite}_cidr" --query "Parameter.Value" --output text --region $region)
secondarysitepublicip=$(aws ssm get-parameter --name "/strongswan/config/${secondarysite}_publicip" --query "Parameter.Value" --output text --region $region)
secondarysiteprivateip=$(aws ssm get-parameter --name "/strongswan/config/${secondarysite}_privateip" --query "Parameter.Value" --output text --region $region)

psk=$(aws ssm get-parameter --name "/strongswan/config/psk" --with-decryption --query "Parameter.Value" --query "Parameter.Value" --output text --region $region)

# Create a temporary configuration fileprimarysite
echo "Updating the variable to the files"
echo "primarycidr=$primarycidr" > /home/ubuntu/conf.temp
echo "primarysitepublicip=$primarysitepublicip" >> /home/ubuntu/conf.temp
echo "primarysiteprivateip=$primarysiteprivateip" >> /home/ubuntu/conf.temp
echo "secondarycidr=$secondarycidr" >> /home/ubuntu/conf.temp
echo "secondarysitepublicip=$secondarysitepublicip" >> /home/ubuntu/conf.temp
echo "secondarysiteprivateip=$secondarysiteprivateip" >> /home/ubuntu/conf.temp
echo "psk=$psk" >> /home/ubuntu/conf.temp

echo "$primarysitepublicip $secondarysitepublicip : PSK \"$psk\"" >> /etc/ipsec.secrets 

echo "
config setup
        charondebug=\"all\"
        uniqueids=yes
        strictcrlpolicy=no

# connection to siteB datacenter
conn siteA-to-siteB
  authby=secret
  left=%defaultroute
  leftid=$primarysitepublicip
  leftsubnet=$primarycidr
  right=$secondarysitepublicip
  rightsubnet=$secondarycidr
  ike=aes256-sha2_256-modp1024!
  esp=aes256-sha2_256!
  keyingtries=0
  ikelifetime=1h
  lifetime=8h
  dpddelay=30
  dpdtimeout=120
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