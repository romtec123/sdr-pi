#!/bin/bash
# This script will automatically set up the PI with CloudflareD, install RTL drivers & install VNC
# This is designed to work with my Pi 3 on a Debian based OS
# VNC and SSH will be exposed via Cloudflare Tunnels

#Update packages & install new ones
echo "Updating and installing packages..."
sudo apt update -y && sudo apt upgrade -y

sudo apt install -y git curl neofetch htop tightvncserver cmake libusb-1.0-0-dev build-essential gqrx-sdr

curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-armhf.deb && sudo dpkg -i cloudflared.deb

rm cloudflare.deb
#Will need to run the install command to link to account and setup SSH and VNC tunnels

echo "Packages and cloudflared installed!"
echo "Installing RTL drivers..."

#Install RTL drivers (based on https://gist.github.com/floehopper/99a0c8931f9d779b0998)
cat <<EOF >no-rtl.conf
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF
sudo mv no-rtl.conf /etc/modprobe.d/ #disable stock stuff

git clone git://git.osmocom.org/rtl-sdr.git #grab drivers

mkdir rtl-sdr/build && cd rtl-sdr/build && cmake ../ -DINSTALL_UDEV_RULES=ON #setup
sudo make install #compile and install
sudo ldconfig #refresh

sudo cp ../rtl-sdr.rules /etc/udev/rules.d/

echo "RTL drivers installed!"
echo "Setting up VNC..."


#Setup VNC and add it to cron. (So I can connect to headless PI through a cloudflare tunnel)
cd ~
tightvncserver -geometry 1280x720 #This will run through the setup process & start the server

#Auto start with cron, systemd seems to have issues.
sudo crontab -l > cur.cron #save cron file
sudo echo "@reboot su - j -c '/usr/bin/tightvncserver -geometry 1280x720'" >> cur.cron #add new command
sudo crontab cur.cron #install new cron file

sudo rm cur.cron


echo "Install complete! Make sure to setup Cloudflared and reboot the pi."
