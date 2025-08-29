@_cdecl("app_main")
func main() {
  print("Hello from Swift on ESP32-C6!")

  // 1 tick = 10 milliseconds with the default configuration.
  let ticks: UInt32 = 10
  let led = Output(gpioPin: 22)
  let button = Input(gpioPin: 21)

  var ledState = false
  var buttonState = button.state
  var counter = 0

  led.setState(ledState)

  while true {
    if button.state != buttonState {
      buttonState = button.state
      counter += 1
      print("Counter: \(counter)")
      if buttonState == false {
        ledState.toggle()
        led.setState(ledState)
      }
    }
    vTaskDelay(ticks)
  }
}
