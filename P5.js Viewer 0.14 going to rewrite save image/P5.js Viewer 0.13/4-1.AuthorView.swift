//
//  4-1.PageElements.swift
//  P5.js Viewer 0.13
//
//  Created by Jiaqi Yi on 4/15/24.
//

import SwiftUI

struct AuthorView: View {
    @EnvironmentObject var viewModelSearch: SearchViewModel
    var author:String
    var body: some View {
        Button(action: {
                // Define what should happen when the button is clicked
            viewModelSearch.searchQuery = author
            viewModelSearch.selectedTab = 1
            print("HStack clicked!")
        }) {
            HStack(spacing: 3) { // Title + author
                Text(author)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 1)
                
                Image(systemName: "arrow.up.forward.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 14)
            }.padding(.bottom,7)
        }
    }
}
