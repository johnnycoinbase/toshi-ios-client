#import "CryptoTools.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation CryptoTools

+ (NSData *)generateSecureRandomData:(NSUInteger)length {
    NSMutableData *d = [NSMutableData dataWithLength:length];
    OSStatus status  = SecRandomCopyBytes(kSecRandomDefault, length, [d mutableBytes]);
    if (status != noErr) {
        exit(-1);
    }

    return [d copy];
}

+ (uint16_t)generateSecureRandomUInt16 {
    return [[self generateSecureRandomData:sizeof(uint16_t)] bigEndianUInt16At:0];
}

+ (uint32_t)generateSecureRandomUInt32 {
    return [[self generateSecureRandomData:sizeof(uint32_t)] bigEndianUInt32At:0];
}

+ (NSString *)computeOtpWithPassword:(NSString *)password andCounter:(int64_t)counter {
    NSData *d = [[@(counter) stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *h = [d hmacWithSha1WithKey:[password dataUsingEncoding:NSUTF8StringEncoding]];

    return [h base64EncodedStringWithOptions:0];
}

+ (NSString *)hashWithSha256:(NSString *)input {
        const char* str = [input UTF8String];
        unsigned char result[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256(str, (CC_LONG)strlen(str), result);
    
        NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
        for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [ret appendFormat:@"%02x",result[i]];
        }
        return ret;
}

@end

@implementation NSData (Conversions)

- (uint8_t)byteAt:(NSUInteger)offset {
    return ((const uint8_t *)[self bytes])[offset];
}

- (uint16_t)bigEndianUInt16At:(NSUInteger)offset {
    return (uint16_t)[self byteAt:1 + offset] | (uint16_t)((uint16_t)[self byteAt:0 + offset] << 8);
}

- (uint32_t)bigEndianUInt32At:(NSUInteger)offset {
    return ((uint32_t)[self byteAt:3 + offset] << 0) | ((uint32_t)[self byteAt:2 + offset] << 8) | ((uint32_t)[self byteAt:1 + offset] << 16) | ((uint32_t)[self byteAt:0 + offset] << 24);
}

+ (NSData *)dataWithBigEndianBytesOfUInt16:(uint16_t)value {
    uint8_t d[sizeof(uint16_t)];
    d[1] = (uint8_t)((value >> 0) & 0xFF);
    d[0] = (uint8_t)((value >> 8) & 0xFF);

    return [NSData dataWithBytes:d length:sizeof(uint16_t)];
}

+ (NSData *)dataWithBigEndianBytesOfUInt32:(uint32_t)value {
    uint8_t d[sizeof(uint32_t)];
    d[3] = (uint8_t)((value >> 0) & 0xFF);
    d[2] = (uint8_t)((value >> 8) & 0xFF);
    d[1] = (uint8_t)((value >> 16) & 0xFF);
    d[0] = (uint8_t)((value >> 24) & 0xFF);

    return [NSData dataWithBytes:d length:sizeof(uint32_t)];
}

+ (NSData *)switchEndiannessOfData:(NSData *)data {
    const void *bytes                 = [data bytes];
    NSMutableData *switchedEndianData = [NSMutableData new];
    for (NSUInteger i = data.length; i > 0; --i) {
        uint8_t byte = *(((uint8_t *)(bytes)) + ((i - 1) * sizeof(uint8_t)));
        [switchedEndianData appendData:[NSData dataWithBytes:&byte length:sizeof(byte)]];
    }

    return switchedEndianData;
}

@end
