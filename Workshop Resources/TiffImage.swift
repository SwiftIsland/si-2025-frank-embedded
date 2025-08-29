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

    func draw(display: Display, at position: Point, subset: Rect? = nil) {
        let subset = subset ?? Rect(origin: .zero, size: imageSize)
        let callbackData = CallbackData(display: display, position: position, length: UInt16(subset.width))
        
        #error("This is not implemented!")
        // TIFF decoding is performed line by line.
        // For each line, the callback (drawCallback) is invoked, and it expects an opaque pointer that will be interpreted as CallbackData.
        // This pointer is taken from pUser in TIFFIMAGE.
        // 
        // 1 - set the pUser property of tiffImage to callbackData
        // 2 - define the decoding parameters with TIFF_setDrawParameters()
        //     (we are dealing with 1bpp images, the last parameter can be nil)
        // 3 - call TIFF_Decode()
        
        display.refreshAll() // This will be removed eventually
    }
}

fileprivate struct CallbackData {
    let display: Display
    let position: Point
    let length: UInt16
}

@_cdecl("drawCallback")
fileprivate func drawCallback(_ draw: UnsafeMutablePointer<TIFFDRAW>?) {
    guard let draw else { return }
    draw.pointee.pUser?.withMemoryRebound(to: CallbackData.self, capacity: 1) { dataPtr in
        dataPtr.pointee.display.drawBitmapRow(at: dataPtr.pointee.position.movedBy(offsetX: 0, offsetY: draw.pointee.y), length: dataPtr.pointee.length, pixels: draw.pointee.pPixels)
    }
}
