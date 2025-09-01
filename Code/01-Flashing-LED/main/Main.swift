@_cdecl("app_main")
func main() {
  print("Hello from Swift on ESP32-C6!")

  // 1 tick = 10 milliseconds with the default configuration.
  let onTicks: UInt32 = 10
  let offTicks: UInt32 = 90
  let led = Output(gpioPin: 22)

  while true {
    led.setState(true)
    vTaskDelay(onTicks)
    led.setState(false)
    vTaskDelay(offTicks)
  }
}
