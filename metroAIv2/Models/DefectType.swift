import Foundation

/// Individual defect within a category
struct Defect: Codable, Identifiable, Hashable {
    let id: String
    let name: String
}

/// A category of defects (e.g. "seats", "walls")
struct DefectCategory: Codable, Hashable {
    let name: String
    let defects: [Defect]
}

/// Wrapper for the defect types response: a dictionary keyed by category slug.
/// API returns: `{ "seats": { "name": "...", "defects": [...] }, ... }`
struct DefectTypesData: Codable, Hashable {
    let categories: [String: DefectCategory]

    init(categories: [String: DefectCategory]) {
        self.categories = categories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.categories = try container.decode([String: DefectCategory].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(categories)
    }

    /// Flat list of all defects across all categories
    var allDefects: [Defect] {
        categories.values.flatMap(\.defects)
    }

    /// Find a defect by its UUID string
    func defect(byId id: String) -> Defect? {
        for category in categories.values {
            if let defect = category.defects.first(where: { $0.id == id }) {
                return defect
            }
        }
        return nil
    }
}

/// Legacy typealias for backward compatibility
typealias DefectType = Defect
