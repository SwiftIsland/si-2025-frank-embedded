#define ESP_PLATFORM 1

#include <stdio.h>

#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "sdkconfig.h"
#include "esp_timer.h"

#include "u8g2.h"
#include "u8g2_esp32_hal.h"
#include "u8g2_font_ptr.h"
