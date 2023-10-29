/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import CryptoKit

let OTP_FORMATTER: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = " "
    formatter.minimumIntegerDigits = 6
    return formatter
}();

func int64ToBytes(value: UInt64) -> [UInt8] {
    var buf = [UInt8](repeating: 0, count: 8)
    buf[0] = (UInt8) ((value >> 56) & 0xff)
    buf[1] = (UInt8) ((value >> 48) & 0xff)
    buf[2] = (UInt8) ((value >> 40) & 0xff)
    buf[3] = (UInt8) ((value >> 32) & 0xff)
    buf[4] = (UInt8) ((value >> 24) & 0xff)
    buf[5] = (UInt8) ((value >> 16) & 0xff)
    buf[6] = (UInt8) ((value >> 8) & 0xff)
    buf[7] = (UInt8) (value & 0xff)
    return buf;
}

func generateGoogleOneTimePassword(key: [UInt8], counter: UInt64) -> UInt32 {
    let key = SymmetricKey(data: key)
    let data = int64ToBytes(value: counter)
    let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: data, using: key)
    let hmacHash = Array(hmac)

    let offset = Int(hmacHash[hmacHash.count - 1] & 0x0f)
    let hotp = UInt32(hmacHash[offset] & 0x7f) << 24
             | UInt32(hmacHash[1 + offset] & 0xff) << 16
             | UInt32(hmacHash[2 + offset] & 0xff) << 8
             | UInt32(hmacHash[3 + offset] & 0xff)
    return UInt32(hotp % 1_000_000);
}

func generateGoogleTimeBasedOneTimePassword(key: [UInt8], timestamp: UInt64) -> UInt32 {
    let interval = UInt64((timestamp / 1000) / 30) // 30sec window
    return generateGoogleOneTimePassword(key: key, counter: interval)
}

func getGoogleTimeBasedOtpRemainingInterval(timestamp: UInt64) -> Double {
    return 1.0 - (Double((timestamp / 1000) % 30) / 30.0) // 30sec window
}

func base32ToUInt8Array(_ base32: String) -> [UInt8]? {
    let base32Chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    // Create a mapping from Base32 characters to their integer values
    var base32Lookup: [Character: UInt8] = [:]
    for (index, char) in base32Chars.enumerated() {
        base32Lookup[char] = UInt8(index)
    }

    var result: [UInt8] = []
    var bits: UInt32 = 0
    var bitsRemaining: UInt8 = 0

    for char in base32.uppercased() {
        guard let value = base32Lookup[char] else {
            print("invalid base32 char", char)
            return nil // Invalid Base32 character
        }

        bits = (bits << 5) | UInt32(value)
        bitsRemaining += 5

        if bitsRemaining >= 8 {
            let shift = bitsRemaining - 8
            let byte = UInt8((bits >> shift) & 0xff)
            result.append(byte)
            bits &= (1 << bitsRemaining) - 1
            bitsRemaining -= 8
        }
    }

    if bitsRemaining >= 5 {
        print("incomplete encoding", bitsRemaining)
        return nil // Incomplete Base32 encoding
    }

    return result
}

func parseOtpAuthUrl(otpAuthUrl: String) -> OtpItem? {
    guard let url = URL(string: otpAuthUrl) else {
        return nil;
    }

    guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems else {
        return nil;
    }

    if url.host() != "totp" {
        print("invalid OTP type", url.host() ?? "-")
        return nil;
    }

    let name = String(url.path(percentEncoded: false).dropFirst())
    var issuer: String = "";
    var secret: [UInt8]?;

    for item in queryItems {
        guard let value = item.value else {
            continue;
        }

        switch item.name {
            case "secret":
                secret = base32ToUInt8Array(value)
            case "issuer":
                issuer = value;
            default:
                print("unknown otp field", item.name, value)
        }
    }

    guard secret != nil && ((secret?.isEmpty) != nil) else {
        print("missing secret", otpAuthUrl)
        return nil;
    }

    return OtpItem(name: name, key: secret!, issuer: issuer)
}
