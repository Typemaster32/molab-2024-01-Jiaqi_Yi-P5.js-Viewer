import SwiftUI

struct SettingsView: View {
    @State private var toggleSetting: Bool = false
    @State private var chosenProportion: String = " "
    @State private var settingsProportions: [String] = ["1:1","4:3","16:9","Fit My Screen"]
    @State private var editableText: String = " "
    
    var body: some View {
        NavigationView {
            Form {
                // Editable Text Setting
                
//                HStack {
//                    Text("Your p5 Web Editor ID:")
//                    Spacer()
//                    TextField(" ", text: $editableText, prompt: Text("Placeholder").foregroundColor(.gray))
//                        .frame(width:120, alignment: .trailing) // Adjust width as needed
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .multilineTextAlignment(.trailing)
//                }
                
                // Toggle Setting
                Toggle(isOn: $toggleSetting) {
                    Text("Prohibit draw()")
                }
                
                // Pop-up Menu (Picker) Setting
                Picker("Sketch Preview Proportion", selection: $chosenProportion) {
                    ForEach(settingsProportions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
                // Button Setting
                Button("Clear My Collection") {
                    buttonAction()
                }.foregroundColor(.black)
                
                Button("About P5 Viewer") {
                    buttonAction()
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    func buttonAction() {
        let fileManager = FileManager.default
        
        // Path to the Collections directory
        guard let collectionsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Collections") else {
            print("Failed to locate Collections directory.")
            return
        }
        
        // Path to collectionlist.json within the Collections directory
        let collectionListURL = collectionsURL.appendingPathComponent("collectionlist.json")
        
        // Delete everything in "Collections"
        do {
            let filePaths = try fileManager.contentsOfDirectory(at: collectionsURL, includingPropertiesForKeys: nil, options: [])
            for filePath in filePaths {
                try fileManager.removeItem(at: filePath)
            }
            print("Successfully cleared Collections directory.")
        } catch {
            print("Error clearing Collections directory: \(error)")
        }
        
        // Clear everything in collectionlist.json by overwriting it with an empty array
        do {
            let emptyArray = [ElementModel]() // Assuming ElementModel is your model structure
            let data = try JSONEncoder().encode(emptyArray)
            try data.write(to: collectionListURL, options: [.atomicWrite])
            print("Successfully cleared collectionlist.json.")
        } catch {
            print("Error resetting collectionlist.json: \(error)")
        }
        
        print("Button was tapped")
    }

}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
