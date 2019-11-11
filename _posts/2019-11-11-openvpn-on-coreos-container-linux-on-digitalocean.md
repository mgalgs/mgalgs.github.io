---
layout: post
title: OpenVPN On CoreOS Container Linux On DigitalOcean
tags: [docker, digitalocean, coreos]
---

Using a VPN is useful for a whole host of reasons.  Unfortunately, you
either have to pay for a hosted service (which means trusting the service
provider) or you have to host it yourself (and VPNs are famously difficult
to configure and maintain).

Fortunately, there's a handy little Docker image for OpenVPN that makes
installation and configuration a breeze.  And with the wide variety of
hosting providers on the market today you can host your own OpenVPN server
on the cheap with minimal headache.

This post will document the full installation and configuration of [OpenVPN
under Docker](https://hub.docker.com/r/kylemanna/openvpn/) on [CoreOS
Container Linux](https://coreos.com/os/docs/latest/) on a
[DigitalOcean](https://www.digitalocean.com/) $10/month droplet.  You could
probably run it just fine on their $5/month plan but I didn't test that.

## Installing CoreOS

Click through the DigitalOcean Droplet creation screen, picking CoreOS
(from the "Container Distributions" tab) and the $10/month Droplet size.

## Installing and Configuring OpenVPN

Now that we have shell access to our Container Linux instance (login is
`core@<droplet-ip>`) we can configure the OpenVPN container.  We're using
the [`kylemanna/openvpn`](https://hub.docker.com/r/kylemanna/openvpn/)
image and will follow the Quick Start instructions there.

First, pick a name for the Docker Volume that will provide persistence for
OpenVPN and store it in an environment variable:

```
OVPN_DATA="ovpn-data-primary"
```

Initialize the configuration files and certificates (you'll be prompted to
pick a passphrase):

```
docker volume create --name $OVPN_DATA
docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_genconfig -u udp://vpn.example.com
docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn ovpn_initpki
```

(Replace `vpn.example.com` with your VPN server's DNS name.)

Start the OpenVPN server (using the [provided systemd
service](https://github.com/kylemanna/docker-openvpn/blob/master/docs/systemd.md)):

```
curl -L https://raw.githubusercontent.com/kylemanna/docker-openvpn/master/init/docker-openvpn%40.service | sudo tee /etc/systemd/system/docker-openvpn@.service
sudo systemctl enable --now docker-openvpn@primary.service
```

(Note the `@primary` in the service name. That should match the
`ovpn-data-SUFFIX` from the volume you created earlier.)

At this point OpenVPN is configured and will autostart at boot.  Now we
need to generate client certificates that can be used to connect to the
OpenVPN server.  Let's create one now without a passphrase and retrieve its
associated ovpn file:

```
CLIENTNAME=my-cool-machine
docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn easyrsa build-client-full $CLIENTNAME nopass
docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn
```

At this point you can copy the `$CLIENTNAME.ovpn` file to your client
machine (using `scp` or similar), drop it in `/etc/openvpn/` and use it to
connect to the VPN:

```
(user@vpn-client) $ sudo openvpn --config /etc/openvpn/$CLIENTNAME.ovpn
```

If you've ever attempted setting up an OpenVPN server from scratch you
might be surprised to discover that WE'RE DONE!  Enjoy your shiny new VPN
server!
