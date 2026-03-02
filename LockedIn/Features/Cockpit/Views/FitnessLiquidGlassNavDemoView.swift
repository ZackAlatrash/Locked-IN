import SwiftUI

struct FitnessLiquidGlassNavDemoView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The large title collapses into a pinned navigation title while content scrolls underneath.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("This is native iOS large-title behavior.")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Recent Sessions") {
                    ForEach(1...40, id: \.self) { index in
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Session \(index)")
                                    .font(.body.weight(.semibold))

                                Text("The collapsed title remains fixed at the top")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FitnessLiquidGlassNavDemoView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessLiquidGlassNavDemoView()
    }
}
