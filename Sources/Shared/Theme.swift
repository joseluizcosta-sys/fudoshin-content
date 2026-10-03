import SwiftUI
import UIKit

/// Cores e espaçamentos do app. Cores se adaptam ao modo escuro.
enum Theme {
    static let background = dynamicColor(light: (0.97, 0.96, 0.94), dark: (0.07, 0.08, 0.09))
    static let primaryText = dynamicColor(light: (0.10, 0.11, 0.12), dark: (0.95, 0.94, 0.92))
    static let secondaryText = dynamicColor(light: (0.35, 0.36, 0.38), dark: (0.68, 0.69, 0.71))
    static let accent = dynamicColor(light: (0.72, 0.30, 0.10), dark: (0.95, 0.55, 0.30))

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    private static func dynamicColor(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat(c.0), green: CGFloat(c.1), blue: CGFloat(c.2), alpha: 1)
        })
    }
}
