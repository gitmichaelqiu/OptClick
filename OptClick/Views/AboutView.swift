import SwiftUI

struct AboutView: View {
    var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "OptClick"
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var currentYear: String {
        let year = Calendar.current.component(.year, from: Date())
        return String(year)
    }

    var body: some View {
        VStack(spacing: 12) {
            if let nsImage = NSApplication.shared.applicationIconImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .padding(.bottom, 8)
            }

            Text(appName)
                .font(.largeTitle)
                .bold()

            Text("Version \(appVersion)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 8)

            Text("OptClick lets you simulate right-clicks by pressing the Option (⌥) key or via a customizable hotkey.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Spacer()

            Text("© \(currentYear) Michael Yicheng Qiu. All rights reserved.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
    }
}

