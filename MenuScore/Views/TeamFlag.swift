import SwiftUI

/// A team's flag: ESPN's flag image when available, falling back to the
/// emoji flag (or a soccer ball) while loading or when no image exists.
/// `height` sets the rendered size; width follows the image's aspect.
struct TeamFlag: View {
    let team: Team
    var height: CGFloat = 22

    var body: some View {
        if let url = team.logoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                default:
                    emoji
                }
            }
            .frame(height: height)
        } else {
            emoji
        }
    }

    private var emoji: some View {
        Text(team.flag.isEmpty ? "⚽️" : team.flag)
            .font(.system(size: height))
    }
}
