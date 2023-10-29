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

import SwiftUI

struct OtpRowView: View {
    var item: OtpItem
    var timestamp: UInt64
    
    var body: some View {
        let otp = generateGoogleTimeBasedOneTimePassword(key: item.key, timestamp: timestamp)
        let progress = getGoogleTimeBasedOtpRemainingInterval(timestamp: timestamp)
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 16, weight: .bold))
                Text("\(otp as NSNumber, formatter: OTP_FORMATTER)")
                    .foregroundStyle(.blue)
                    .font(.system(size: 32, weight: .bold))
            }
            Spacer()
            OtpTimeView(progress: progress)
        }
    }
}

#Preview {
    OtpRowView(
        item: OtpItem(name: "foo", key: [1, 2, 3, 4]),
        timestamp: UInt64(Date().timeIntervalSinceReferenceDate * 1000)
    )
}
