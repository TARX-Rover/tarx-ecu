cmake_minimum_required(VERSION 3.21)

project(kyraxCyclicSched LANGUAGES C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

set(MCU_FLAGS
    -mcpu=cortex-m4
    -mthumb
    -mfloat-abi=hard
    -mfpu=fpv4-sp-d16
)

set(FREERTOS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/FreeRTOS-Kernel")
set(FREERTOS_PORT_DIR "${FREERTOS_DIR}/portable/GCC/ARM_CM4F")
set(FREERTOS_HEAP_DIR "${FREERTOS_DIR}/portable/MemMang")
set(LINKER_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/startup/linkerscript_STM32F407VGT6.ld")

set(FREERTOS_SOURCES
    "${FREERTOS_DIR}/croutine.c"
    "${FREERTOS_DIR}/event_groups.c"
    "${FREERTOS_DIR}/list.c"
    "${FREERTOS_DIR}/queue.c"
    "${FREERTOS_DIR}/stream_buffer.c"
    "${FREERTOS_DIR}/tasks.c"
    "${FREERTOS_DIR}/timers.c"
    "${FREERTOS_PORT_DIR}/port.c"
    "${FREERTOS_HEAP_DIR}/heap_4.c"
)

add_executable(firmware
    src/main.cpp
    startup/startup_STM32F407VGT6.c
    ${FREERTOS_SOURCES}
)

set_target_properties(firmware PROPERTIES
    OUTPUT_NAME main
    SUFFIX .elf
)

target_include_directories(firmware PRIVATE
    inc
    inc/CMSIS/Core/Include
    inc/cmsis-device-f4/Include
)

# FreeRTOS ships its own stdint.h fallback. Search its directories after the
# compiler's standard headers so that the Arm toolchain's stdint.h wins.
target_compile_options(firmware PRIVATE
    ${MCU_FLAGS}
    -Wall
    -ffreestanding
    "SHELL:-idirafter ${FREERTOS_DIR}/include"
    "SHELL:-idirafter ${FREERTOS_PORT_DIR}"
    "SHELL:-idirafter ${FREERTOS_HEAP_DIR}"
    $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>
    $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>
    $<$<COMPILE_LANGUAGE:CXX>:-fno-threadsafe-statics>
    $<$<COMPILE_LANGUAGE:CXX>:-fno-use-cxa-atexit>
)

target_link_options(firmware PRIVATE
    ${MCU_FLAGS}
    -nostartfiles
    "-T${LINKER_SCRIPT}"
    "-Wl,-Map=${CMAKE_CURRENT_BINARY_DIR}/main.map"
    -specs=nosys.specs
)

target_link_libraries(firmware PRIVATE
    -Wl,--start-group
    c
    gcc
    -Wl,--end-group
)

# Relink whenever the linker script changes.
set_property(TARGET firmware APPEND PROPERTY LINK_DEPENDS "${LINKER_SCRIPT}")

if(CMAKE_SIZE)
    add_custom_command(TARGET firmware POST_BUILD
        COMMAND "${CMAKE_SIZE}" "$<TARGET_FILE:firmware>"
        COMMENT "Firmware size"
        VERBATIM
    )
endif()

find_program(OPENOCD_EXECUTABLE NAMES openocd)
find_program(GDB_EXECUTABLE NAMES arm-none-eabi-gdb)

if(OPENOCD_EXECUTABLE)
    add_custom_target(flash
        COMMAND "${OPENOCD_EXECUTABLE}"
            -f interface/stlink.cfg
            -f target/stm32f4x.cfg
            -c "program $<TARGET_FILE:firmware> verify reset exit"
        DEPENDS firmware
        COMMENT "Flashing STM32F407 with OpenOCD"
        USES_TERMINAL
        VERBATIM
    )

    add_custom_target(openocd-server
        COMMAND "${OPENOCD_EXECUTABLE}"
            -f interface/stlink.cfg
            -f target/stm32f4x.cfg
        COMMENT "Starting OpenOCD debug server on localhost:3333"
        USES_TERMINAL
        VERBATIM
    )
endif()

if(GDB_EXECUTABLE)
    add_custom_target(gdb
        COMMAND "${GDB_EXECUTABLE}"
            "$<TARGET_FILE:firmware>"
            -x "${CMAKE_CURRENT_SOURCE_DIR}/startup/debug.gdb"
        DEPENDS firmware
        COMMENT "Connecting GDB to OpenOCD on localhost:3333"
        USES_TERMINAL
        VERBATIM
    )
endif()
