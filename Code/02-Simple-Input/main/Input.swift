struct Input {
    private let pin: gpio_num_t

    init(gpioPin: Int) {
        pin = gpio_num_t(Int32(gpioPin))

        guard gpio_reset_pin(pin) == ESP_OK else {
            fatalError("cannot reset input pin")
        }
        guard gpio_set_direction(pin, GPIO_MODE_INPUT) == ESP_OK else {
            fatalError("cannot set direction")
        }
    }

    var state: Bool {
        gpio_get_level(pin) != 0
    }
}
