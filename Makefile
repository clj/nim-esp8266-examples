subdir_targets := all clean
subdirs := $(dir $(wildcard */Makefile))
goals := $(MAKECMDGOALS)
firmwares := $(addsuffix firmware/,$(subdirs))
release_tag = $(shell (git describe --exact-match --tags $$(git log -n1 --pretty='%h') 2>/dev/null || git describe --tags) | sed -e "s/release-//")
release_name = nim_esp8266_examples-$(release_tag)

# Set path related variables to have absolute paths
override XTENSA_TOOLS_ROOT := $(abspath $(XTENSA_TOOLS_ROOT))
override SDK_BASE := $(abspath $(SDK_BASE))
override NIM_SDK_BASE := $(abspath $(NIM_SDK_BASE))

# Pass the absolute paths to recursive makes even if overriden on command line
_PATH_VARS := \
  XTENSA_TOOLS_ROOT \
  SDK_BASE \
  NIM_SDK_BASE
MAKEOVERRIDES += $(foreach v,$(_PATH_VARS),$(v)=$($(v)))

V ?= $(VERBOSE)
ifeq ("$(V)","1")
Q :=
vecho := @true
print_dirs :=
else
Q := @
vecho := @echo
print_dirs := --no-print-directory
endif

.PHONY: $(subdir_targets) $(subdirs) dist

$(subdir_targets): $(subdirs)
$(subdirs):
	$(vecho) "MAKE    $(goals) $@"
	$(Q) $(MAKE) $(print_dirs) -C $@ $(goals)

dist: goals=all
dist: $(release_name).tar.gz $(release_name).zip

$(release_name).tar.gz: all
	$(vecho) "TAR     $@"
	$(Q) tar -czf $@ $(firmwares)

$(release_name).zip: all
	$(vecho) "ZIP     $@"
	$(Q) zip -qr $(@F) $(firmwares)