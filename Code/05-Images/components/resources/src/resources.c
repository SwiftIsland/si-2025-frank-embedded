#include "resources.h"

extern const unsigned char swift_logo_white_start[] asm("_binary_Swift_logo_white_tiff_start");
extern const unsigned char swift_logo_white_end[] asm("_binary_Swift_logo_white_tiff_end");
extern const unsigned char swift_island_logo_start[] asm("_binary_Swift_Island_logo_tiff_start");
extern const unsigned char swift_island_logo_end[] asm("_binary_Swift_Island_logo_tiff_end");

uint8_t *swiftLogoPtr(void) {
    return (uint8_t *)swift_logo_white_start;
}

size_t swiftLogoSize(void) {
    return swift_logo_white_end - swift_logo_white_start;
}

uint8_t *swiftIslandLogoPtr(void) {
    return (uint8_t *)swift_island_logo_start;
}

size_t swiftIslandLogoSize(void) {
    return swift_island_logo_end - swift_island_logo_start;
}
