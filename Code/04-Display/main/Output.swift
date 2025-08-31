struct Output {
  private let pin: gpio_num_t

  init(gpioPin: Int) {
    pin = gpio_num_t(Int32(gpioPin))

    guard gpio_reset_pin(pin) == ESP_OK else {
      fatalError("cannot reset output")
    }

    guard gpio_set_direction(pin, GPIO_MODE_OUTPUT) == ESP_OK else {
      fatalError("cannot set direction")
    }
  }

  func setState(_ state: Bool) {
    let value: UInt32 = state ? 1 : 0
    gpio_set_level(pin, value)
  }
}
