import Foundation
import SwiftUI

/// Metro line
struct Line: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let hexColor: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case hexColor = "hex_color"
    }
    
    /// SwiftUI Color from hex
    var color: Color {
        Color(hex: hexColor)
    }
}

// Helper extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}