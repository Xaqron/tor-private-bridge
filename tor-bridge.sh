#!/usr/bin/env bash

#=================================================
#title           :Tor bridge installer
#description     :Installs a private Tor bridge
#author	    	 :Xaqron
#date            :20180416
#version         :1.1.0
#license         :MIT    
#=================================================

TOR_PUBLIC_KEY="A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89"

echo "Checking root privilege..."
if [[ $EUID -ne 0 ]]; then
    echo "Usage: sudo bash $0"
    echo "Run script as root. Exiting..."
    exit 1
fi

if [ "$#" -eq 3 ]; then # TODO: Argument validation
    IP=$1
    LISTENING_PORT=$2
    OR_PORT=$3
elif [ "$#" -eq 0 ]; then
    IP=$(curl ipinfo.io/ip)
    LISTENING_PORT=$((20000 + RANDOM % 39000))
    OR_PORT=$((20000 + RANDOM % 39000))
else
    echo "Wrong parameters!"
    echo "Usage: sudo bash $0 IP ListenPort ORPort"
    exit 1
fi

echo "Updating server..."
apt update
apt full-upgrade -y

echo "Adding gpg keys..."
apt install -y dirmngr
gpg --keyserver keys.gnupg.net --recv $TOR_PUBLIC_KEY
gpg --export $TOR_PUBLIC_KEY | apt-key add -

echo Adding official Tor repositories...
rm -f /etc/apt/sources.list.d/tor.list 2> /dev/null
rm -f /etc/apt/sources.list.d/tor.list.save 2> /dev/null
echo "deb http://deb.torproject.org/torproject.org $(lsb_release -cs) main" > /etc/apt/sources.list.d/tor.list
echo "deb-src http://deb.torproject.org/torproject.org $(lsb_release -cs) main" >> /etc/apt/sources.list.d/tor.list

echo Installing Tor bridge...
apt update
apt install -y tor tor-geoipdb deb.torproject.org-keyring obfs4proxy
service tor stop

echo "Backup made at \"/etc/tor/torrc.bak\", Writing Tor config..."
mv /etc/tor/torrc /etc/tor/torrc.bak
echo "RunAsDaemon 0" >> /etc/tor/torrc
echo "ORPort $OR_PORT" >> /etc/tor/torrc
echo "ExtORPort auto" >> /etc/tor/torrc
echo "ExitPolicy reject *:*" >> /etc/tor/torrc
echo "BridgeRelay 1" >> /etc/tor/torrc
echo "PublishServerDescriptor 0" >> /etc/tor/torrc
echo "ServerTransportPlugin obfs4 exec /usr/bin/obfs4proxy" >> /etc/tor/torrc
echo "ServerTransportListenAddr obfs4 0.0.0.0:$LISTENING_PORT" >> /etc/tor/torrc

echo "Setting firewall rules..."
ufw allow $LISTENING_PORT
ufw allow $OR_PORT

echo "Starting Tor service..."
service tor start

echo "Tor starts after 30 seconds. Please wait..."
sleep 30

echo
echo "Your obfs4 address is:"
OBFS4TEMPLATE=`tail -1 /var/lib/tor/pt_state/obfs4_bridgeline.txt`
FINGERPRINT0=`cat /var/lib/tor/fingerprint`
FINGERPRINT0=$(echo $FINGERPRINT0 | cut -d ' ' -f 2-)
FINGERPRINT=${FINGERPRINT0#"Xaqron "}
OBFS4ADDRESS="${OBFS4TEMPLATE/<IP ADDRESS>/$IP}"
OBFS4ADDRESS="${OBFS4ADDRESS/<PORT>/$LISTENING_PORT}"
OBFS4ADDRESS="${OBFS4ADDRESS/<FINGERPRINT>/$FINGERPRINT}"
echo $OBFS4ADDRESS
echo

echo "Saving obfs4 address to: \"~/obfs4.address\""
echo "Use obfs4 address with Tor client."
echo $OBFS4ADDRESS > ~/obfs4.address
echo "Done!"
