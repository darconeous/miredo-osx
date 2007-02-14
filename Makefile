

##### Path Variables
MIREDO_DIR=miredo
MISC_DIR=misc
BUILD_DIR=build
UTIL_DIR=util
OUT_DIR=$(BUILD_DIR)/out

##### Tool Variables
PACKAGE=$(UTIL_DIR)/package

##### Targets

all: $(MIREDO_DIR)/configure
	./Make_universal

package:
	$(PACKAGE) $(OUT_DIR) miredo.info -r Resources -bzip

$(MIREDO_DIR)/configure: $(MIREDO_DIR)/configure.ac
	cd $(MIREDO_DIR) && ./autogen.sh
	cp $(MISC_DIR)/gettext.h $(MIREDO_DIR)/include/gettext.h

clean:
	$(RM) -r $(BUILD_DIR)

mrproper: clean
	$(RM) $(MIREDO_DIR)/configure
