struct ESPError: Error {
    let code: esp_err_t

    static func validate(_ rc: esp_err_t) throws(ESPError) {
        guard rc == ESP_OK else { throw ESPError(code: rc) }
    }
}

struct OSError: Error {
    let code: BaseType_t

    static func validate(_ rc: BaseType_t) throws(OSError) {
        guard rc == pdPASS else { throw OSError(code: rc) }
    }
}
