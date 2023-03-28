#!/bin/bash
#
# 3proxy_startup       This starts and stops the 3proxy startup script.
#
# chkconfig: 23456 20 80
# description: 3proxy startup script


touch /home/3proxy_install_log
echo "3proxy_startup" >> /home/3proxy_install_log

if [ -f /home/3proxy_reboot_persistence ]; then
  # Wait for the network to come up
  while ! ping -c 1 8.8.8.8 &> /dev/null; do
      sleep 1
  done

  echo "In the if" >> /home/3proxy_install_log
  # remove the flag file so the script doesn't run again after the next reboot
  rm /home/3proxy_reboot_persistence

  random() {
  	tr </dev/urandom -dc A-Za-z0-9 | head -c5
  	echo
  }

  array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
  main_interface=$(ip route get 8.8.8.8 | awk -- '{printf $5}')

  gen64() {
  	ip64() {
  		echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
  	}
  	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
  }

  install_3proxy() {
      echo "installing 3proxy" >> /home/3proxy_install_log
      mkdir -p /3proxy
      cd /3proxy
      URL="https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz"
      echo "Downloading 3proxy from $URL" >> /home/3proxy_install_log
      wget -qO- $URL | bsdtar -xvf-
      cd 3proxy-0.9.3
      echo "Compiling 3proxy" >> /home/3proxy_install_log
      make -f Makefile.Linux
      mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
      touch /usr/local/etc/3proxy/logs/3proxy.log
      touch /usr/local/etc/3proxy/bin/license.txt
      echo "3proxy-0.9.3 END-USER LICENSE AGREEMENT (EULA)
            ==============================================

            Please read this agreement carefully before using 3proxy software.

            By using 3proxy software, you agree to be bound by the terms and conditions of this agreement.

            If you do not agree to the terms and conditions of this agreement, do not use the software.

            END-USER LICENSE AGREEMENT FOR 3proxy software

            1. 3proxy is free software distributed under the terms of the GNU GPL.

            2. 3proxy is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

            3. You should have received a copy of the GNU General Public License along with 3proxy; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

            This is a confirmation that you have read and accepted the terms of the 3proxy-0.9.3 END-USER LICENSE AGREEMENT (EULA).

      " > /usr/local/etc/3proxy/bin/license.txt

      mv /3proxy/3proxy-0.9.3/bin/3proxy /usr/local/etc/3proxy/bin/
      chown -R nobody:nobody /usr/local/etc/3proxy
      chmod -R +x /usr/local/etc/3proxy
      echo "Generating config" >> /home/3proxy_install_log
      wget https://raw.githubusercontent.com/Wathfea/letsdoproxy/main/scripts/3proxy.service-Centos8 --output-document=/3proxy/3proxy-0.9.3/scripts/3proxy.service2
      cp /3proxy/3proxy-0.9.3/scripts/3proxy.service2 /usr/lib/systemd/system/3proxy.service
      systemctl link /usr/lib/systemd/system/3proxy.service
      systemctl daemon-reload
      echo "* hard nofile 999999" >>  /etc/security/limits.conf
      echo "* soft nofile 999999" >>  /etc/security/limits.conf
      echo "net.ipv6.conf.$main_interface.proxy_ndp=1" >> /etc/sysctl.conf
      echo "net.ipv6.conf.all.proxy_ndp=1" >> /etc/sysctl.conf
      echo "net.ipv6.conf.default.forwarding=1" >> /etc/sysctl.conf
      echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
      echo "net.ipv6.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
      echo "Reloading system config" >> /home/3proxy_install_log
      sysctl -p
      if systemctl status firewalld >/dev/null 2>&1; then
          echo "Firewalld is installed. Now disable it" >> /home/3proxy_install_log
          systemctl stop firewalld
          systemctl disable firewalld
      else
          echo "Firewalld is not installed." >> /home/3proxy_install_log
      fi

      cd $WORKDIR
  }

  gen_3proxy() {
      cat <<EOF
daemon
maxconn 4000
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456
flush
#log /usr/local/etc/3proxy/logs/3proxy.log D
#logformat "L%y%m%d-%H:%M:%S.%. %E %U %C:%c %R:%r %O %I %h %T"
auth strong

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
  }

  gen_proxy_file_for_user() {
      cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' ${WORKDATA})
EOF
  }

  upload_proxy() {
      cd $WORKDIR
      local PASS=$(random)
      zip --password $PASS proxy.zip proxy.txt
      URL=$(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip)

      echo "Proxy is ready! Format IP:PORT:LOGIN:PASS" >> /home/3proxy_install_log
      echo "Download zip archive from: ${URL}" >> /home/3proxy_install_log
      echo $URL > $WORKDIR/proxies_zip_url.txt
      echo "Password: ${PASS}" >> /home/3proxy_install_log
      echo $PASS > $WORKDIR/proxies_zip_pass.txt
  }

  gen_data() {
      seq $FIRST_PORT $LAST_PORT | while read port; do
          echo "$(random)/$(random)/$IP4/$port/$(gen64 $IP6)"
      done
  }

  gen_iptables() {
      cat <<EOF
$(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA})
EOF
  }

  gen_ifconfig() {
      cat <<EOF
$(awk -F "/" '{print "ifconfig '$main_interface' inet6 add " $5 "/64"}' ${WORKDATA})
EOF
  }

  # INIT STARTS HERE
  install_3proxy

  WORKDIR="/home/proxy-installer"
  WORKDATA="${WORKDIR}/data.txt"
  mkdir $WORKDIR && cd $_

  IP4=$(curl -4 -s icanhazip.com)
  IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

  echo "Internal ip = ${IP4}. Exteranl sub for ip6 = ${IP6}" >> /home/3proxy_install_log

  #Read the saved number out of the file /home/3proxy_proxies_number and save the value in the variable COUNT
  COUNT=$(cat /home/3proxy_proxies_number)

  FIRST_PORT=10000
  LAST_PORT=$(($FIRST_PORT + $COUNT))

  gen_data >$WORKDIR/data.txt
  gen_iptables >$WORKDIR/boot_iptables.sh
  gen_ifconfig >$WORKDIR/boot_ifconfig.sh
  echo NM_CONTROLLED="no" >> /etc/sysconfig/network-scripts/ifcfg-${main_interface}
  chmod +x $WORKDIR/boot_*.sh /etc/rc.local

  gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

  cat >>/etc/rc.local <<EOF
echo "Bash is running"
systemctl start NetworkManager.service
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 999999
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &
EOF

  bash /etc/rc.local

  #Start 3proxy in this session
  echo "Setting up ulimit" >> /home/3proxy_install_log
  ulimit -n 999999

  echo "Starting service" >> /home/3proxy_install_log
  /usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg &

  gen_proxy_file_for_user

  upload_proxy
fi
