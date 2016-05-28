INSTALLEXE = /usr/bin/install -c -m 755
INSTALLDATA = /usr/bin/install -c -m 600
INSTALLDIR = /usr/bin/install -c -d -m 755
srcdir = src

all:
	@echo "Nothing to build"
install:
	$(INSTALLDIR) $(DESTDIR)/etc/init.d
	$(INSTALLEXE) $(srcdir)/etc/init.d/tcpdump_any $(DESTDIR)/etc/init.d/tcpdump_any
	$(INSTALLEXE) $(srcdir)/etc/init.d/tcpdump_bond0 $(DESTDIR)/etc/init.d/tcpdump_bond0
	$(INSTALLEXE) $(srcdir)/etc/init.d/tcpdump_eth0 $(DESTDIR)/etc/init.d/tcpdump_eth0
	$(INSTALLEXE) $(srcdir)/etc/init.d/tcpdump_eth1 $(DESTDIR)/etc/init.d/tcpdump_eth1
	$(INSTALLEXE) $(srcdir)/etc/init.d/tcpdump_eth2 $(DESTDIR)/etc/init.d/tcpdump_eth2
	$(INSTALLDIR) $(DESTDIR)/etc/tcpdump.d
	$(INSTALLDATA) $(srcdir)/etc/tcpdump.d/tcpdump_any $(DESTDIR)/etc/tcpdump.d/tcpdump_any
	$(INSTALLDATA) $(srcdir)/etc/tcpdump.d/tcpdump_bond0 $(DESTDIR)/etc/tcpdump.d/tcpdump_bond0
	$(INSTALLDATA) $(srcdir)/etc/tcpdump.d/tcpdump_eth0 $(DESTDIR)/etc/tcpdump.d/tcpdump_eth0
	$(INSTALLDATA) $(srcdir)/etc/tcpdump.d/tcpdump_eth1 $(DESTDIR)/etc/tcpdump.d/tcpdump_eth1
	$(INSTALLDATA) $(srcdir)/etc/tcpdump.d/tcpdump_eth2 $(DESTDIR)/etc/tcpdump.d/tcpdump_eth2
	$(INSTALLDIR) $(DESTDIR)/usr/local
	$(INSTALLDIR) $(DESTDIR)/usr/local/bin
	$(INSTALLDIR) $(DESTDIR)/usr/local/sbin
	$(INSTALLEXE) $(srcdir)/usr/local/sbin/archive_tcpdump.sh $(DESTDIR)/usr/local/sbin/archive_tcpdump.sh
	$(INSTALLDATA) $(srcdir)/etc/tcpdump.d/archive_tcpdump.cfg $(DESTDIR)/etc/tcpdump.d/archive_tcpdump.cfg
	$(INSTALLEXE) $(srcdir)/usr/local/bin/sctpdechunk $(DESTDIR)/usr/local/bin/sctpdechunk
	$(INSTALLDIR) $(DESTDIR)/var/tcpdump
	$(INSTALLDIR) $(DESTDIR)/var/tcpdumparc
