#!/bin/sh

exec > /root/setup.log 2>&1

# dont remove!
echo "Installed Time: $(date '+%A, %d %B %Y %T')"
echo "###############################################"
echo "Processor: $(ubus call system board | grep '\"system\"' | sed 's/ \+/ /g' | awk -F'\"' '{print $4}')"
echo "Device Model: $(ubus call system board | grep '\"model\"' | sed 's/ \+/ /g' | awk -F'\"' '{print $4}')"
echo "Device Board: $(ubus call system board | grep '\"board_name\"' | sed 's/ \+/ /g' | awk -F'\"' '{print $4}')"
sed -i "s#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' / ':'')+(luciversion||''),#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' build OpenWrt [Ouc3kNF6]':''),#g" /www/luci-static/resources/view/status/include/10_system.js
if grep -q "ImmortalWrt" /etc/openwrt_release; then
  sed -i "s/\(DISTRIB_DESCRIPTION='ImmortalWrt [0-9]*\.[0-9]*\.[0-9]*\).*'/\1'/g" /etc/openwrt_release
  echo Branch version: "$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')"
elif grep -q "OpenWrt" /etc/openwrt_release; then
  sed -i "s/\(DISTRIB_DESCRIPTION='OpenWrt [0-9]*\.[0-9]*\.[0-9]*\).*'/\1'/g" /etc/openwrt_release
  echo Branch version: "$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')"
fi
echo "Tunnel Installed: $(opkg list-installed | grep -e luci-app-openclash -e luci-app-neko -e luci-app-passwall | awk '{print $1}' | tr '\n' ' ')"
echo "###############################################"

# Set login root password
(echo "root"; sleep 1; echo "root") | passwd > /dev/null

# Set hostname and Timezone to Asia/Jakarta
echo "Setup NTP Server and Time Zone to Asia/Jakarta"
uci set system.@system[0].hostname='OpenWrt'
uci set system.@system[0].timezone='WIB-7'
uci set system.@system[0].zonename='Asia/Jakarta'
uci -q delete system.ntp.server
uci add_list system.ntp.server="pool.ntp.org"
uci add_list system.ntp.server="id.pool.ntp.org"
uci add_list system.ntp.server="time.google.com"
uci commit system

# configure wan interface
# chmod +x /usr/lib/ModemManager/connection.d/10-report-down
echo "Setup WAN and LAN Interface"
uci set network.lan.ipaddr="192.168.1.1"
# uci set network.wan=interface 
# uci set network.wan.proto='modemmanager'
# uci set network.wan.device='/sys/devices/platform/scb/fd500000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/usb2/2-1'
# uci set network.wan.apn='internet'
# uci set network.wan.auth='none'
# uci set network.wan.iptype='ipv4'
uci set network.wan=interface
uci set network.wan.proto='dhcp'
uci set network.wan.device='eth1'
uci commit network
uci set firewall.@zone[1].network='wan'
uci commit firewall

# configure ipv6
uci -q delete dhcp.lan.dhcpv6
uci -q delete dhcp.lan.ra
uci -q delete dhcp.lan.ndp
uci commit dhcp

# configure WLAN
# echo "Setup Wireless if available"
# uci set wireless.@wifi-device[0].disabled='0'
# uci set wireless.@wifi-iface[0].disabled='0'
# uci set wireless.@wifi-iface[0].encryption='psk2'
# uci set wireless.@wifi-iface[0].key='friwrt2024'
# uci set wireless.@wifi-device[0].country='ID'
# if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
#  uci set wireless.@wifi-iface[0].ssid='friWrt_5g'
#  uci set wireless.@wifi-device[0].channel='149'
#  uci set wireless.radio0.htmode='HT40'
#  uci set wireless.radio0.band='5g'
# else
#  uci set wireless.@wifi-iface[0].ssid='friWrt_2g'
#  uci set wireless.@wifi-device[0].channel='1'
#  uci set wireless.@wifi-device[0].band='2g'
# fi
# uci commit wireless
# wifi reload && wifi up
# if iw dev | grep -q Interface; then
#  if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
#    if ! grep -q "wifi up" /etc/rc.local; then
#      sed -i '/exit 0/i # remove if you dont use wireless' /etc/rc.local
#      sed -i '/exit 0/i sleep 10 && wifi up' /etc/rc.local
#    fi
#    if ! grep -q "wifi up" /etc/crontabs/root; then
#      echo "# remove if you dont use wireless" >> /etc/crontabs/root
#      echo "0 */12 * * * wifi down && sleep 5 && wifi up" >> /etc/crontabs/root
#      service cron restart
#    fi
#  fi
# else
#  echo "No wireless device detected."
# fi

# custom repo and Disable opkg signature check
echo "Setup custom repo using MyOPKG Repo"
if grep -qE '^VERSION_ID="21' /etc/os-release; then
  sed -i 's/option check_signature/# option check_signature/g' /etc/opkg.conf
#  echo "src/gz custom_generic https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/21.02/generic" >> /etc/opkg/customfeeds.conf
#  echo "src/gz custom_arch https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/21.02/$(grep "OPENWRT_ARCH" /etc/os-release | awk -F '"' '{print $2}')" >> /etc/opkg/customfeeds.conf
else
  sed -i 's/option check_signature/# option check_signature/g' /etc/opkg.conf
#  echo "src/gz custom_generic https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/main/generic" >> /etc/opkg/customfeeds.conf
#  echo "src/gz custom_arch https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/main/$(grep "OPENWRT_ARCH" /etc/os-release | awk -F '"' '{print $2}')" >> /etc/opkg/customfeeds.conf
fi

# setting firewall for samba4
# echo "Setup SAMBA4 firewall"
# uci -q delete firewall.samba_nsds_nt
# uci set firewall.samba_nsds_nt="rule"
# uci set firewall.samba_nsds_nt.name="NoTrack-Samba/NS/DS"
# uci set firewall.samba_nsds_nt.src="lan"
# uci set firewall.samba_nsds_nt.dest="lan"
# uci set firewall.samba_nsds_nt.dest_port="137-138"
# uci set firewall.samba_nsds_nt.proto="udp"
# uci set firewall.samba_nsds_nt.target="NOTRACK"
# uci -q delete firewall.samba_ss_nt
# uci set firewall.samba_ss_nt="rule"
# uci set firewall.samba_ss_nt.name="NoTrack-Samba/SS"
# uci set firewall.samba_ss_nt.src="lan"
# uci set firewall.samba_ss_nt.dest="lan"
# uci set firewall.samba_ss_nt.dest_port="139"
# uci set firewall.samba_ss_nt.proto="tcp"
# uci set firewall.samba_ss_nt.target="NOTRACK"
# uci -q delete firewall.samba_smb_nt
# uci set firewall.samba_smb_nt="rule"
# uci set firewall.samba_smb_nt.name="NoTrack-Samba/SMB"
# uci set firewall.samba_smb_nt.src="lan"
# uci set firewall.samba_smb_nt.dest="lan"
# uci set firewall.samba_smb_nt.dest_port="445"
# uci set firewall.samba_smb_nt.proto="tcp"
# uci set firewall.samba_smb_nt.target="NOTRACK"
# uci commit firewall

# set argon as default theme
echo "Setup Default Theme"
uci set luci.main.mediaurlbase='/luci-static/material' && uci commit

echo "Setup misc settings"
# remove login password required when accessing terminal
uci set ttyd.@ttyd[0].command='/bin/bash --login'
uci commit

# remove huawei me909s usb-modeswitch
sed -i -e '/12d1:15c1/,+5d' /etc/usb-mode.json

# remove dw5821e usb-modeswitch
sed -i -e '/413c:81d7/,+5d' /etc/usb-mode.json

# Disable /etc/config/xmm-modem
uci set xmm-modem.@xmm-modem[0].enable='0'
uci commit

# setup nlbwmon database dir
# uci set nlbwmon.@nlbwmon[0].database_directory='/etc/nlbwmon'
# uci set nlbwmon.@nlbwmon[0].commit_interval='3h'
# uci set nlbwmon.@nlbwmon[0].refresh_interval='60s'
# uci commit nlbwmon
# bash /etc/init.d/nlbwmon restart

# setup auto vnstat database backup
sed -i 's/;DatabaseDir "\/var\/lib\/vnstat"/DatabaseDir "\/etc\/vnstat"/' /etc/vnstat.conf
mkdir -p /etc/vnstat
chmod +x /etc/init.d/vnstat_backup
bash /etc/init.d/vnstat_backup enable

# adjusting app catagory
# sed -i 's/services/nas/g' /usr/lib/lua/luci/controller/aria2.lua 2>/dev/null || sed -i 's/services/nas/g' /usr/share/luci/menu.d/luci-app-aria2.json
# sed -i 's/services/nas/g' /usr/share/luci/menu.d/luci-app-samba4.json
# sed -i 's/services/nas/g' /usr/share/luci/menu.d/luci-app-hd-idle.json
# sed -i 's/services/modem/g' /usr/share/luci/menu.d/luci-app-lite-watchdog.json

# setup misc settings
sed -i 's/\[ -f \/etc\/banner \] && cat \/etc\/banner/#&/' /etc/profile
# sed -i 's/\[ -n "$FAILSAFE" \] && cat \/etc\/banner.failsafe/& || \/usr\/bin\/neofetch/' /etc/profile
# chmod +x /root/fix-tinyfm.sh && bash /root/fix-tinyfm.sh
# chmod +x /root/install2.sh && bash /root/install2.sh
# chmod +x /sbin/sync_time.sh
chmod +x /sbin/free.sh
# chmod +x /usr/bin/neofetch
# chmod +x /usr/bin/clock
# chmod +x /usr/bin/mount_hdd
chmod +x /usr/bin/openclash.sh
# chmod +x /usr/bin/cek_sms.sh

# configurating openclash
if opkg list-installed | grep luci-app-openclash > /dev/null; then
  echo "Openclash Detected!"
  echo "Start Patch YACD and Openclash Core"
#  if [ -d "/usr/share/openclash/ui/yacd.new" ]; then
#    echo "Configuring YACD..."
#    if mv /usr/share/openclash/ui/yacd /usr/share/openclash/ui/yacd.old; then
#      mv /usr/share/openclash/ui/yacd.new /usr/share/openclash/ui/yacd
#    fi
  fi
  echo "Configuring Core..."
#  chmod +x /etc/openclash/core/clash
#  chmod +x /etc/openclash/core/clash_tun
  chmod +x /etc/openclash/core/clash_meta
  chmod +x /usr/bin/patchoc.sh
  echo "Patching Openclash Overview"
  bash /usr/bin/patchoc.sh
  sed -i '/exit 0/i #/usr/bin/patchoc.sh' /etc/rc.local
  echo "YACD and Core setup complete!"
else
  echo "No Openclash Detected."
  uci delete internet-detector.Openclash
  uci commit internet-detector
  service internet-detector restart
fi

# Function to set up TinyFM file manager
setup_tinyfm() {
  echo "STEP" "Setting up TinyFM file manager..."
  
  # Create directory if it doesn't exist
  mkdir -p /www/tinyfm
  
  # Create rootfs symlink for full filesystem access
  ln -sf / /www/tinyfm/rootfs
  
  # Set permissions
  chmod 755 /www/tinyfm
  
  echo "INFO" "TinyFM setup complete"
}

# Function to set up PHP for web applications
setup_php() {
  echo "STEP" "Setting up PHP..."
  
  # Check if PHP is installed
  if is_package_installed "php8" || is_package_installed "php7"; then
    # Configure uhttpd for PHP
    safe_uci set "uhttpd.main.ubus_prefix" "/ubus"
    safe_uci set "uhttpd.main.interpreter" ".php=/usr/bin/php-cgi"
    safe_uci set "uhttpd.main.index_page" "cgi-bin/luci"
    safe_uci add_list "uhttpd.main.index_page" "index.html"
    safe_uci add_list "uhttpd.main.index_page" "index.php"
    commit_uci "uhttpd"
    
    # Optimize PHP configuration
    if [ -f "/etc/php.ini" ]; then
      cp /etc/php.ini /etc/php.ini.bak
      sed -i -E "s|memory_limit = [0-9]+M|memory_limit = 128M|g" /etc/php.ini
      sed -i -E "s|max_execution_time = [0-9]+|max_execution_time = 60|g" /etc/php.ini
      sed -i -E "s|display_errors = On|display_errors = Off|g" /etc/php.ini
      sed -i -E "s|;date.timezone =|date.timezone = Asia/Jakarta|g" /etc/php.ini
      echo "INFO" "PHP configuration optimized"
    else
      echo "WARNING" "PHP configuration file not found"
    fi
    
    # Create symbolic links for PHP
    ln -sf /usr/bin/php-cli /usr/bin/php
    
    # Link PHP libraries if needed
    if [ -d "/usr/lib/php8" ] && [ ! -d "/usr/lib/php" ]; then
      ln -sf /usr/lib/php8 /usr/lib/php
      echo "INFO" "Created PHP library symlink"
    fi
    
    # Restart uhttpd
    /etc/init.d/uhttpd restart
    echo "INFO" "PHP setup complete"
  else
    echo "INFO" "PHP not installed, skipping configuration"
  fi
}

# configurating neko
# if opkg list-installed | grep luci-app-neko > /dev/null; then
#  chmod +x /etc/neko/core/mihomo
# fi

# adding new line for enable i2c oled display
# if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
#  echo -e "\ndtparam=i2c1=on\ndtparam=spi=on\ndtparam=i2s=on" >> /boot/config.txt
# fi

# enable adguardhome
# chmod +x /usr/bin/adguardhome
#bash /usr/bin/adguardhome enable_agh

# Main execution function
main() {
  # Print banner
  echo "=========================================================="
  echo "          OPEN-WRT Router Configuration Script             "
  echo "                     Version 2.0                          "
  echo "=========================================================="
  
  # Execute functions in sequence with error handling
  setup_tinyfm
  setup_php
}

# Run the main function
main

echo "All first boot setup complete!"

exit 0
