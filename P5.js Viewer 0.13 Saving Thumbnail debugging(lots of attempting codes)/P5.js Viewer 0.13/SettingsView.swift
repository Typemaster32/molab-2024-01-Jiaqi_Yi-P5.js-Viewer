import SwiftUI

struct SettingsView: View {
    @State private var toggleSetting: Bool = false
    @State private var chosenProportion: String = ""
    @State private var settingsProportions: [String] = ["1:1","4:3","16:9","Fit My Screen"]
    @State private var editableText: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Editable Text Setting
                
                HStack {
                    Text("Your p5 Web Editor ID:")
                    Spacer()
                    TextField("", text: $editableText, prompt: Text("Placeholder").foregroundColor(.gray))
                        .frame(width:120, alignment: .trailing) // Adjust width as needed
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                }
                
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
        // Example function called by the Button setting
        print("Button was tapped")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
