# Binaries
CC = arm-none-eabi-gcc
CXX = arm-none-eabi-g++
GDB ?= arm-none-eabi-gdb

# SRC Directories
SRC_DIR = src
SUP_DIR = startup
# FreeRTOS files
SRC_FREERTOS_DIR = thirdparty/FreeRTOS-Kernel
SRC_FREERTOS_PORTABLE_DIR = thirdparty/FreeRTOS-Kernel/portable/GCC/ARM_CM4F
SRC_FREERTOS_MEMMANG_DIR = thirdparty/FreeRTOS-Kernel/portable/MemMang
# END FreeRTOS files
OBJ_DIR = obj
INC_DIR = inc
INC_DIR_CMSIS = inc/CMSIS/Core/Include
INC_DIR_CMSIS_DEV_F4 = inc/cmsis-device-f4/Include
INC_DIR_FREERTOS = thirdparty/FreeRTOS-Kernel/include
INC_DIR_FREERTOS_PORTABLE = thirdparty/FreeRTOS-Kernel/portable/GCC/ARM_CM4F
INC_DIR_FREERTOS_MEMMANG = thirdparty/FreeRTOS-Kernel/portable/MemMang
DEB_DIR = debug

# Application files may be C or C++. Startup and FreeRTOS stay compiled as C.
APP_C_SRC := $(wildcard $(SRC_DIR)/*.c)
APP_CXX_SRC := $(wildcard $(SRC_DIR)/*.cpp)
STARTUP_SRC := $(wildcard $(SUP_DIR)/*.c)
FREERTOS_SRC := $(wildcard $(SRC_FREERTOS_DIR)/*.c)
FREERTOS_PORTABLE_SRC := $(wildcard $(SRC_FREERTOS_PORTABLE_DIR)/*.c)
FREERTOS_MEMMANG_SRC := $(wildcard $(SRC_FREERTOS_MEMMANG_DIR)/*.c)

OBJ := $(patsubst $(SRC_DIR)/%.c,$(SRC_DIR)/$(OBJ_DIR)/%.o,$(APP_C_SRC))
OBJ += $(patsubst $(SRC_DIR)/%.cpp,$(SRC_DIR)/$(OBJ_DIR)/%.o,$(APP_CXX_SRC))
OBJ += $(patsubst $(SUP_DIR)/%.c,$(SRC_DIR)/$(OBJ_DIR)/%.o,$(STARTUP_SRC))
OBJ += $(patsubst $(SRC_FREERTOS_DIR)/%.c,$(SRC_DIR)/$(OBJ_DIR)/%.o,$(FREERTOS_SRC))
OBJ += $(patsubst $(SRC_FREERTOS_PORTABLE_DIR)/%.c,$(SRC_DIR)/$(OBJ_DIR)/%.o,$(FREERTOS_PORTABLE_SRC))
OBJ += $(patsubst $(SRC_FREERTOS_MEMMANG_DIR)/%.c,$(SRC_DIR)/$(OBJ_DIR)/%.o,$(FREERTOS_MEMMANG_SRC))
LD := $(wildcard $(SUP_DIR)/*.ld)

# FLAGS
MARCH = cortex-m4
ARCH_FLAGS = -mcpu=$(MARCH) -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
# Standard includes first: CMSIS + STM32 device definitions provide core types/vector addresses.
# FreeRTOS include files are added with -idirafter to avoid shadowing system <stdint.h>.
CPPFLAGS = -I$(INC_DIR) -I$(INC_DIR_CMSIS) -I$(INC_DIR_CMSIS_DEV_F4) -idirafter $(INC_DIR_FREERTOS) -idirafter $(INC_DIR_FREERTOS_PORTABLE) -idirafter $(INC_DIR_FREERTOS_MEMMANG)
CFLAGS = -g -Wall $(ARCH_FLAGS) -ffreestanding -std=gnu11
CXXFLAGS = -g -Wall $(ARCH_FLAGS) -ffreestanding -std=gnu++17 -fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-use-cxa-atexit
# Link with the C++ driver, but use the custom reset handler instead of a hosted C runtime.
LFLAGS = $(ARCH_FLAGS) -nostartfiles -T $(LD) -Wl,-Map=$(DEB_DIR)/main.map -specs=nosys.specs

# OpenOCD searches its installed scripts directory automatically. Keeping these
# paths relative makes them work with Homebrew on both Apple Silicon and Intel
# Macs, as well as with standard OpenOCD installations on other platforms.
OPENOCD ?= openocd
OPENOCD_INTERFACE ?= interface/stlink.cfg
OPENOCD_TARGET ?= target/stm32f4x.cfg

# Targets
TARGET = $(DEB_DIR)/main.elf

all: $(OBJ) $(TARGET)

$(SRC_DIR)/$(OBJ_DIR)/%.o : $(SRC_DIR)/%.c | mkobj
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(SRC_DIR)/$(OBJ_DIR)/%.o : $(SRC_DIR)/%.cpp | mkobj
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

$(SRC_DIR)/$(OBJ_DIR)/%.o : $(SUP_DIR)/%.c | mkobj
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(SRC_DIR)/$(OBJ_DIR)/%.o : $(SRC_FREERTOS_DIR)/%.c | mkobj
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(SRC_DIR)/$(OBJ_DIR)/%.o : $(SRC_FREERTOS_PORTABLE_DIR)/%.c | mkobj
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(SRC_DIR)/$(OBJ_DIR)/%.o : $(SRC_FREERTOS_MEMMANG_DIR)/%.c | mkobj
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(TARGET) : $(OBJ) $(LD) | mkdeb
	$(CXX) $(LFLAGS) -o $@ $(OBJ) -Wl,--start-group -lc -lgcc -Wl,--end-group

mkobj:
	mkdir -p $(SRC_DIR)/$(OBJ_DIR)

mkdeb:
	mkdir -p $(DEB_DIR)

flash: FORCE
	$(OPENOCD) -f $(OPENOCD_INTERFACE) -f $(OPENOCD_TARGET) &
	$(GDB) $(TARGET) -x $(SUP_DIR)/flash.gdb

debug: FORCE
	$(OPENOCD) -f $(OPENOCD_INTERFACE) -f $(OPENOCD_TARGET) &
	$(GDB) $(TARGET) -x $(SUP_DIR)/debug.gdb

edit: FORCE
	vim -S Session.vim

doxy: FORCE
	cd ./docs && doxygen Doxyfile

clean: FORCE
	rm -rf $(SRC_DIR)/$(OBJ_DIR) $(DEB_DIR)

FORCE:

.PHONY: all mkobj mkdeb clean FORCE flash debug edit doxy
