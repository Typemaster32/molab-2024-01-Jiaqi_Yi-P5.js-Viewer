//
//  2-2.SearchViewModel.swift
//  P5.js Viewer 0.13
//
//  Created by Jiaqi Yi on 4/28/24.
//

import Foundation


class SearchViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var searchQuery: String = ""
}
