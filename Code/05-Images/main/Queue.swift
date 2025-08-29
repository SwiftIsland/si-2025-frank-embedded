struct Queue<T> {
	private let queue: QueueHandle_t
	
	init(count: some BinaryInteger, elements: T.Type) {
		queue = xQueueGenericCreate(UInt32(count), UInt32(MemoryLayout<T>.size), queueQUEUE_TYPE_BASE)
	}
	
	/// Send an element to the queue.
	///
	/// If the queue is full, this call blocks until ticksToWait has elapsed.
	///
	/// > Warning: This function must not be called from an interrupt handler.
	/// > Use `sendFromISR()` instead.
	///
	/// - Parameters:
	///   - element: the element to post to the queue
	///   - ticksToWait: the duration to wait if the queue is full. If the queue is still full
	///     after this duration, an error is thrown.
	func send(_ element: T, wait ticksToWait: TickType_t = 0) throws(OSError) {
		var element = element // withUnsafePointer takes inout parameter, element must be mutable.
		let rc = withUnsafePointer(to: &element) { pointer in
			xQueueGenericSend(queue, pointer, ticksToWait, queueSEND_TO_BACK)
		}
		try OSError.validate(rc)
	}
		
	/// Send an element to the queue from an interrupt handler.
	///
	/// If the queue is full, this call throws an error.
	///
	/// - Parameters:
	///   - element: the element to post to the queue
	func sendFromISR(_ element: T) throws(OSError) {
		var element = element // withUnsafeMutablePointer takes inout parameter, element must be mutable.
		let rc = withUnsafeMutablePointer(to: &element) { pointer in
			var higherPriorityTaskWoken: BaseType_t = pdFALSE
			let rc = xQueueGenericSendFromISR(queue, pointer, &higherPriorityTaskWoken, queueSEND_TO_BACK)
			if higherPriorityTaskWoken != pdFALSE {
				vPortYieldFromISR()
			}
			return rc
		}
		try OSError.validate(rc)
	}
	
	/// Remove the first element from the queue and return it.
	///
	/// If the queue is empty, this call blocks until ticksToWait has elapsed.
	///
	/// > Warning: This function must not be called from an interrupt handler.
	///
	/// - Parameters:
	///   - ticksToWait: the duration to wait if the queue is empty. If the queue is still empty
	///     after this duration, the function returns nil.
	///
	/// - Returns: the first element, or nil if the queue is empty.
	func receive(wait ticksToWait: TickType_t = portMAX_DELAY) -> T? {
		let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
		defer {
			pointer.deallocate()
		}
		guard xQueueReceive(queue, pointer, ticksToWait) == pdPASS else {
			return nil
		}
		let element = pointer.pointee
		return element
	}
	
	/// Remove all elements from the queue.
	func reset() {
		xQueueGenericReset(queue, pdFALSE)
	}
}
