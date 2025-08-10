import SwiftUI

@main
struct AirLinkApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Image(systemName: "wifi")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("AirLink")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Aplikacja działa!")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}
