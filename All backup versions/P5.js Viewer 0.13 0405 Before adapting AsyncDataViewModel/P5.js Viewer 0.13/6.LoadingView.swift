//
//  0-6LoadingView.swift
//  P5.js Viewer 0.13
//
//  Created by Jiaqi Yi on 3/28/24.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
            ProgressView("Loading...")
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .frame(width: 100, height: 100)
                .background(Color.gray.opacity(0.8))
                .cornerRadius(10)
        }
    }
}

#Preview {
    LoadingView()
}
