// Add to BridgingHeader.h:
// #include "esp_adc/adc_oneshot.h"

struct AnalogInput {
    enum Attenuation: UInt32 {
        case db0 = 0
        case db2_5 = 1
        case db6 = 2
        case db12 = 3
    }

    let bitwidth = ADC_BITWIDTH_DEFAULT

    private static let handle = {
        var h = adc_oneshot_unit_handle_t(bitPattern: 0)
        let unitConfig = adc_oneshot_unit_init_cfg_t(unit_id: ADC_UNIT_1, clk_src: ADC_DIGI_CLK_SRC_DEFAULT, ulp_mode: ADC_ULP_MODE_DISABLE)
        withUnsafePointer(to: unitConfig) { configPtr in
            guard adc_oneshot_new_unit(configPtr, &h) == ESP_OK else {
                fatalError("cannot create analog unit")
            }
        }
        return h
    }()

    private let channel: adc_channel_t

    init(pin: Int, attenuation: Attenuation) {
        guard pin >= ADC_CHANNEL_0.rawValue, pin <= ADC_CHANNEL_9.rawValue else {
            fatalError("unsupported ADC pin")
        }
        channel = adc_channel_t(UInt32(pin))

        let channelConfig = adc_oneshot_chan_cfg_t(atten: adc_atten_t(attenuation.rawValue), bitwidth: bitwidth)
        withUnsafePointer(to: channelConfig) { configPtr in
            guard adc_oneshot_config_channel(Self.handle, channel, configPtr) == ESP_OK else {
                fatalError("cannot configure analog channel")
            }
        }
    }

    var value: Int {
        var raw: Int32 = 0
        adc_oneshot_read(Self.handle, channel, &raw)
        return Int(raw)
    }

    var maxValue: Int {
        let actualBitwidth = bitwidth == ADC_BITWIDTH_DEFAULT ? UInt32(SOC_ADC_RTC_MAX_BITWIDTH) : bitwidth.rawValue
        return 1 << actualBitwidth - 1
    }
}
