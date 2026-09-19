/**
 *@file main.cpp
 *@brief Register Level Programming Simple Blink Project using FreeRTOS delayUntil
 **/

#include <stdint.h>
#include <stddef.h>
#include <cstdint>
#include <cstddef>

#include "stm32f4xx.h"

#include "FreeRTOS.h"
#include "task.h"

#define MODER_WIDTH 2

class Gpio{
public:
    Gpio(GPIO_TypeDef *gpio_port, std::uint32_t pin_mask)
        : port{gpio_port}, mask{pin_mask} {}

    void toggle(){
        (port->ODR) ^= mask;
    }

    void write(bool value){
        (port->BSRR) = value ? mask : (mask << 16);
    }

private:
    GPIO_TypeDef *port;
    std::uint32_t mask;
};

/* Symbols called from the C startup code and FreeRTOS kernel need C linkage. */
extern "C" {

uint32_t SystemCoreClock = 16000000UL; /* Required by FreeRTOS port.c for tick timer setup */

/* FreeRTOS hooks */
void vApplicationIdleHook(void) { }
void vApplicationTickHook(void) { }

void vApplicationMallocFailedHook(void) {
    taskDISABLE_INTERRUPTS();
    for(;;) { }
}

void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName) {
    (void)xTask;
    (void)pcTaskName;
    taskDISABLE_INTERRUPTS();
    for(;;) { }
}

/* libc minimal helpers */
void *memcpy(void *dest, const void *src, size_t n) {
    unsigned char *d = (unsigned char *)dest;
    const unsigned char *s = (const unsigned char *)src;
    while (n--) *d++ = *s++;
    return dest;
}

void *memset(void *s, int c, size_t n) {
    unsigned char *p = (unsigned char *)s;
    while (n--) *p++ = (unsigned char)c;
    return s;
}

} /* extern "C" */

/* FreeRTOS invokes task entry points through its C API. */
extern "C" {

/* Blink task toggles PD12 every 100 ms using vTaskDelayUntil */
static void BlinkTask_100ms(void *pvParameters) {
    (void)pvParameters;
    TickType_t xLastWakeTime = xTaskGetTickCount();
    const TickType_t xPeriod = pdMS_TO_TICKS(100);

    Gpio led1{GPIOD, (1 << 12U)};

    for(;;) {
        //GPIOD->ODR ^= (1 << 12);
        led1.toggle();
        vTaskDelayUntil(&xLastWakeTime, xPeriod);
    }
}

/* Blink task toggles PD13 every 500 ms using vTaskDelayUntil */
static void BlinkTask_500ms(void *pvParameters) {
    (void)pvParameters;
    TickType_t xLastWakeTime = xTaskGetTickCount();
    const TickType_t xPeriod = pdMS_TO_TICKS(500);

    Gpio led2{GPIOD, (1 << 13U)};
    for(;;) {
        led2.toggle();
        vTaskDelayUntil(&xLastWakeTime, xPeriod);
    }
}

/* Blink task toggles PD14 every 1000 ms using vTaskDelayUntil */
static void BlinkTask_1000ms(void *pvParameters) {
    (void)pvParameters;
    TickType_t xLastWakeTime = xTaskGetTickCount();
    const TickType_t xPeriod = pdMS_TO_TICKS(1000);

    Gpio led3{GPIOD, (1 << 14U)};
    for(;;) {
        led3.toggle();
        vTaskDelayUntil(&xLastWakeTime, xPeriod);
    }
}

/* Blink task toggles PD15 every 2000 ms using vTaskDelayUntil */
static void BlinkTask_2000ms(void *pvParameters) {
    (void)pvParameters;
    TickType_t xLastWakeTime = xTaskGetTickCount();
    const TickType_t xPeriod = pdMS_TO_TICKS(2000);

    Gpio led4{GPIOD, (1 << 15U)};
    for(;;) {
        led4.toggle();
        vTaskDelayUntil(&xLastWakeTime, xPeriod);
    }
}

} /* extern "C" */

/* Hardware setup for GPIOD pins PD12..PD15 */
static void prvSetupHardware(void) {
    RCC->AHB1ENR |= (1 << 3); // enable GPIOD clock

    for (uint32_t pin = 12; pin <= 15; pin++) {
        GPIOD->MODER &= ~(3 << (pin * MODER_WIDTH)); // reset mode
        GPIOD->MODER |=  (1 << (pin * MODER_WIDTH)); // set as output
    }
}

namespace mcu{
    void example(){
        std::uint32_t reg_val{40'000'000U};

    }
}



/**
 *@brief Main entry point
 **/
int main(void) {

    prvSetupHardware();

    mcu::example();

    // Create separate blink tasks
    xTaskCreate(BlinkTask_100ms,  "Blink_100ms",  configMINIMAL_STACK_SIZE, NULL, tskIDLE_PRIORITY + 1, NULL);
    xTaskCreate(BlinkTask_500ms,  "Blink_500ms",  configMINIMAL_STACK_SIZE, NULL, tskIDLE_PRIORITY + 1, NULL);
    xTaskCreate(BlinkTask_1000ms, "Blink_1000ms", configMINIMAL_STACK_SIZE, NULL, tskIDLE_PRIORITY + 1, NULL);
    xTaskCreate(BlinkTask_2000ms, "Blink_2000ms", configMINIMAL_STACK_SIZE, NULL, tskIDLE_PRIORITY + 1, NULL);

    // Start scheduler
    vTaskStartScheduler();

    for(;;) { } // should never reach here
}
