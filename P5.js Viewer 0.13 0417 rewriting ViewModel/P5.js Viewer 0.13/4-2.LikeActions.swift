//
//  4-2.ButtonActions.swift
//  P5.js Viewer 0.13
//
//  Created by Jiaqi Yi on 4/15/24.
//

import Foundation


/*
Like & Unlike
Like: get the id of this WebContentView -> find it with id -> update with new value of Like
if it is already published, it should have an fbid. This is IMPORTANT, that it is passed through WebContentView.
 */

func UnlikeAction(likesManager: LikesManager , p5id:String, viewModel: ViewModel){
    print("---[Button][Unlike]---")
    likesManager.deleteID(p5id)
    fetchSketch(byFieldName: "p5id", fieldValue: p5id){ item in
        if let item = item {
            var updatedItem = item
            updatedItem.likes -= 1
            viewModel.likesNumber -= 1
            updateSketchInFirestore(item: updatedItem) { success in
                if success {
                    print("[Button][Unlike]:The item was successfully updated in Firestore.")
                } else {
                    print("[Button][Unlike]:Failed to update the item in Firestore.")
                }
            }
        } else {
            print("[Button][Unlike]:Error finding the item")
        }
    }
}

func LikeAction(likesManager: LikesManager , p5id:String, viewModel: ViewModel){
    print("---[Button][Like]---")
    likesManager.addID(p5id)
    fetchSketch(byFieldName: "p5id", fieldValue: p5id){ item in
        if let item = item {
            var updatedItem = item
            updatedItem.likes += 1
            viewModel.likesNumber += 1
            updateSketchInFirestore(item: updatedItem) { success in
                if success {
                    print("[Button][Like]:Succeeded. There're now  \(updatedItem.likes) likes")
                } else {
                    print("\(red)[Button][Like]:Failed to update the item in Firestore.")
                }
            }
        } else {
            print("\(red)[Button][Like]:Error finding the item")
        }
    }
}
