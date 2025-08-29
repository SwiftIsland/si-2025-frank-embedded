@_cdecl("app_main")
func main() {
  print("Hello from Swift on ESP32-C6!")

  let gaugeLeft = 12
  let gaugeTop = 7
  let gaugeWidth = 5
  let gaugeHeight = 50

  var counter = 0

  let queue = Queue(count: 10, elements: RotaryController.Direction.self)
  _ = RotaryController(clkPin: 19, dtPin: 20) { direction in
    try? queue.sendFromISR(direction)
  }

  let display = Display(sdaPin: 0, sclPin: 1)
  let rect = Rect(x: gaugeLeft - 3, y: gaugeTop - 3, width: gaugeWidth + 6, height: gaugeHeight + 6)
  display.frameRect(rect, refresh: true)

  while true {
    switch queue.receive() {
    case .clockwise:
      counter = min(counter + 1, gaugeHeight)
    case .counterclockwise:
      counter = max(counter - 1, 0)
    default:
      continue
    }
    let erased = Rect(x: gaugeLeft, y: gaugeTop, width: gaugeWidth, height: gaugeHeight - counter)
    let filled = Rect(x: gaugeLeft, y: gaugeTop + gaugeHeight - counter, width: gaugeWidth, height: counter)
    display.fillRect(erased, color: .black)
    display.fillRect(filled, color: .white, refresh: true)
  }
}
