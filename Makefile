# 
# Paul Henson <henson@acm.org>
#
# Copyright (c) 1997,1998 Paul Henson -- see COPYRIGHT file for details
#

CC = gcc

CFLAGS = -fpic -D_REENTRANT -DPIC -D_TS_ERRNO

all: dtlogin-dce.so.1

dtlogin-dce.so.1: dtlogin-dce.c
	$(CC) $(CFLAGS) -o dtlogin-dce.so.1 -G dtlogin-dce.c

install: dtlogin-dce.so.1
	@[ ! -d /etc/dt ] && echo "Creating directory /etc/dt" || /bin/true
	@[ ! -d /etc/dt ] && mkdir /etc/dt && chmod 755 /etc/dt || /bin/true
	@[ -d /etc/dt ] || echo "Error: unable to create directory /etc/dt"
	@[ ! -d /etc/dt/lib ] && echo "Creating directory /etc/dt/lib" || /bin/true
	@[ ! -d /etc/dt/lib ] && mkdir /etc/dt/lib && chmod 755 /etc/dt/lib || /bin/true
	@[ -d /etc/dt/lib ] || echo "Error: unable to create directory /etc/dt/lib"
	@echo "Installing dtlogin-dce.so.1 into /etc/dt/lib"
	@cp dtlogin-dce.so.1 /etc/dt/lib && chmod 555 /etc/dt/lib/dtlogin-dce.so.1 || /bin/true
	@[ ! -f /etc/dt/lib/dtlogin-dce.so.1 ] && echo "Error: unable to install dtlogin-dce.so.1" || /bin/true

install-config:
	@[ ! -d /etc/dt/config ] && echo "Creating directory /etc/dt/config" || /bin/true
	@[ ! -d /etc/dt/config ] && mkdir /etc/dt/config && chmod 755 /etc/dt/config || /bin/true
	@[ -d /etc/dt/config ] || echo "Error: unable to create directory /etc/dt/config"
	@echo "Copying /usr/dt/config/Xconfig to /etc/dt/config/Xconfig"
	@cp /usr/dt/config/Xconfig /etc/dt/config || echo "Error: unable to copy /usr/dt/config/Xconfig"
	@echo "Copying /usr/dt/config/Xreset to /etc/dt/config/Xreset"
	@cp /usr/dt/config/Xreset /etc/dt/config || echo "Error: unable to copy /usr/dt/config/Xreset"
	@echo "Moving S99dtlogin from /etc/rc2.d to /etc/rc3.d" 
	@mv /etc/rc2.d/S99dtlogin /etc/rc3.d/S99dtlogin || echo "Error: unable to move S99dtlogin"

patch-config:
	@echo "Patching /etc/dt/config/Xconfig"
	@patch -p4 -d /etc/dt/config < patches/Xconfig.diff && rm /etc/dt/config/Xconfig.orig
	@echo "Patching /etc/dt/config/Xreset"
	@patch -p4 -d /etc/dt/config < patches/Xreset.diff && rm /etc/dt/config/Xreset.orig
	@echo "Patching /etc/rc3.d/S99dtlogin"
	@patch -p4 -d /etc/rc3.d < patches/S99dtlogin.diff && rm /etc/rc3.d/S99dtlogin.orig

clean:
	@rm -f *.o *~ dtlogin-dce.so.1
