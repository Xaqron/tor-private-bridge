# Setup a private obfs4 Tor bridge on Ubuntu server

Copy script to your server:

```bash
wget https://raw.githubusercontent.com/Xaqron/tor-private-bridge/master/tor-bridge.sh
```

## Easy installation

Run the script as root:

```bash
sudo bash tor-bridge.sh
```

Done :blush:

## Advanced installation

```bash
sudo bash tor-bridge.sh 172.16.81.23 51452 59009
```

### In above example

* `172.16.81.23` is your server public IP address.
* `51452` is the listening port of tor service.
* `59009` is ORPort.

For more security change `listening port` and `ORPort` to a random number of your own.

When setup finished you will get an obfs4 address which can be used in Tor browser.

Also your `obfs4` address will be saved at `obfs4.address` file in your home directory.

## Tor Client setup

Use `obfs4` address as `custom bridge` in your Tor client:

![tor-browser](images/tor-browser.png)

> Censorship reflects a society's lack of confidence in itself.
