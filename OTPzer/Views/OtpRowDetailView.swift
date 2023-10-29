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

struct OtpRowDetailView: View {
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.dismiss) private var dismiss;

    @State private var isPresentingDeletionConfirm: Bool = false;
    @State private var isShowingErrorAlert: Bool = false;
    @State private var errorMessage: String = "";
    
    @Bindable var item: OtpItem
    
    var body: some View {
        VStack {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                let timestamp = UInt64(timeline.date.timeIntervalSince1970 * 1000)
                let otp = generateGoogleTimeBasedOneTimePassword(key: item.key, timestamp: timestamp)
                let progress = getGoogleTimeBasedOtpRemainingInterval(timestamp: timestamp)
                HStack {
                    Text("\(otp as NSNumber, formatter: OTP_FORMATTER)")
                        .foregroundStyle(.blue)
                        .font(.system(size: 32, weight: .bold))
                    Spacer()
                    OtpTimeView(progress: progress)
                }
            }
            Section {
                Form {
                    TextField(text: $item.name, prompt: Text("Name")) {
                        Text("Name")
                    }.disableAutocorrection(true)
                    TextField(text: $item.issuer, prompt: Text("Issuer")) {
                        Text("Issuer")
                    }.disableAutocorrection(true)
                    TextEditor(text: $item.notes)
                        .padding(5)
                        .background(Color.primary.colorInvert())
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.black, lineWidth: 1 / 3)
                                .opacity(0.3)
                        )
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { saveIfNecessary() }) {
                    Label("Back", systemImage: "chevron.backward")
                }
            }
            ToolbarItem {
                Button(action: { isPresentingDeletionConfirm = true}) {
                    Label("Delete", systemImage: "trash.square")
                }.confirmationDialog("Are you sure?", isPresented:$isPresentingDeletionConfirm) {
                    Button("Delete OTP Code?", role: .destructive) {
                        do {
                            modelContext.delete(item)
                            try modelContext.save()
                            dismiss();
                        } catch {
                            print("failed to delete", item)
                            errorMessage = error.localizedDescription
                            isShowingErrorAlert = true
                        }
                    }
                } message: {
                  Text("You cannot undo this action")
               }
            }
        }
        .alert(isPresented: $isShowingErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveIfNecessary() {
        if modelContext.hasChanges {
            do {
                try modelContext.save()
                dismiss();
            } catch {
                print("failed to save", item.name)
                errorMessage = error.localizedDescription
                isShowingErrorAlert = true
            }
        } else {
            dismiss()
        }
    }
}

#Preview {
    OtpRowDetailView(
        item: OtpItem(name: "foo", key: [1, 2, 3, 4])
    )
}
