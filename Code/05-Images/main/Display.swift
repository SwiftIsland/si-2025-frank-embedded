class Display {
	enum Orientation {
		case landscape
		case portraitRight
		case portraitLeft
		case landscape180
		case landscapeMirrored
		case portraitMirrored
	}
	
	private var u8g2: UnsafeMutablePointer<u8g2_t>
	private var u8g2Callbacks: UnsafeMutablePointer<u8g2_cb_t>
	private var dirtyRect = Rect.zero

	let displaySize: Size
	
	init(sdaPin: Int, sclPin: Int, i2cAddress: UInt8 = 0x78, orientation: Orientation = .landscape) {
		// Initialize HAL
		var halParam = u8g2_esp32_hal_t() // U8G2_ESP32_HAL_DEFAULT
		halParam.bus.i2c.sda = gpio_num_t(Int32(sdaPin))
		halParam.bus.i2c.scl = gpio_num_t(Int32(sclPin))
		halParam.reset = GPIO_NUM_NC // U8G2_ESP32_HAL_UNDEFINED
		halParam.dc = GPIO_NUM_NC // U8G2_ESP32_HAL_UNDEFINED
		u8g2_esp32_hal_init(halParam)

		// Initialize display
		u8g2 = UnsafeMutablePointer<u8g2_t>.allocate(capacity: 1)
		u8g2Callbacks = UnsafeMutablePointer<u8g2_cb_t>.allocate(capacity: 1)
		u8g2Callbacks.pointee = u8g2_cb_r0
		u8g2_Setup_ssd1306_i2c_128x32_univision_f(u8g2, u8g2Callbacks, u8g2_esp32_i2c_byte_cb, u8g2_esp32_gpio_and_delay_cb)

		u8g2.withMemoryRebound(to: u8x8_t.self, capacity: 1) { u8x8 in
			u8x8.pointee.i2c_address = i2cAddress
			u8x8_InitDisplay(u8x8)
		}
		u8g2_ClearBuffer(u8g2)
		u8g2_SendBuffer(u8g2)
		u8g2.withMemoryRebound(to: u8x8_t.self, capacity: 1) { u8x8 in
			u8x8_SetPowerSave(u8x8, 0)
		}

		// Retrieve display characteristics
		displaySize = Size(width: u8g2.pointee.width, height: u8g2.pointee.height)
	}

	func clear() {
		u8g2_ClearBuffer(u8g2)
	}

	func refreshAll() {
		u8g2_SendBuffer(u8g2)
		dirtyRect = .zero
	}

	func refresh() {
		dirtyRect.intersect(Rect(origin: .zero, size: displaySize))
		let tx = UInt8(dirtyRect.minX / 8)
		let ty = UInt8(dirtyRect.minY / 8)
		let txMax = UInt8((dirtyRect.maxX + 7) / 8)
		let tyMax = UInt8((dirtyRect.maxY + 7) / 8)
		let tw = txMax - tx
		let th = tyMax - ty
		u8g2_UpdateDisplayArea(u8g2, tx, ty, tw, th)
		dirtyRect = .zero
	}

	func frameRect(_ rect: Rect, color: Color = .white, refresh: Bool = false) {
        guard !rect.isEmpty else { return }
		dirtyRect.union(rect)
		u8g2_SetDrawColor(u8g2, color.rawValue)
		u8g2_DrawFrame(u8g2, rect.origin.x.u8g2, rect.origin.y.u8g2, rect.size.width.u8g2, rect.size.height.u8g2)
		if refresh {
			self.refresh()
		}
	}

	func fillRect(_ rect: Rect, color: Color = .white, refresh: Bool = false) {
        guard !rect.isEmpty else { return }
		dirtyRect.union(rect)
		u8g2_SetDrawColor(u8g2, color.rawValue)
		u8g2_DrawBox(u8g2, rect.origin.x.u8g2, rect.origin.y.u8g2, rect.size.width.u8g2, rect.size.height.u8g2)
		if refresh {
			self.refresh()
		}
	}

	func frameCircle(center: Point, radius: Unit, color: Color = .white, refresh: Bool = false) {
		dirtyRect.union(Rect(x: center.x.value - radius.value, y: center.y.value - radius.value, width: radius.value * 2 + 1, height: radius.value * 2 + 1))
		u8g2_SetDrawColor(u8g2, color.rawValue)
		u8g2_DrawCircle(u8g2, center.x.u8g2, center.y.u8g2, radius.u8g2, 0xf)
		if refresh {
			self.refresh()
		}
	}

	func fillCircle(center: Point, radius: Unit, color: Color = .white, refresh: Bool = false) {
		dirtyRect.union(Rect(x: center.x.value - radius.value, y: center.y.value - radius.value, width: radius.value * 2 + 1, height: radius.value * 2 + 1))
		u8g2_SetDrawColor(u8g2, color.rawValue)
		u8g2_DrawDisc(u8g2, center.x.u8g2, center.y.u8g2, radius.u8g2, 0xf)
		if refresh {
			self.refresh()
		}
	}

	func fillCircle(_ rect: Rect, color: Color = .white, refresh: Bool = false) {
        guard !rect.isEmpty else { return }
		dirtyRect.union(rect)
		let radius = Unit((min(rect.size.width.value, rect.size.height.value) - 1) / 2)
		let centerX = rect.minX + (rect.size.width.value - 1) / 2
		let centerY = rect.minY + (rect.size.height.value - 1) / 2
		let center = Point(x: centerX, y: centerY)
		u8g2_SetDrawColor(u8g2, color.rawValue)
		u8g2_DrawDisc(u8g2, center.x.u8g2, center.y.u8g2, radius.u8g2, 0xf)
		if refresh {
			self.refresh()
		}
	}

	func drawStr(_ str: String, at point: Point, font: UnsafePointer<UInt8> = u8g2_font_ptr_helvR12_tf, color: Color = .white, erase: Bool = true, refresh: Bool = false) {
		// u8g2_SetDrawColor(pointer, color.rawValue)
        u8g2_SetFont(u8g2, font)
        u8g2_SetFontMode(u8g2, erase ? 0 : 1)
        let ascent = u8g2.pointee.font_ref_ascent
        let descent = u8g2.pointee.font_ref_descent
		str.withCString { cstr in
            let width = u8g2_GetUTF8Width(u8g2, cstr)
   			let rect = Rect(x: point.x.value, y: point.y.value - Int(ascent), width: width, height: ascent - descent)
            dirtyRect.union(rect)
            if erase {
		        u8g2_SetDrawColor(u8g2, color.inversed.rawValue)
		        u8g2_DrawBox(u8g2, rect.origin.x.u8g2, rect.origin.y.u8g2, rect.size.width.u8g2, rect.size.height.u8g2)
            }
   			u8g2_SetDrawColor(u8g2, color.rawValue)
			u8g2_DrawUTF8(u8g2, point.x.u8g2, point.y.u8g2, cstr)
		}
		if refresh {
			self.refresh()
		}
	}

	func drawImage(_ image: TiffImage, at point: Point, subset: Rect? = nil, transparent: Bool = false, inverted: Bool = false, refresh: Bool = false) {
		let rect = Rect(origin: point, size: subset?.size ?? image.imageSize)
		dirtyRect.union(rect)
		u8g2_SetBitmapMode(u8g2, transparent ? 1 : 0)
		image.draw(display: self, at: point, subset: subset, inverted: inverted)
		if refresh {
			self.refresh()
		}
	}

	func drawBitmapRow(at point: Point, length: UInt16, pixels: UnsafePointer<UInt8>) {
		u8g2_DrawHorizontalBitmap(u8g2, point.x.u8g2, point.y.u8g2, length, pixels)
	}
}
