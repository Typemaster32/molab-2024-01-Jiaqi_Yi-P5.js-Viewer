//
//  4-3.ViewModel.swift
//  P5.js Viewer 0.13
//
//  Created by Jiaqi Yi on 4/17/24.
//

import Foundation


class ViewModelOfFirebaseStatus: ObservableObject {//This is an updater of isPublished
    @Published var isPublished = false
    @Published var isLoading = false
    @Published var likesNumber: Int = 0
    private var p5id: String
    
    init(p5id: String) {
        self.p5id = p5id
        print("[ViewModel][init]: Initialized with p5id: \(p5id)")
    }
    
    func checkPublishStatusAndLikes() async {
        print("[ViewModel][checkPublishStatusAndLikes]: Checking publish status and likes started for p5id: \(p5id).")
        
        DispatchQueue.main.async {
            self.isLoading = true
            print("[ViewModel][checkPublishStatusAndLikes]: isLoading set to true.")
        }
        
        if let item = await fetchSketchAsync(byFieldName: "p5id", fieldValue: p5id) {
            DispatchQueue.main.async {
                self.isPublished = true
                self.likesNumber = item.likes
                self.isLoading = false
                print("[ViewModel][checkPublishStatusAndLikes]: Fetch successful. Publish status set to true, likes updated to \(item.likes), isLoading set to false.")
            }
        } else {
            DispatchQueue.main.async {
                self.isPublished = false
                self.isLoading = false
                print("[ViewModel][checkPublishStatusAndLikes]: Fetch failed. No item found for p5id: \(self.p5id). Publish status set to false, isLoading set to false.")
            }
        }
    }
}
