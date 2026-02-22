//
//  ConnectingIndicatorView.swift
//  MouseKit
//
//  Created by Charles Little on 22/02/2026.
//

import SwiftUI

///Connecting Indicator View
struct ConnectingIndicatorView: View {
  var body: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()

      VStack(spacing: 16) {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: .primary))
          .scaleEffect(1.5)

        Text("Connecting...")
          .font(.headline)
          .foregroundColor(.primary)
      }
      .padding(32)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(UIColor.systemBackground))
          .shadow(radius: 10)
      )
    }
  }
}

#Preview("Light Mode") {
  ConnectingIndicatorView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ConnectingIndicatorView()
        .preferredColorScheme(.dark)
}
