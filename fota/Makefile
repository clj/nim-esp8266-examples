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
TARGET		= user

# which modules (subdirectories) of the project to include in compiling
MODULES		= driver user
EXTRA_INCDIR	= include

# libraries used in this project, mainly provided by the SDK
LIBS		= c gcc hal pp phy net80211 lwip wpa crypto main upgrade

# compiler flags using during compilation of source files
CFLAGS		= -Os -g -O2 -Wpointer-arith -Wundef -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals  -D__ets__ -DICACHE_FLASH -DHAVE_STDINT_H

# linker flags used to generate the main object file
LDFLAGS		= -nostdlib -Wl,--no-check-sections -u call_user_start -Wl,-static -Wl,-Map,$(TARGET_MAP)

# linker script used for the above linkier step
LD_SCRIPT_1	?= eagle.app.v6.new.1024.app1.ld
LD_SCRIPT_2	?= eagle.app.v6.new.1024.app2.ld
LD_SCRIPT_DIR	?= $(NIM_SDK_BASE)/esp8266/nonos-sdk/ld/
#LD_SCRIPT_DIR	= $(SDK_BASE)/ld/

# various paths from the SDK used in this project
SDK_LIBDIR	= lib
SDK_LDDIR	= ld
SDK_INCDIR	= include include/json

# nim library path
NIM_LIBDIR	:= $(shell nim dump 2>&1 | grep '/lib$$' | head -n 1)

FLASH_SIZE ?= 1MB
# FOTA addresses
# See Table 4-4 in https://www.espressif.com/sites/default/files/2a-esp8266-sdk_getting_started_guide_en_0.pdf
BIN_ADDRESS_1 ?= 0x01000
BIN_ADDRESS_2 ?= 0x81000
BOOTLOADER_ADDRESS ?= 0x00000
ESP_INIT_DATA_DEFAULT_ADDR = 0xFC000
BLANK_1_ADDR ?= 0XFB000
BLANK_2_ADDR ?= 0XFE000
USER_DATA_ADDR	= 0xE1000

BOOT_BIN ?= $(addprefix $(SDK_BASE)/bin/,boot_v1.7.bin)
ESP_INIT_DATA_DEFAULT_BIN ?= $(SDK_BASE)/bin/esp_init_data_default_v08.bin
BLANK_BIN ?= $(SDK_BASE)/bin/blank.bin

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
TARGET_OUT_1	:= $(addprefix $(BUILD_BASE)/,$(TARGET)_1.out)
TARGET_MAP_1	:= $(TARGET_OUT_1:out=map)
TARGET_OUT_2	:= $(addprefix $(BUILD_BASE)/,$(TARGET)_2.out)
TARGET_MAP_2	:= $(TARGET_OUT_2:out=map)

LD_SCRIPT_1	:= $(addprefix -T$(LD_SCRIPT_DIR),$(LD_SCRIPT_1))
LD_SCRIPT_2	:= $(addprefix -T$(LD_SCRIPT_DIR),$(LD_SCRIPT_2))
LD_SCRIPT_INCL	:= $(addprefix -L,$(LD_SCRIPT_DIR))

INCDIR		:= $(addprefix -I,$(SRC_DIR) $(NIM_SDK_BASE)/esp8266/nonos-sdk)
EXTRA_INCDIR	:= $(addprefix -I,$(EXTRA_INCDIR))
MODULE_INCDIR	:= $(addsuffix /include,$(INCDIR))
NIM_INCDIR	:= -I$(NIM_CACHE) -I$(NIM_LIBDIR)

OUTPUT_1	:= $(addprefix $(FW_BASE)/,$(TARGET)1.bin)
OUTPUT_2	:= $(addprefix $(FW_BASE)/,$(TARGET)2.bin)

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

.PHONY: all checkdirs flash flash-data gen-data flash-all clean

all: checkdirs $(OUTPUT_1) $(OUTPUT_2)

$(OUTPUT_1): $(TARGET_OUT_1) | $(FW_BASE)
	$(vecho) "FW      $@"
	$(Q) $(ESPTOOL) elf2image --version=2 --flash_size $(FLASH_SIZE) $< -o $@

$(OUTPUT_2): $(TARGET_OUT_2) | $(FW_BASE)
	$(vecho) "FW      $@"
	$(Q) $(ESPTOOL) elf2image --version=2 --flash_size $(FLASH_SIZE) $< -o $@

$(TARGET_OUT_1): TARGET_MAP=$(TARGET_MAP_1)
$(TARGET_OUT_1): LD_SCRIPT=$(LD_SCRIPT_1)
$(TARGET_OUT_1): $(APP_AR)
	$(vecho) "LD      $@"
	$(Q) $(LD) $(LD_SCRIPT_INCL) -L$(SDK_LIBDIR) $(LD_SCRIPT) $(LDFLAGS) -Wl,--start-group $(LIBS) $(APP_AR) -Wl,--end-group -o $@

$(TARGET_OUT_2): TARGET_MAP=$(TARGET_MAP_2)
$(TARGET_OUT_2): LD_SCRIPT=$(LD_SCRIPT_2)
$(TARGET_OUT_2): $(APP_AR)
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

flash: $(OUTPUT_1)
	$(ESPTOOL) --port $(ESPPORT) --baud $(ESPTOOL_BAUD) write_flash --flash_size $(FLASH_SIZE) $(BOOTLOADER_ADDRESS) $(BOOT_BIN) $(BIN_ADDRESS_1) $(OUTPUT_1) $(ESP_INIT_DATA_DEFAULT_ADDR) $(ESP_INIT_DATA_DEFAULT_BIN) $(BLANK_1_ADDR) $(BLANK_BIN) $(BLANK_2_ADDR) $(BLANK_BIN)

gen-data:
	$(vecho) "NIM RUN $@"
	nim c -r $(NIM_SEARCH_PATHS) user/user_data.nim

flash-data:
	$(ESPTOOL) --port $(ESPPORT) --baud $(ESPTOOL_BAUD) write_flash --flash_size $(FLASH_SIZE) $(USER_DATA_ADDR) user_data.bin

#$(FW_BASE)/user_data.py: user_data.py
#	$(vecho) "CP      $@"
#	$(Q) cp $< $@

flash-all: flash $(OUTPUT_2)
	$(ESPTOOL) --port $(ESPPORT) --baud $(ESPTOOL_BAUD) write_flash --flash_size $(FLASH_SIZE) $(BIN_ADDRESS_2) $(OUTPUT_2)

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
