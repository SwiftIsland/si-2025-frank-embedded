@_cdecl("app_main")
func main() {
  print("Hello from Swift on ESP32-C6!")

  var counter = 0

  let queue = Queue(count: 10, elements: RotaryController.Direction.self)
  _ = RotaryController(clkPin: 19, dtPin: 20) { direction in
    try? queue.sendFromISR(direction)
  }

  while true {
    switch queue.receive() {
    case .clockwise:
      counter += 1
    case .counterclockwise:
      counter -= 1
    default:
      continue
    }
    print(counter)
  }
}
