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

struct Arc: Shape {
  let startAngle: Angle
  let endAngle: Angle
  let clockwise: Bool
  let lineWidth: Double

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let radius = (max(rect.size.width, rect.size.height) / 2) - (lineWidth / 2)
    path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: clockwise)
    return path
  }
}

struct OtpTimeView: View {
    let progress: Double
    
    var body: some View {
        ZStack(alignment: .center) {
            Arc(startAngle: .degrees(-90), endAngle: .degrees(-90 + (progress * 360)), clockwise: false, lineWidth: 8)
                .stroke(Color.blue, lineWidth: 8)
                .frame(width: 25, height: 25)
        }
    }
}

#Preview {
    OtpTimeView(progress: 0.7)
        .frame(width: 100, height: 100)
}
