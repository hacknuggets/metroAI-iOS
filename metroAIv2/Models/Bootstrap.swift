import Foundation

/// Bootstrap API response
struct BootstrapResponse: Codable {
    let defectTypes: DefectTypesData
    let stations: [Station]
    let lines: [Line]
    
    enum CodingKeys: String, CodingKey {
        case defectTypes = "defect_types"
        case stations
        case lines
    }
}