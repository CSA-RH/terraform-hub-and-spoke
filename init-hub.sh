#!/bin/bash
echo "Adding ip_forwarding to /etc/sysctl.d/99-sysctl.conf file"
echo net.ipv4.ip_forward = 1 >> /etc/sysctl.d/99-sysctl.conf
echo "Disabling firewall-cmd"
systemctl disable --now firewalld