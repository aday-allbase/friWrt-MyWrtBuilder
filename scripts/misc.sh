#!/bin/bash

echo "Start Downloading Misc files and setup configuration!"
echo "Current Path: $PWD"

#setup custom setting for openwrt and immortalwrt
sed -i "s/Ouc3kNF6/$DATE/g" files/etc/uci-defaults/99-init-settings.sh
if [[ "$BASE" == "openwrt" ]]; then
    echo "$BASE"
    sed -i '/# setup misc settings/ a\mv \/www\/luci-static\/resources\/view\/status\/include\/29_temp.js \/www\/luci-static\/resources\/view\/status\/include\/17_temp.js' files/etc/uci-defaults/99-init-settings.sh
fi

if [ "$(echo "$BRANCH" | cut -d'.' -f1)" == "21" ] || [ "$TYPE" == "AMLOGIC" ] || [ "$ROOTFS_SQUASHFS" == "true" ]; then
    rm files/etc/uci-defaults/70-rootpt-resize
    rm files/etc/uci-defaults/80-rootfs-resize
    rm files/etc/sysupgrade.conf
fi

# add yout custom command for specific target and release branch version here
if [ "$(echo "$BRANCH" | cut -d'.' -f1)" == "21" ]; then
    echo "$BRANCH"
elif [ "$(echo "$BRANCH" | cut -d'.' -f1)" == "24" ]; then
    echo "$BRANCH"
fi

echo "All custom configuration setup completed!"
