//
//  HIDReader.m
//

#import "HIDReader.h"
#import <IOKit/hidsystem/IOHIDEventSystemClient.h>
#import <IOKit/hidsystem/IOHIDServiceClient.h>

// --- Приватный API IOHID, не объявленный в публичных заголовках. ---
typedef struct __IOHIDEvent *IOHIDEventRef;

#define kIOHIDEventTypeTemperature 15
#define IOHIDEventFieldBase(type)  ((type) << 16)

// Полноценный (не "simple") клиент — именно он отдаёт сервисы по matching на Apple Silicon.
extern IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
extern void IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
extern IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef service, int64_t type,
                                                 int32_t options, int64_t timestamp);
extern double IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

@implementation HIDReader

- (NSArray<NSDictionary<NSString *, id> *> *)readTemperatures {
    NSMutableArray *out = [NSMutableArray array];

    IOHIDEventSystemClientRef client = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    if (!client) { return out; }

    // Фильтр: страница AppleVendor (0xff00), usage температурного сенсора (0x05).
    NSDictionary *match = @{ @"PrimaryUsagePage": @(0xff00),
                             @"PrimaryUsage":     @(0x05) };
    IOHIDEventSystemClientSetMatching(client, (__bridge CFDictionaryRef)match);

    CFArrayRef services = IOHIDEventSystemClientCopyServices(client);
    if (services) {
        CFIndex count = CFArrayGetCount(services);
        int32_t field = (int32_t)IOHIDEventFieldBase(kIOHIDEventTypeTemperature);

        for (CFIndex i = 0; i < count; i++) {
            IOHIDServiceClientRef service =
                (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, i);
            if (!service) { continue; }

            IOHIDEventRef event =
                IOHIDServiceClientCopyEvent(service, kIOHIDEventTypeTemperature, 0, 0);
            if (!event) { continue; }

            double value = IOHIDEventGetFloatValue(event, field);
            CFRelease(event);
            if (value <= 0 || value > 130) { continue; }   // отсекаем мусор

            NSString *name = @"sensor";
            CFTypeRef prop = IOHIDServiceClientCopyProperty(service, CFSTR("Product"));
            if (prop) {
                if (CFGetTypeID(prop) == CFStringGetTypeID()) {
                    name = [(__bridge NSString *)prop copy];
                }
                CFRelease(prop);
            }
            [out addObject:@{ @"name": name, @"value": @(value) }];
        }
        CFRelease(services);
    }

    CFRelease(client);
    return out;
}

@end
