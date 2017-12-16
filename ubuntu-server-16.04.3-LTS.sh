#!/bin/sh

echo Checking root privilege...
if [[ $EUID -ne 0 ]]; then
    echo Run script as root. Exiting...
    exit 1
fi

echo Usage: command IP ListenPort ORPort

echo Updating server
apt update
apt full-upgrade -y

echo Adding official tor repositories...
rm -rf /etc/apt/sources.list.d/tor.list 2> /dev/null
echo "deb http://deb.torproject.org/torproject.org xenial main" >> /etc/apt/sources.list.d/tor.list
echo "deb-src http://deb.torproject.org/torproject.org xenial main" >> /etc/apt/sources.list.d/tor.list

echo Adding gpg keys...
apt install -y dirmngr
gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -

echo Installing Tor bridge...
apt update
apt install -y tor tor-geoipdb deb.torproject.org-keyring obfs4proxy
service tor stop

echo A backup made as /etc/tor/torrc.bak, Writing Tor config...
mv /etc/tor/torrc /etc/tor/torrc.bak
echo "RunAsDaemon 0" >> /etc/tor/torrc
echo "ORPort $3" >> /etc/tor/torrc
echo "ExtORPort auto" >> /etc/tor/torrc
echo "ExitPolicy reject *:*" >> /etc/tor/torrc
echo "BridgeRelay 1" >> /etc/tor/torrc
echo "PublishServerDescriptor 0" >> /etc/tor/torrc
echo "ServerTransportPlugin obfs4 exec /usr/bin/obfs4proxy" >> /etc/tor/torrc
echo "ServerTransportListenAddr obfs4 0.0.0.0:$2" >> /etc/tor/torrc
echo "ContactInfo https://twitter.com/xaqron" >> /etc/tor/torrc
echo "Nickname Xaqron" >> /etc/tor/torrc

echo Setting firewall rules...
iptables -A INPUT -p tcp --dport $2 -j ACCEPT
iptables -A INPUT -p tcp --dport $3 -j ACCEPT
dpkg-reconfigure iptables-persistent

echo Starting Tor service...
service tor start

echo Tor starts after 30 seconds. Please wait...
sleep 30

echo Your obfs4 address is:
OBFS4TEMPLATE=`tail -1 /var/lib/tor/pt_state/obfs4_bridgeline.txt`
FINGERPRINT0=`cat /var/lib/tor/fingerprint`
FINGERPRINT=${FINGERPRINT0#"Xaqron "}
OBFS4ADDRESS="${OBFS4TEMPLATE/<IP ADDRESS>/$1}"
OBFS4ADDRESS="${OBFS4ADDRESS/<PORT>/$2}"
OBFS4ADDRESS="${OBFS4ADDRESS/<FINGERPRINT>/$FINGERPRINT}"
echo $OBFS4ADDRESS

echo Saving obfs4 address to file: ~/obfs4.address
echo Use obfs4 address with Tor client.
echo $OBFS4ADDRESS > ~/obfs4.address
echo Done!