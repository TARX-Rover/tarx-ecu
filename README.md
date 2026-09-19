# kyrax Cyclic Scheduling RTOS Base

STM32F407 firmware using a C++ application with the C-based FreeRTOS kernel.

## Build with CMake

The Arm GNU embedded toolchain, CMake, and Ninja must be available on `PATH`.

```sh
cmake --preset stm32-debug
cmake --build --preset stm32-debug
```

The build produces `build/main.elf` and `build/main.map`.

## Flash

Connect the ST-Link probe, then run:

```sh
cmake --build --preset stm32-debug --target flash
```

## Debug

Start OpenOCD in one terminal:

```sh
cmake --build --preset stm32-debug --target openocd-server
```

Then start GDB in another terminal:

```sh
cmake --build --preset stm32-debug --target gdb
```
