#!/bin/sh
set -e
sudo rm -f /usr/local/bin/hdmi-hotplug.sh /etc/udev/rules.d/95-hdmi-hotplug.rules
sudo udevadm control --reload-rules
echo "Uninstalled."
