#!/bin/bash

REALUSER="$USER"
if [ "$REALUSER" = "" ] || [ "$REALUSER" = "root" ]; then
	if [ "$SUDO_USER" = "" ]; then
		echo '$SUDO_USER must be set.'
		exit 1
	fi
	REALUSER="$SUDO_USER"
fi

if [ $(whoami) != "root" ]; then
	echo "Must be run as root."
	exit 1
fi

echo "Running under user $REALUSER."

[ "$?" != "0" ] && exit 1

deltacp()
{
	SRC="$1"
	DST="$2"
	START="#START MORTCUSTOM"
	END="#END MORTCUSTOM"

	if grep "$START" "$DST" > /dev/null; then
		sed -i "/$START/,/$END/d" "$DST"
	fi

	echo "$START" >> "$DST"
	cat "$SRC" >> "$DST"
	echo "$END" >> "$DST"
}

fixuser()
{
	chown -R -h "$REALUSER" "$1"
}

cpr()
{
	rm -rf "$2"
	cp -r "$1" "$2";
}

./setup/install.sh

if ! [ $(hostname) = "elli" ]; then
	umount remote &>/dev/null
	deltacp setup/fstab /etc/fstab
	mount remote
fi

cp setup/killsshfs.service /etc/systemd/system/killsshfs.service
systemctl enable killsshfs
systemctl start killsshfs

mkdir -p tmp
fixuser tmp
mkdir -p mnt
fixuser mnt
mkdir -p src
fixuser src
mkdir -p cloud
fixuser cloud
mkdir -p remote
fixuser remote
[ ! -h uni ] && ln -s cloud/uni uni
fixuser uni
[ ! -h dev ] && ln -s cloud/dev dev
fixuser dev

cpr setup/mort-custom.sh /etc/profile.d/mort-custom.sh

# vdirsyncer
setup_vdirsyncer() {
	echo -n "Set up vdirsyncer? [Y/n] "
	read reply
	if [ "$reply" != "n" ] && [ "$reply" != "N" ]; then
		echo -n "vdirsyncer username? "
		read username
		if [ "$username" = "" ]; then
			return
		fi

		echo -n "vdirsyncer password? "
		read password
		if [ "$password" = "" ]; then
			return
		fi

		cpr setup/vdirsyncer .vdirsyncer
		sed -i "s/<USERNAME>/$username/; s/<PASSWORD>/$password/" .vdirsyncer/config
		fixuser .vdirsyncer
	fi
}
if ! [ -f .vdirsyncer ]; then
	setup_vdirsyncer
fi

exit 0
