import Foundation

enum InvoiceStatus: String, CaseIterable, Identifiable {
    case draft, open, paid, cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft: "Entwurf"
        case .open: "Offen"
        case .paid: "Bezahlt"
        case .cancelled: "Storniert"
        }
    }
}

/// Art der Position. Arbeitslohn und Anfahrt zählen als Lohnkosten im Sinne von § 35a EStG.
enum ItemKind: String, CaseIterable, Identifiable {
    case labor, travel, material, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .labor: "Arbeitslohn"
        case .travel: "Anfahrt"
        case .material: "Material"
        case .other: "Sonstiges"
        }
    }

    var icon: String {
        switch self {
        case .labor: "wrench.and.screwdriver"
        case .travel: "car"
        case .material: "shippingbox"
        case .other: "ellipsis.circle"
        }
    }

    var defaultUnit: String {
        switch self {
        case .labor: "Std."
        case .travel: "pauschal"
        case .material, .other: "Stk."
        }
    }

    var countsAsLaborCost: Bool { self == .labor || self == .travel }
}

enum VatRate {
    static let options: [Decimal] = [19, 7, 0]
}

enum Units {
    static let common = ["Stk.", "Std.", "m", "m²", "pauschal", "km", "Satz", "Pkg."]
}
