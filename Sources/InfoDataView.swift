import SwiftUI

// Data model
struct InfoData {
    let maxQuota: Double // Convert maxQuota to Double for calculations
    let remaining: Double
    let user: String
    let ipv4: String
    let ipv6: String
    let status: String
}

// SwiftUI View
struct InfoDataView: View {
    @ObservedObject var fetcher: InfoDataFetcher
    var data: InfoData { fetcher.infoData }

    // Calculated percentage for Remaining vs Max Quota
    var usagePercentage: Double {
        return (data.maxQuota - data.remaining) / data.maxQuota
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title
            Text("User Information")
                .font(.headline)
                .padding(.bottom, 5)

            // User Info
            HStack {
                Text("User:")
                Spacer()
                Text(data.user)
            }
            HStack {
                Text("IPv4:")
                Spacer()
                Text(data.ipv4)
            }
            HStack {
                Text("IPv6:")
                Spacer()
                Text(data.ipv6)
            }
            HStack {
                Text("Status:")
                Spacer()
                Text(data.status)
                    .foregroundColor(data.status == "Already Authenticated" ? .green : .red)
            }

            Divider()

            VStack(alignment: .leading) {
                // Progress Bar (Visual Representation)
                ProgressView(value: usagePercentage) {
                    HStack {
                        Text("Used:")
                        Text(String(format: "%.2f GB", data.maxQuota - data.remaining))
                    }
                } currentValueLabel: {
                    Text("Remaining: \(String(format: "%.2f GB", data.remaining))")
                }
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.bottom, 10)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
