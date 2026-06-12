import SwiftUI

/// MenuScore's "tournament vibrant" brand: a hot red → purple → teal
/// gradient and chunky rounded type for scores and the wordmark.
enum Brand {
    static let red = Color(red: 1.00, green: 0.22, blue: 0.37)
    static let purple = Color(red: 0.54, green: 0.25, blue: 0.99)
    static let teal = Color(red: 0.00, green: 0.78, blue: 0.75)

    static let gradient = LinearGradient(
        colors: [red, purple, teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Chunky display type used for the wordmark and scores.
    static func displayFont(size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
}
