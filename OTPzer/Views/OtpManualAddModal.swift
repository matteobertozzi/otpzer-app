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

struct OtpManualAddModal: View {
    @Environment(\.modelContext) private var modelContext;
    @Binding var visible: Bool;
    
    @State private var name: String = "";
    @State private var issuer: String = "";
    @State private var secret: String = "";
    @State private var notes: String = "";
    @State private var isSecretValid: Bool = true;
    
    var body: some View {
        NavigationStack {
            Section {
                Form {
                    TextField(text: $name, prompt: Text("Name")) {
                        Text("Name")
                    }.disableAutocorrection(true)
                    TextField(text: $secret, prompt: Text("Secret")) {
                        Text("Secret")
                    }
                    .disableAutocorrection(true)
                    .onChange(of: secret) { oldValue, newValue in
                        print("new value", oldValue, newValue)
                        validateSecret(value: newValue)
                    }
                    TextField(text: $issuer, prompt: Text("Issuer")) {
                        Text("Issuer")
                    }.disableAutocorrection(true)
                    TextEditor(text: $notes)
                        .padding(5)
                        .background(Color.primary.colorInvert())
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.black, lineWidth: 1 / 3)
                                .opacity(0.3)
                        )
                }.padding(.bottom)
                if !self.isSecretValid {
                    Text("Secret is Not Valid")
                        .font(.callout)
                        .foregroundColor(Color.red)
                }
            }
            Section {
                HStack {
                    Spacer()
                    Button("Save") {
                        let otp = OtpItem(name: name, key: base32ToUInt8Array(secret)!, issuer: issuer, notes: notes)
                        self.modelContext.insert(otp)
                        self.visible = false
                    }.disabled(name.isEmpty || secret.isEmpty)
                    Button("Cancel") {
                        self.visible = false
                    }
                }
            }
        }
        .navigationTitle("Enter Account details")
        .frame(minWidth: 400, minHeight: 350)
        .padding()
    }
    
    func validateSecret(value: String) -> Void {
        guard base32ToUInt8Array(value) != nil else {
            self.isSecretValid = false;
            return
        }
        self.isSecretValid = true;
    }
}

#Preview {
    OtpManualAddModal(visible: .constant(true))
}
