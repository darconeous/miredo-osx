

##### Path Variables
PREFIX=/usr
SYSCONF=/etc
LOCALSTATE=/var
MIREDO_DIR=$(shell pwd)/miredo
MISC_DIR=$(shell pwd)/misc
BUILD_DIR=$(shell pwd)/build
UTIL_DIR=$(shell pwd)/util
OUT_DIR=$(BUILD_DIR)/out
TMP_DIR=/tmp
TUNTAP_DIR=$(shell pwd)/tuntap

## miredo
MIREDO_SRC_DIR=$(shell pwd)/miredo
MIREDO_BUILD_X86_DIR=$(BUILD_DIR)/miredo_build_x86
MIREDO_BUILD_PPC_DIR=$(BUILD_DIR)/miredo_build_ppc
MIREDO_OUT_X86_DIR=$(BUILD_DIR)/miredo_out_x86
MIREDO_OUT_PPC_DIR=$(BUILD_DIR)/miredo_out_ppc
MIREDO_CONFIG_FLAGS+="--enable-miredo-user=root"
MIREDO_CONFIG_FLAGS+="--without-libiconv-prefix"
MIREDO_CONFIG_FLAGS+="--without-gettext"
MIREDO_CONFIG_FLAGS+="--without-libintl-prefix"
MIREDO_CONFIG_FLAGS+="--localstatedir=$(LOCALSTATE)"
MIREDO_CONFIG_FLAGS+="--sysconfdir=$(SYSCONF)"
MIREDO_CONFIG_FLAGS+="--disable-shared"
MIREDO_CONFIG_FLAGS+="--enable-static"
MIREDO_CONFIG_FLAGS+="--disable-sample-conf"
MIREDO_CONFIG_FLAGS+="--prefix=$(PREFIX)"
MIREDO_CONFIG_FLAGS+="gt_cv_func_gnugettext1_libintl=no"
MIREDO_CONFIG_FLAGS+="ac_cv_header_libintl_h=no"


## libJudy
JUDY_SRC_DIR=$(shell pwd)/libjudy
JUDY_BUILD_X86_DIR=$(BUILD_DIR)/judy_build_x86
JUDY_BUILD_PPC_DIR=$(BUILD_DIR)/judy_build_ppc
JUDY_OUT_X86_DIR=$(BUILD_DIR)/judy_out_x86
JUDY_OUT_PPC_DIR=$(BUILD_DIR)/judy_out_ppc
JUDY_CONFIG_FLAGS+="--disable-shared"
JUDY_CONFIG_FLAGS+="--enable-static"

## Uninstaller
UNINST_SCRIPT_DIR=/Applications/Utilities
UNINST_SCRIPT=$(UNINST_SCRIPT_DIR)/uninstall-miredo.command

## Pref Pane
MIREDO_PREF_SRC_DIR=$(shell pwd)/MiredoPreferencePane
MIREDO_PREF_OUT_DIR=$(OUT_DIR)/Library/PreferencePanes


##### Tool Variables
PACKAGEMAKER=/Developer/Tools/packagemaker
RMDIR=rm -fr
MKDIR=mkdir
CP=cp
MAKE=make
TEST=test
MAKE_UNIVERSAL=$(shell pwd)/util/make_universal
RMKDIR=$(shell pwd)/util/rmkdir
XCODEBUILD=/usr/bin/xcodebuild


##### Targets


	

.PHONY: all miredo package clean mrproper tuntap libjudy uninst-script default pref-pane

default: tuntap miredo

all: tuntap miredo uninst-script package

uninst-script: $(OUT_DIR)$(UNINST_SCRIPT)

$(OUT_DIR)$(UNINST_SCRIPT): miredo tuntap 
	$(RMKDIR) $(OUT_DIR)$(UNINST_SCRIPT_DIR)
	echo "#!/bin/sh" > $(OUT_DIR)$(UNINST_SCRIPT)
	echo "cd /" >> $(OUT_DIR)$(UNINST_SCRIPT)
	echo "sudo launchctl unload /Library/LaunchDaemons/miredo.plist" >> $(OUT_DIR)$(UNINST_SCRIPT)
	echo "sudo killall -9 miredo" >> $(OUT_DIR)$(UNINST_SCRIPT)
	echo "sudo /Library/StartupItems/tun/tun stop" >> $(OUT_DIR)$(UNINST_SCRIPT)
	echo "sudo /Library/StartupItems/tap/tap stop" >> $(OUT_DIR)$(UNINST_SCRIPT)
	for FILE in `cd $(OUT_DIR) ; find . ` ; do { \
		( cd $(OUT_DIR) && [ -d $$FILE ] ) && continue ; \
		( echo $(OUT_DIR) | grep -q ".svn" ) && continue; \
		echo "sudo rm $$FILE" >> $(OUT_DIR)$(UNINST_SCRIPT) ; \
	} ; done ;
	echo "sudo rm -fr /Library/StartupItems/tun" >> $(OUT_DIR)$(UNINST_SCRIPT)
	echo "sudo rm -fr /Library/StartupItems/tap" >> $(OUT_DIR)$(UNINST_SCRIPT)
	echo "sudo rm $(UNINST_SCRIPT)" >> $(OUT_DIR)$(UNINST_SCRIPT)
	chmod +x $(OUT_DIR)$(UNINST_SCRIPT)

#miredo: $(MIREDO_DIR)/configure libjudy
#	./Make_universal

tuntap:
	$(MAKE) -C $(TUNTAP_DIR) tap.kext tun.kext
	-$(RMKDIR) $(BUILD_DIR)
	-$(RMKDIR) $(OUT_DIR)/Library/Extensions
	-$(RMKDIR) $(OUT_DIR)/Library/StartupItems
	$(CP) -fr $(TUNTAP_DIR)/tap.kext $(OUT_DIR)/Library/Extensions
	$(CP) -fr $(TUNTAP_DIR)/tun.kext $(OUT_DIR)/Library/Extensions
	$(CP) -fr $(TUNTAP_DIR)/startup_item/tap $(OUT_DIR)/Library/StartupItems
	$(CP) -fr $(TUNTAP_DIR)/startup_item/tun $(OUT_DIR)/Library/StartupItems

package: miredo.pkg

miredo.pkg: tuntap miredo  uninst-script
	$(PACKAGEMAKER) -build -p $@ -proj miredo.pmproj 




$(MIREDO_DIR)/configure: $(MIREDO_DIR)/configure.ac
	cd $(MIREDO_DIR) && ./autogen.sh
	$(CP) $(MISC_DIR)/gettext.h $(MIREDO_DIR)/include/gettext.h

$(MIREDO_BUILD_X86_DIR)/config.status: $(MIREDO_SRC_DIR)/configure $(JUDY_OUT_X86_DIR)/lib/libJudy.a
	-$(RMKDIR) $(BUILD_DIR)
	-$(RMKDIR) $(MIREDO_BUILD_X86_DIR)
	-$(RMKDIR) $(MIREDO_OUT_X86_DIR)
	cd $(MIREDO_BUILD_X86_DIR) && $(MIREDO_SRC_DIR)/configure $(MIREDO_CONFIG_FLAGS) CFLAGS="-arch i386 -O2 -I$(JUDY_OUT_X86_DIR)/include" --with-Judy=$(JUDY_OUT_X86_DIR) LDFLAGS=-L$(JUDY_OUT_X86_DIR)/lib

$(MIREDO_BUILD_PPC_DIR)/config.status: $(MIREDO_SRC_DIR)/configure $(JUDY_OUT_PPC_DIR)/lib/libJudy.a
	-$(RMKDIR) $(BUILD_DIR)
	-$(RMKDIR) $(MIREDO_BUILD_PPC_DIR)
	-$(RMKDIR) $(MIREDO_OUT_PPC_DIR)
	cd $(MIREDO_BUILD_PPC_DIR) && $(MIREDO_SRC_DIR)/configure $(MIREDO_CONFIG_FLAGS) CFLAGS="-arch ppc -O2 -I$(JUDY_OUT_PPC_DIR)/include" --with-Judy=$(JUDY_OUT_PPC_DIR) LDFLAGS=-L$(JUDY_OUT_PPC_DIR)/lib

miredo-x86-conf: $(MIREDO_BUILD_X86_DIR)/config.status

miredo-ppc-conf: $(MIREDO_BUILD_PPC_DIR)/config.status

$(MIREDO_OUT_X86_DIR)$(PREFIX)/sbin/miredo: $(MIREDO_BUILD_X86_DIR)/config.status
	$(MAKE) -C $(MIREDO_BUILD_X86_DIR)
	$(MAKE) -C $(MIREDO_BUILD_X86_DIR) install prefix=$(MIREDO_OUT_X86_DIR)$(PREFIX)

$(MIREDO_OUT_PPC_DIR)$(PREFIX)/sbin/miredo: $(MIREDO_BUILD_PPC_DIR)/config.status
	$(MAKE) -C $(MIREDO_BUILD_PPC_DIR)
	$(MAKE) -C $(MIREDO_BUILD_PPC_DIR) install prefix=$(MIREDO_OUT_PPC_DIR)$(PREFIX)

$(OUT_DIR)$(PREFIX)/sbin/miredo: $(MIREDO_OUT_X86_DIR)$(PREFIX)/sbin/miredo $(MIREDO_OUT_PPC_DIR)$(PREFIX)/sbin/miredo
	$(MAKE_UNIVERSAL) $(OUT_DIR) $(MIREDO_OUT_X86_DIR) $(MIREDO_OUT_PPC_DIR)

miredo: $(OUT_DIR)$(PREFIX)/sbin/miredo $(OUT_DIR)$(SYSCONF)/miredo.conf.sample $(OUT_DIR)/Library/LaunchDaemons/miredo.plist

$(OUT_DIR)$(SYSCONF)/miredo.conf.sample: $(MISC_DIR)/miredo.conf
	-$(RMKDIR) $(OUT_DIR)$(SYSCONF)
	$(CP) $(MISC_DIR)/miredo.conf $(OUT_DIR)$(SYSCONF)/miredo.conf.sample

$(OUT_DIR)/Library/LaunchDaemons/miredo.plist: $(MISC_DIR)/miredo.plist
	-$(RMKDIR) $(OUT_DIR)/Library/LaunchDaemons
	$(CP) $(MISC_DIR)/miredo.plist $(OUT_DIR)/Library/LaunchDaemons/miredo.plist

$(JUDY_SRC_DIR)/configure: $(JUDY_SRC_DIR)/configure.ac
	cd $(JUDY_SRC_DIR) && ./bootstrap
	# Libjudy is a little screwed up, so we need to do a build pass on the main directory first
	cd $(JUDY_SRC_DIR) && ./configure
	make -C $(JUDY_SRC_DIR)
	make -C $(JUDY_SRC_DIR) distclean

libjudy: $(JUDY_OUT_X86_DIR)/lib/libJudy.a $(JUDY_OUT_PPC_DIR)/lib/libJudy.a

libjudy-x86-conf: $(JUDY_BUILD_X86_DIR)/config.status

libjudy-x86-build: $(JUDY_BUILD_X86_DIR)/config.status
	$(MAKE) -C $(JUDY_BUILD_X86_DIR)

$(JUDY_BUILD_X86_DIR)/config.status: $(JUDY_SRC_DIR)/configure
	-$(RMKDIR) $(BUILD_DIR)
	-$(RMKDIR) $(JUDY_BUILD_X86_DIR)
	-$(RMKDIR) $(JUDY_OUT_X86_DIR)
	cd $(JUDY_BUILD_X86_DIR) && $(JUDY_SRC_DIR)/configure $(JUDY_CONFIG_FLAGS) CFLAGS='-arch i386 -O2 -I$(JUDY_SRC_DIR)/src -I$(JUDY_SRC_DIR)/src/Judy1 -I$(JUDY_SRC_DIR)/src/JudyCommon' --prefix=$(JUDY_OUT_X86_DIR)

$(JUDY_OUT_X86_DIR)/lib/libJudy.a: $(JUDY_BUILD_X86_DIR)/config.status
	$(MAKE) -C $(JUDY_BUILD_X86_DIR) install

libjudy-ppc-conf: $(JUDY_BUILD_PPC_DIR)/config.status

libjudy-ppc-build: $(JUDY_BUILD_PPC_DIR)/config.status
	$(MAKE) -C $(JUDY_BUILD_PPC_DIR)

$(JUDY_BUILD_PPC_DIR)/config.status: $(JUDY_SRC_DIR)/configure
	-$(RMKDIR) $(BUILD_DIR)
	-$(RMKDIR) $(JUDY_BUILD_PPC_DIR)
	-$(RMKDIR) $(JUDY_OUT_PPC_DIR)
	cd $(JUDY_BUILD_PPC_DIR) && $(JUDY_SRC_DIR)/configure $(JUDY_CONFIG_FLAGS) CFLAGS='-arch ppc -O2 -I$(JUDY_SRC_DIR)/src -I$(JUDY_SRC_DIR)/src/Judy1 -I$(JUDY_SRC_DIR)/src/JudyCommon' --prefix=$(JUDY_OUT_PPC_DIR)

$(JUDY_OUT_PPC_DIR)/lib/libJudy.a: $(JUDY_BUILD_PPC_DIR)/config.status
	$(MAKE) -C $(JUDY_BUILD_PPC_DIR) install


pref-pane: $(MIREDO_PREF_OUT_DIR)/Miredo.prefPane

$(MIREDO_PREF_SRC_DIR)/build/Release/Miredo.prefPane:
	cd $(MIREDO_PREF_SRC_DIR) && $(XCODEBUILD)

$(MIREDO_PREF_OUT_DIR)/Miredo.prefPane: $(MIREDO_PREF_SRC_DIR)/build/Release/Miredo.prefPane
	$(RMKDIR) $(MIREDO_PREF_OUT_DIR)
	$(CP) -r $(MIREDO_PREF_SRC_DIR)/build/Release/Miredo.prefPane $(MIREDO_PREF_OUT_DIR)/Miredo.prefPane







miredo.pkg.tar.gz: miredo.pkg
	tar cvzf miredo.pkg.tar.gz miredo.pkg

miredo.pkg.zip: miredo.pkg
	zip -r miredo.pkg.zip miredo.pkg
	
clean:
	$(RMDIR) $(BUILD_DIR)
	$(RMDIR) miredo.pkg
	$(RM) miredo.pkg.tar.gz
	$(RM) miredo.pkg.zip
	$(MAKE) -C $(TUNTAP_DIR) clean

mrproper: clean
	$(RM) $(MIREDO_DIR)/configure
	$(RM) $(JUDY_SRC_DIR)/configure
