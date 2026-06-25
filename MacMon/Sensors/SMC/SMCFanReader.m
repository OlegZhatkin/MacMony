//
//  SMCFanReader.m
//

#import "SMCFanReader.h"
#import <IOKit/IOKitLib.h>

// --- Протокол AppleSMC (классический интерфейс, размер структуры = 80 байт). ---

typedef struct {
    uint8_t  major;
    uint8_t  minor;
    uint8_t  build;
    uint8_t  reserved;
    uint16_t release;
} SMCVersion;

typedef struct {
    uint16_t version;
    uint16_t length;
    uint32_t cpuPLimit;
    uint32_t gpuPLimit;
    uint32_t memPLimit;
} SMCPLimitData;

typedef struct {
    uint32_t dataSize;
    uint32_t dataType;
    uint8_t  dataAttributes;
} SMCKeyInfoData;

typedef struct {
    uint32_t        key;
    SMCVersion      vers;
    SMCPLimitData   pLimitData;
    SMCKeyInfoData  keyInfo;
    uint8_t         result;
    uint8_t         status;
    uint8_t         data8;
    uint32_t        data32;
    uint8_t         bytes[32];
} SMCParamStruct;

enum {
    kSMCHandleYPCEvent  = 2,
    kSMCReadKey         = 5,
    kSMCGetKeyInfo      = 9,
};

@implementation SMCFanReader {
    io_connect_t _conn;
}

static uint32_t fourCC(const char *s) {
    return ((uint32_t)s[0] << 24) | ((uint32_t)s[1] << 16) |
           ((uint32_t)s[2] << 8)  |  (uint32_t)s[3];
}

- (BOOL)open {
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                       IOServiceMatching("AppleSMC"));
    if (!service) { return NO; }
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &_conn);
    IOObjectRelease(service);
    return kr == kIOReturnSuccess;
}

- (void)close {
    if (_conn) { IOServiceClose(_conn); _conn = 0; }
}

- (void)dealloc { [self close]; }

// Низкоуровневый вызов SMC.
- (BOOL)call:(SMCParamStruct *)input output:(SMCParamStruct *)output {
    size_t outSize = sizeof(SMCParamStruct);
    kern_return_t kr = IOConnectCallStructMethod(_conn, kSMCHandleYPCEvent,
                                                 input, sizeof(SMCParamStruct),
                                                 output, &outSize);
    return kr == kIOReturnSuccess && output->result == 0;
}

// Читает ключ как double, декодируя тип данных SMC.
- (BOOL)readKey:(const char *)key value:(double *)out {
    if (!_conn) { return NO; }

    SMCParamStruct in = {0}, info = {0};
    in.key = fourCC(key);
    in.data8 = kSMCGetKeyInfo;
    if (![self call:&in output:&info]) { return NO; }

    uint32_t dataSize = info.keyInfo.dataSize;
    uint32_t dataType = info.keyInfo.dataType;
    if (dataSize == 0) { return NO; }

    SMCParamStruct read = {0}, result = {0};
    read.key = fourCC(key);
    read.keyInfo.dataSize = dataSize;
    read.data8 = kSMCReadKey;
    if (![self call:&read output:&result]) { return NO; }

    const uint8_t *b = result.bytes;
    if (dataType == fourCC("flt ") && dataSize == 4) {
        float f;
        memcpy(&f, b, 4);                 // little-endian IEEE float
        *out = (double)f;
        return YES;
    }
    if (dataType == fourCC("fpe2") && dataSize == 2) {
        *out = (double)(((uint16_t)b[0] << 8) | b[1]) / 4.0;   // big-endian fixed point
        return YES;
    }
    if (dataType == fourCC("ui8 ") || dataSize == 1) { *out = (double)b[0]; return YES; }
    if (dataType == fourCC("ui16") && dataSize >= 2) {
        *out = (double)(((uint16_t)b[0] << 8) | b[1]); return YES;
    }
    if (dataType == fourCC("ui32") && dataSize >= 4) {
        *out = (double)(((uint32_t)b[0] << 24) | ((uint32_t)b[1] << 16) |
                        ((uint32_t)b[2] << 8) | b[3]);
        return YES;
    }
    return NO;
}

- (NSArray<NSDictionary<NSString *, NSNumber *> *> *)readFans {
    NSMutableArray *fans = [NSMutableArray array];

    double countD = 0;
    if (![self readKey:"FNum" value:&countD]) { return fans; }
    int count = (int)countD;
    if (count <= 0 || count >= 16) { return fans; }

    for (int i = 0; i < count; i++) {
        char keyAc[5], keyMn[5], keyMx[5];
        snprintf(keyAc, sizeof(keyAc), "F%dAc", i);
        snprintf(keyMn, sizeof(keyMn), "F%dMn", i);
        snprintf(keyMx, sizeof(keyMx), "F%dMx", i);

        double cur = 0, mn = 0, mx = 0;
        if (![self readKey:keyAc value:&cur]) { continue; }
        [self readKey:keyMn value:&mn];
        [self readKey:keyMx value:&mx];

        [fans addObject:@{ @"current": @((int)lround(cur)),
                           @"min":     @((int)lround(mn)),
                           @"max":     @((int)lround(mx > 0 ? mx : cur)) }];
    }
    return fans;
}

@end
