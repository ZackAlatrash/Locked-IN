import SwiftUI

/// Shared presentational logs/profile toolbar action cluster.
struct LogsProfileToolbarActions: ToolbarContent {
    let iconColor: Color
    let indicatorColor: Color
    let onLogsTap: () -> Void
    let onProfileTap: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: onLogsTap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 18, weight: .medium))

                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 7, height: 7)
                        .offset(x: 5, y: -3)
                }
                .foregroundColor(iconColor)
            }
            .accessibilityLabel("Open logs")

            Button(action: onProfileTap) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(iconColor)
            }
            .accessibilityLabel("Open profile")
        }
    }
}
