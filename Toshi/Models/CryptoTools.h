// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>

/// Handles some of the encryption needs for SignalServiceKit integration.

@interface NSData (Conversions)
- (uint16_t)bigEndianUInt16At:(NSUInteger)offset;
- (uint32_t)bigEndianUInt32At:(NSUInteger)offset;
- (uint8_t)byteAt:(NSUInteger)offset;

+ (NSData *)dataWithBigEndianBytesOfUInt16:(uint16_t)value;
+ (NSData *)dataWithBigEndianBytesOfUInt32:(uint32_t)value;
+ (NSData *)switchEndiannessOfData:(NSData *)data;
@end


@interface CryptoTools : NSObject

/// Returns a secure random 16-bit unsigned integer.
+ (uint16_t)generateSecureRandomUInt16;

/// Returns a secure random 32-bit unsigned integer.
+ (uint32_t)generateSecureRandomUInt32;

/// Returns data composed of 'length' cryptographically unpredictable bytes sampled uniformly from [0, 256).
+ (NSData *)generateSecureRandomData:(NSUInteger)length;

/// Returns the token included as part of HTTP OTP authentication.
+ (NSString *)computeOtpWithPassword:(NSString *)password andCounter:(int64_t)counter;

/// Compute SHA256 hash of the given string.
+ (NSString *)hashWithSha256:(NSString *)input;

@end

@interface NSData (CryptoTools)

- (NSData *)hashWithSha256;

- (NSData *)hmacWithSha1WithKey:(NSData *)key;
- (NSData *)hmacWithSha256WithKey:(NSData *)key;

- (NSData *)encryptWithAesInCipherFeedbackModeWithKey:(NSData *)key andIv:(NSData *)iv;
- (NSData *)decryptWithAesInCipherFeedbackModeWithKey:(NSData *)key andIv:(NSData *)iv;

- (NSData *)encryptWithAesInCipherBlockChainingModeWithPkcs7PaddingWithKey:(NSData *)key andIv:(NSData *)iv;
- (NSData *)decryptWithAesInCipherBlockChainingModeWithPkcs7PaddingWithKey:(NSData *)key andIv:(NSData *)iv;

- (NSData *)encryptWithAesInCounterModeWithKey:(NSData *)key andIv:(NSData *)iv;
- (NSData *)decryptWithAesInCounterModeWithKey:(NSData *)key andIv:(NSData *)iv;

/// Determines if two data vectors contain the same information.
/// Avoids short-circuiting or data-dependent branches, so that early returns can't be used to infer where the
/// difference is.
/// Returns early if data is of different length.
- (bool)isEqualToData_TimingSafe:(NSData *)other;

@end
