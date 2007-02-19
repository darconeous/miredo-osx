# Lets have a version, at last!
TUNTAP_VERSION = 20060513

# BASE install directory
BASE=

all:	tap.kext tun.kext
	cp -pR tap.kext pkg/tap_kext/Library/Extensions/
	cp -pR tun.kext pkg/tun_kext/Library/Extensions/
	cp -pR startup_item/tap pkg/startup_item/Library/StartupItems/
	cp -pR startup_item/tun pkg/startup_item/Library/StartupItems/

pkg:	all
	sed -e 's/@@TUNTAP_VERSION@@/$(TUNTAP_VERSION)/' pkg/tap_kext.desc/Info.plist.in > pkg/tap_kext.desc/Info.plist
	sed -e 's/@@TUNTAP_VERSION@@/$(TUNTAP_VERSION)/' pkg/tun_kext.desc/Info.plist.in > pkg/tun_kext.desc/Info.plist
	sed -e 's/@@TUNTAP_VERSION@@/$(TUNTAP_VERSION)/' pkg/startup_item.desc/Info.plist.in > pkg/startup_item.desc/Info.plist
	tools/makepkg.sh pkg/tap_kext.pkg pkg/tap_kext pkg/tap_kext.res pkg/tap_kext.desc
	tools/makepkg.sh pkg/tun_kext.pkg pkg/tun_kext pkg/tun_kext.res pkg/tun_kext.desc
	tools/makepkg.sh pkg/startup_item.pkg pkg/startup_item pkg/startup_item.res pkg/startup_item.desc
	@# make a copy of the tuntap metapackage not containing the CVS data
	-rm -rf pkg/tuntap_installer.mpkg
	-mkdir pkg/tuntap_installer.mpkg
	tar cv -C pkg/tuntap.mpkg . --exclude '*CVS*' | tar xv -C pkg/tuntap_installer.mpkg
	tar czf tuntap_tiger_$(TUNTAP_VERSION).tar.gz README.installer README -C pkg tap_kext.pkg tun_kext.pkg startup_item.pkg tuntap_installer.mpkg
	rm -rf pkg/tuntap_installer.mpkg

# Install targets
# They are provided for the gentoo ebuild, but should work just fine for other people as well.
install_kext: tap.kext tun.kext
	cp -pR tap.kext ${BASE}/Library/Extensions/
	cp -pR tun.kext ${BASE}/Library/Extensions/ 

install_scripts:
	cp -pR startup_item/tap ${BASE}/Library/StartupItems/
	cp -pR startup_item/tun ${BASE}/Library/StartupItems/ 

install: install_kext install_scripts

tarball:	clean
	tar czf tuntap_tiger_$(TUNTAP_VERSION)_src.tar.gz --exclude "*/CVS*" --exclude "tuntap/tuntap_tiger_src.tar.gz" \
		--exclude "*/.*" -C .. tuntap

clean:
	cd src/tap && make -f Makefile clean
	cd src/tun && make -f Makefile clean
	-rm -rf pkg/tap_kext.desc/Info.plist
	-rm -rf pkg/tun_kext.desc/Info.plist
	-rm -rf pkg/startup_item.desc/Info.plist
	-rm -rf pkg/tap_kext/Library/Extensions/tap.kext
	-rm -rf pkg/tun_kext/Library/Extensions/tun.kext
	-rm -rf pkg/startup_item/Library/StartupItems/tap
	-rm -rf pkg/startup_item/Library/StartupItems/tun
	-rm -rf pkg/tap_kext.pkg
	-rm -rf pkg/tun_kext.pkg
	-rm -rf pkg/startup_item.pkg
	-rm -rf tuntap_tiger_$(TUNTAP_VERSION).tar.gz
	-rm -rf tuntap_tiger_$(TUNTAP_VERSION)_src.tar.gz

tap.kext:
	cd src/tap && make TUNTAP_VERSION=$(TUNTAP_VERSION) -f Makefile all

tun.kext:
	cd src/tun && make TUNTAP_VERSION=$(TUNTAP_VERSION) -f Makefile all

