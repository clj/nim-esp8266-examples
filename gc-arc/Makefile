# Makefile for ESP8266 projects
#
# Thanks to:
# - zarya
# - Jeroen Domburg (Sprite_tm)
# - Christian Klippel (mamalala)
# - Tommie Gannert (tommie)
# - Christian Jacobsen (clj)
#
# Changelog:
# - 2014-10-06: Changed the variables to include the header file directory
# - 2014-10-06: Added global var for the Xtensa tool root
# - 2014-11-23: Updated for SDK 0.9.3
# - 2014-12-25: Replaced esptool by esptool.py
# - 2019-09-09: Added Nim support

# Output directors to store intermediate compiled files
# relative to the project directory
BUILD_BASE	= build
FW_BASE		= firmware
NIM_CACHE	= $(BUILD_BASE)/user/nimcache

# base directory for the compiler
XTENSA_TOOLS_ROOT ?= /opt/Espressif/crosstool-NG/builds/xtensa-lx106-elf/bin

# base directory of the ESP8266 related SDKS
SDK_BASE	?= /opt/Espressif/ESP8266_SDK
NIM_SDK_BASE	?= /opt/nim-esp8266-sdk

# Set path related variables to have absolute paths
override XTENSA_TOOLS_ROOT := $(abspath $(XTENSA_TOOLS_ROOT))
override SDK_BASE := $(abspath $(SDK_BASE))
override NIM_SDK_BASE := $(abspath $(NIM_SDK_BASE))

# esptool.py options
ESPPORT		?= /dev/ttyUSB0
ESPTOOL		?= esptool.py
ESPTOOL_BAUD	?= 115200

# name for the target project
TARGET		= app

# which modules (subdirectories) of the project to include in compiling
MODULES		= driver user
EXTRA_INCDIR	= include

# libraries used in this project, mainly provided by the SDK
LIBS		= c gcc hal pp phy net80211 lwip wpa crypto main

# compiler flags using during compilation of source files
CFLAGS		= -Os -g -O2 -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals  -D__ets__ -DICACHE_FLASH -DHAVE_STDINT_H

# linker flags used to generate the main object file
LDFLAGS		= -nostdlib -Wl,--no-check-sections -u call_user_start -Wl,-static -Wl,-Map,$(TARGET_MAP)

# linker script used for the above linkier step
LD_SCRIPT	?= eagle.app.v6.ld
LD_SCRIPT_DIR	?= $(NIM_SDK_BASE)/esp8266/nonos-sdk/ld/

# various paths from the SDK used in this project
SDK_LIBDIR	= lib
SDK_LDDIR	= ld
SDK_INCDIR	= include include/json

# nim library path
NIM_LIBDIR	:= $(shell nim dump 2>&1 | grep '/lib$$' | head -n 1)

FLASH_SIZE	?= 1MB
# we create two different files for uploading into the flash
# these are the names and options to generate them
FW_FILE_1_ADDR	= 0x00000
FW_FILE_2_ADDR	= 0x10000

# select which tools to use as compiler, librarian and linker
CC		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
AR		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-ar
LD		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc



####
#### no user configurable options below here
####
SRC_DIR		:= $(MODULES)
BUILD_DIR	:= $(addprefix $(BUILD_BASE)/,$(MODULES))
NIM_BUILD_DIR 	:= $(NIM_CACHE)

SDK_LIBDIR	:= $(addprefix $(SDK_BASE)/,$(SDK_LIBDIR))
SDK_INCDIR	:= $(addprefix -I$(SDK_BASE)/,$(SDK_INCDIR))
NIM_SEARCH_PATHS:= $(addprefix --path:,$(NIM_SDK_BASE) $(NIM_SDK_BASE)/../nim-sdk) $(NIM_SEARCH_PATHS)

SRC		:= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.c))
OBJ		:= $(patsubst %.c,$(BUILD_BASE)/%.o,$(SRC))
NIM_OBJ		:= $(patsubst %.c,$(NIM_CACHE)/%.o,$(shell awk '/gcc -c/{ print $$NF }' $(NIM_CACHE)/compile_main.sh 2> /dev/null))
LIBS		:= $(addprefix -l,$(LIBS))
APP_AR		:= $(addprefix $(BUILD_BASE)/,$(TARGET)_app.a)
TARGET_OUT	:= $(addprefix $(BUILD_BASE)/,$(TARGET).out)
TARGET_MAP	:= $(addprefix $(BUILD_BASE)/,$(TARGET).map)

LD_SCRIPT	:= $(addprefix -T$(LD_SCRIPT_DIR),$(LD_SCRIPT))
LD_SCRIPT_INCL	:= $(addprefix -L,$(LD_SCRIPT_DIR))

INCDIR		:= $(addprefix -I,$(SRC_DIR) $(NIM_SDK_BASE)/esp8266/nonos-sdk)
EXTRA_INCDIR	:= $(addprefix -I,$(EXTRA_INCDIR))
MODULE_INCDIR	:= $(addsuffix /include,$(INCDIR))
NIM_INCDIR	:= -I$(NIM_CACHE) -I$(NIM_LIBDIR)

FW_FILE_1	:= $(addprefix $(FW_BASE)/,$(FW_FILE_1_ADDR).bin)
FW_FILE_2	:= $(addprefix $(FW_BASE)/,$(FW_FILE_2_ADDR).bin)

V ?= $(VERBOSE)
ifeq ("$(V)","1")
Q :=
vecho := @true
else
Q := @
vecho := @echo
endif

vpath %.c $(SRC_DIR)

define compile-objects
$1/%.o: %.c
	$(vecho) "CC      $$<"
	$(Q) $(CC) $(NIM_INCDIR) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CFLAGS) -c $$< -o $$@
endef

.PHONY: all checkdirs flash clean

all: checkdirs $(TARGET_OUT) $(FW_FILE_1) $(FW_FILE_2)

$(FW_BASE)/%.bin: $(TARGET_OUT) | $(FW_BASE)
	$(vecho) "FW      $(FW_BASE)/"
	$(Q) $(ESPTOOL) elf2image --flash_size $(FLASH_SIZE) -o $(FW_BASE)/ $(TARGET_OUT)

$(TARGET_OUT): $(APP_AR)
	$(vecho) "LD      $@"
	$(Q) $(LD) $(LD_SCRIPT_INCL) -L$(SDK_LIBDIR) $(LD_SCRIPT) $(LDFLAGS) -Wl,--start-group $(LIBS) $(APP_AR) -Wl,--end-group -o $@

$(APP_AR): $(OBJ) $(NIM_OBJ)
	$(vecho) "AR      $@"
	$(Q) $(AR) cru $@ $^

checkdirs: | $(BUILD_DIR) $(FW_BASE)

$(BUILD_DIR):
	$(vecho) "MKDIR   $@"
	$(Q) mkdir -p $@

$(FW_BASE):
	$(vecho) "MKDIR   $@"
	$(Q) mkdir -p $@

flash: $(FW_FILE_1) $(FW_FILE_2)
	$(ESPTOOL) --port $(ESPPORT) --baud $(ESPTOOL_BAUD) write_flash --flash_size $(FLASH_SIZE) $(FW_FILE_1_ADDR) $(FW_FILE_1) $(FW_FILE_2_ADDR) $(FW_FILE_2)

clean:
	$(vecho) "CLEAN"
	$(Q) rm -rf $(FW_BASE) $(BUILD_BASE)

$(NIM_CACHE)/%.nim.c $(NIM_CACHE)/nim_%.h: user/%.nim user/%.nim.cfg
	$(vecho) "NIM     $@"
	$(Q) nim c --cpu:arm --os:standalone --noMain --compileOnly --verbosity:0 --genDeps:on --nimcache:$(NIM_CACHE) --header:nim_$*.h -d:nimMinHeapPages=1 $(NIM_SEARCH_PATHS) $<
	$(Q) touch $@
	$(Q) sed -e 's!^!$(NIM_CACHE)/main.nim.c: !' -e 's!#!\\#!' < $(NIM_CACHE)/main.deps > $(NIM_CACHE)/main.deps.mk

$(NIM_CACHE)/nim_built.mk: $(NIM_CACHE)/main.nim.c
	$(vecho) "TOUCH   $@"
	$(Q) touch $@


$(foreach bdir,$(BUILD_DIR),$(eval $(call compile-objects,$(bdir))))

%.o: %.c
%.o: %.c
	$(vecho) "CC      $<"
	$(Q) $(CC) $(NIM_INCDIR) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CFLAGS)  -c $< -o $@

$(NIM_CACHE)/stdlib_system.nim.o: CFLAGS:=$(CFLAGS) -D'realloc(ptr, size)=os_realloc(ptr, size)' -D'calloc(count, size)=os_calloc(count, size)' -D'malloc(size)=os_malloc(size)' -D'free(ptr)=os_free(ptr)' -include stdlib.h -include mem.h

$(NIM_CACHE)/main.deps.mk:

ifneq ($(MAKECMDGOALS), clean)
-include $(NIM_CACHE)/nim_built.mk
-include $(NIM_CACHE)/main.deps.mk
sdk_version_check=$(shell $(NIM_SDK_BASE)/esp8266/nonos-sdk/bin/check_sdk_version.sh $(SDK_BASE))
ifneq ($(sdk_version_check),)
$(error $(sdk_version_check))
endif
endif
