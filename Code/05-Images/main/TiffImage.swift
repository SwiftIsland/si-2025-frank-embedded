struct TiffError: Error {
    let code: Int32
}

struct TiffImage {
    private let tiffImage: UnsafeMutablePointer<TIFFIMAGE>
    let imageSize: Size

    init(pointer: UnsafeMutablePointer<UInt8>, byteCount: Int) throws(TiffError) {
        tiffImage = UnsafeMutablePointer<TIFFIMAGE>.allocate(capacity: 1)
        guard TIFF_openTIFFRAM(tiffImage, pointer, Int32(byteCount), drawCallback) != 0 else {
            throw TiffError(code: tiffImage.pointee.iError)
        }
        imageSize = Size(width: tiffImage.pointee.iWidth, height: tiffImage.pointee.iHeight)
    }

    func draw(display: Display, at position: Point, subset: Rect? = nil, inverted: Bool = false) {
        let subset = subset ?? Rect(origin: .zero, size: imageSize)
        let callbackData = CallbackData(display: display, position: position, length: UInt16(subset.width), inverted: inverted)
        withUnsafePointer(to: callbackData) { ptr in
            tiffImage.pointee.pUser = UnsafeMutableRawPointer(mutating: ptr)
            TIFF_setDrawParameters(tiffImage, 1.0, Int32(TIFF_PIXEL_1BPP), Int32(subset.minX), Int32(subset.minY), Int32(subset.width), Int32(subset.height), nil); // no buffer needed for 1bpp
            TIFF_decode(tiffImage)
        }
    }
}

fileprivate struct CallbackData {
    let display: Display
    let position: Point
    let length: UInt16
    let inverted: Bool
}

@_cdecl("drawCallback")
fileprivate func drawCallback(_ draw: UnsafeMutablePointer<TIFFDRAW>?) {
    guard let draw else { return }
    draw.pointee.pUser?.withMemoryRebound(to: CallbackData.self, capacity: 1) { dataPtr in
        if dataPtr.pointee.inverted {
            let bytes = Int(dataPtr.pointee.length + 7) / 8
            (0..<bytes).forEach { offset in
                (draw.pointee.pPixels + offset).pointee ^= 0xff
            }
        }
        dataPtr.pointee.display.drawBitmapRow(at: dataPtr.pointee.position.movedBy(offsetX: 0, offsetY: draw.pointee.y), length: dataPtr.pointee.length, pixels: draw.pointee.pPixels)
    }
}