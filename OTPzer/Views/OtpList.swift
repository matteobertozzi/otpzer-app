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
import SwiftData
import AVFoundation

struct OtpList: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \OtpItem.name) private var items: [OtpItem]
    
    @State var addItemPresented = false;
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let timestamp = UInt64(timeline.date.timeIntervalSince1970 * 1000)
            
            List(items) { item in
                NavigationLink {
                    OtpRowDetailView(item: item)
                } label: {
                    OtpRowView(item: item, timestamp: timestamp)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: scanQrCode) {
                    Label("Scan QRCode", systemImage: "qrcode.viewfinder")
                }
                Button(action: { addItemPresented = true }) {
                    Label("Add Item", systemImage: "plus.square")
                }.sheet(isPresented: $addItemPresented) {
                    OtpManualAddModal(visible: $addItemPresented)
                        .scaledToFit()
                }
            }
        }
    }
    
    private func scanQrCode() {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select File"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [UTType.image];
        openPanel.begin { result -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let selectedUrl = openPanel.url else {
                    print("nothing selcted")
                    return
                }
                print(selectedUrl)
                let image = CIImage(contentsOf: selectedUrl)
                print(selectedUrl)
                extractQRCodeText(from: image!)
            }
        }
    }
    
    private func extractQRCodeText(from ciImage: CIImage) {
        let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        guard let features = qrDetector?.features(in: ciImage) else {
            return;
        }
        
        for feature in features {
            if let qrCodeFeature = feature as? CIQRCodeFeature {
                if let otpAuthUrl = qrCodeFeature.messageString {
                    print("OTP Auth URL: \(otpAuthUrl)")
                    if let item = parseOtpAuthUrl(otpAuthUrl: otpAuthUrl) {
                        modelContext.insert(item)
                    }
                }
            }
        }
    }
}

#Preview {
    OtpList()
}
