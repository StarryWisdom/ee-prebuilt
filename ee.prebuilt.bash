#!/bin/bash

#if scripts are automatically downloaded then this may be merge-able into run_common
#note prepare may be run as 2 different users - ubuntu and whatever the startup script runs as (I dont know if thats root or ubuntu)
prepare () {
	cd /home/ubuntu
	#note - the prebuilt from above needs uploading to s3
	wget https://eeprebuilt.s3.us-east-2.amazonaws.com/EmptyEpsilon.tar.gz
	sudo apt-get update
	#gdb is probably only going to be used for debug builds but installing it unconditionally makes it easier later
	#unzip is needed for noVNC later may already be installed?
	#websockify is for vnc web stuff
	yes Y | sudo apt-get install x11vnc xserver-xorg libflac8 libopenal1 libvorbisfile3 gdb websockify unzip
	tar -xf EmptyEpsilon.tar.gz

	#copied straight from http://noseynick.org/artemis/nebula/artemis.sh
sudo sysctl -f - <<__TUNING__
net.ipv4.tcp_fin_timeout=5 # restart quicker after server crash
net.ipv4.tcp_retries1 = 2 # fewer retries
net.ipv4.tcp_retries2 = 4 # fewer retries - just over 10sec
net.ipv4.tcp_keepalive_time=5 # probe conns after N secs of idle
net.ipv4.tcp_keepalive_intvl=3 # probe dead conns every N secs
net.ipv4.tcp_keepalive_probes=3 # ... and kill them after N tries
net.ipv4.tcp_tw_reuse=1 # to re-use conns in TIMEWAIT
__TUNING__

	cd EmptyEpsilon/scripts
	wget https://raw.githubusercontent.com/Xansta/EEScenarios/master/scenario_59_border.lua -O secenario_59_border_updated.lua
	sed -i~ -E 's/Borderline Fever/Borderline Fever Updated/' scenario_59_border_updated.lua
	chown ubuntu:ubuntu scenario_59_border_updated.lua

	cd /home/ubuntu
}

run_common () {
	#in an ideal world we would cope with the case of EmptyEpsilon not having been downloaded, this however is not an ideal world
	export VNCPASS=sig93air
	export DISPLAY=:20
	sudo Xorg $DISPLAY -nolisten tcp & 
	mkdir -p /home/ubuntu/.vnc /home/ubuntu/www
	x11vnc -storepasswd "$VNCPASS" /home/ubuntu/.vnc/passwd
	x11vnc -localhost -forever -shared -usepw &
	#this is from nicks http://noseynick.org/artemis/nebula/vnc.sh
	#apologies for butchering the code to make it work
	NVVER=master
	if [ ! -d noVNC-$NVVER ]; then
		wget https://github.com/novnc/noVNC/archive/$NVVER.zip
		unzip -o $NVVER.zip
		for X in core vendor app vnc.html vnc_lite.html; do
			rm -f /home/ubuntu/www/$X
			ln -vfs ../noVNC-$NVVER/$X /home/ubuntu/www/$X
		done
		# run the webserver on port 8080 ...
		cd www
		# fix for 2019-07 NoVNC / WebSockify compatibility bug:
		sed -i~ -E '/options.wsProtocols/ s/\[\]/["binary","base64"]/' /home/ubuntu/www/core/rfb.js
		cd /home/ubuntu
		websockify --web /home/ubuntu/www/ --daemon --log-file /home/ubuntu/www.log 8080 127.1:5900
		# ... but make it available on port 80 from the outside world
		sudo iptables -C PREROUTING -t nat -p tcp --dport 80 -j REDIRECT --to-ports 8080 || \
		sudo iptables -A PREROUTING -t nat -p tcp --dport 80 -j REDIRECT --to-ports 8080
	fi
	cd EmptyEpsilon
}

run_debug () {
	run_common
	gdb ./EmptyEpsilon.Debug -ex run
}

run_release () {
	run_common
	./EmptyEpsilon.Release
}