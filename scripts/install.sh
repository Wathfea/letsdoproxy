#!/bin/bash

# This script will install 3proxy on CentOS 8
# It will also configure it to run on boot

# Install wget
echo "Installing apps... Please wait."
sudo yum -y install wget >/dev/null
sudo yum -y install nano >/dev/null
sudo yum -y install iptables >/dev/null
sudo yum -y install gcc >/dev/null
sudo yum -y install net-tools >/dev/null
sudo yum -y install bsdtar >/dev/null
sudo yum -y install zip >/dev/null
sudo yum -y install make >/dev/null

# Create a reboot persistence file
echo "Creating reboot persistence file..."
touch /home/3proxy_reboot_persistence

#sleep 2 seconds
sleep 2

if [ -f /home/3proxy_reboot_persistence ]; then
  # Disable SELinux
  echo "Disabling SELinux..."
  sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

  #Download startup.sh
  echo "Downloading startup.sh..."
  wget https://raw.githubusercontent.com/Wathfea/letsdoproxy/main/scripts/startup.sh --output-document=/etc/init.d/3proxy_startup
  # Set the permission for run the startup script
  echo "Setting permissions..."
  sudo chmod +x /etc/init.d/3proxy_startup
  # Add the startup script to the boot sequence
  echo "Adding startup script to boot sequence..."
  chkconfig --add 3proxy_startup

  #Ask the user how many proxies they want to install and save the answer into a file
  echo "How many proxies do you want to install?"
  read PROXY_COUNT
  echo $PROXY_COUNT > /home/3proxy_proxies_number
  #sleep 2 seconds
  sleep 2

  if [ -f /home/3proxy_proxies_number ]; then
      # Reboot
      echo "Rebooting... Please reconnect after 5 minutes."
      sleep 5
      reboot
  else
      echo "Something went wrong. 3proxy_proxies_number is missing. Please try again."
  fi
else
  echo "Something went wrong. 3proxy_reboot_persistence is missing. Please try again."
fi
