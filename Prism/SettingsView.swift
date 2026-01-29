import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("appsPerPage") private var appsPerPage: Int = 35
    @AppStorage("invertScroll") private var invertScroll: Bool = false
    @AppStorage("IconSizeConstant") private var IconSizeConstant: Double = 0.09936
    @AppStorage("InterItemSpacingConstant") private var InterItemSpacingConstant: Double = 0.0361

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .ignoresSafeArea()
                

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 10)
                }

                Text("Settings")
                    .font(.title2)
                    .bold()
                    .padding(.leading)

                HStack {
                    Text("Apps per page: \(appsPerPage)")
                    Slider(value: Binding(
                        get: { Double(appsPerPage) },
                        set: { appsPerPage = max(7, Int($0 / 7) * 7) }
                    ), in: 7...35, step: 7)
                }
                .padding(.horizontal)

                Picker("App Icon Size", selection: $IconSizeConstant) {
                    Text("Small").tag(0.08)
                    Text("Default").tag(0.09936)
                    Text("Large").tag(0.12)
                    
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Toggle("Invert Scroll Direction", isOn: $invertScroll)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 20)
        }
        .frame(width: 420, height: 300)
    }
}
