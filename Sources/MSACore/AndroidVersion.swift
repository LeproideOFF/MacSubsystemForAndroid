import Foundation

public enum AndroidVersion: Int, CaseIterable, Codable, CustomStringConvertible {
    case android6 = 6
    case android7 = 7
    case android8 = 8
    case android9 = 9
    case android10 = 10
    case android11 = 11
    case android12 = 12
    case android13 = 13
    case android14 = 14
    case android15 = 15
    case android16 = 16
    case android17 = 17

    public var codename: String {
        switch self {
        case .android6: return "Marshmallow (API 23)"
        case .android7: return "Nougat (API 24/25)"
        case .android8: return "Oreo (API 26/27)"
        case .android9: return "Pie (API 28)"
        case .android10: return "Quince Tart / Android 10 (API 29)"
        case .android11: return "Red Velvet Cake / Android 11 (API 30)"
        case .android12: return "Snow Cone / Android 12 (API 31/32)"
        case .android13: return "Tiramisu / Android 13 (API 33)"
        case .android14: return "Upside Down Cake / Android 14 (API 34)"
        case .android15: return "Vanilla Ice Cream / Android 15 (API 35)"
        case .android16: return "Baklava / Android 16 (API 36)"
        case .android17: return "Android 17 (Future Preview)"
        }
    }

    public var isRecommended: Bool {
        return self == .android13 || self == .android14
    }

    public var description: String {
        let tag = isRecommended ? " [Recommandé / Stable]" : ""
        return "Android \(rawValue) - \(codename)\(tag)"
    }
}
