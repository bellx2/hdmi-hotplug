#!/bin/sh
# HDMI hotplug auto-resolution installer
set -e
cd "$(dirname "$0")"
sudo install -m 755 hdmi-hotplug.sh /usr/local/bin/hdmi-hotplug.sh
sudo install -m 644 95-hdmi-hotplug.rules /etc/udev/rules.d/95-hdmi-hotplug.rules
sudo udevadm control --reload-rules
echo "Installed. Logs: journalctl -t hdmi-hotplug"
