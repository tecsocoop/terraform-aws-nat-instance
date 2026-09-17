#!/bin/bash

sudo apt update
sudo apt upgrade -y 

#### SSM Agent

sudo apt install -y wget
wget https://s3.${region}.amazonaws.com/amazon-ssm-${region}/latest/debian_amd64/amazon-ssm-agent.deb -O /tmp/amazon-ssm-agent.deb
sudo dpkg -i /tmp/amazon-ssm-agent.deb
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

#### Iptables 

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

sudo apt install iptables-persistent -y

sudo /usr/sbin/iptables -t nat -A POSTROUTING -s ${vpc_cidr} -j MASQUERADE ###### VARIABLE VPC

sudo bash -c "iptables-save > /etc/iptables/rules.v4"

#### IP forwarding (persistent across reboots)

sudo bash -c 'cat > /etc/systemd/system/nat-ip-forward.service' <<'EOF'
[Unit]
Description=Enable IPv4 forwarding for NAT instance
After=systemd-networkd.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/sysctl -w net.ipv4.ip_forward=1
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now nat-ip-forward.service

#For reference
sudo bash -c 'echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf'
