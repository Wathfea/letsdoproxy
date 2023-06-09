Redirect connections from different ports at one ipv4 address to unique random ipv6 address from \64 subnetwork. Based on 3proxy

![cover](cover.svg)

## Requirements
- Centos 8 on Vultr VPS (Only Vultr is working now)
- Ipv6 \64 enabled on your VPS

## Installation
Register a VPS on [Vultr *100$ free*](https://www.vultr.com/?ref=9406148-8H) and create a Centos 8 setup with ipv6 enabled

1. `bash <(curl -s "https://raw.githubusercontent.com/Wathfea/letsdoproxy/main/scripts/install.sh")`
2. The script will reboot your server after installation, so you will need to reconnect to it

3. After installation dowload the file `proxy.zip`, you can find the url and password like: ```cat /home/proxy-installer/proxies_zip_url.txt ``` ```cat /home/proxy-installer/proxies_zip_password.txt ```
   * File structure: `IP4:PORT:LOGIN:PASS`
   * You can use this online [util](http://buyproxies.org/panel/format.php
) to change proxy format as you like

4. If you need IPV4 proxies you can use [this](https://buyproxies.org/panel/aff.php?aff=2766) service


<a href="https://www.buymeacoffee.com/repgen"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=repgen&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>

## Test your proxy

Install [FoxyProxy](https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/) in Firefox
![Foxy](foxyproxy.png)

Open [ipv6-test.com](http://ipv6-test.com/) and check your connection
![check ip](check_ip.png)
