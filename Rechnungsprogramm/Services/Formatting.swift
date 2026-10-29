import Foundation
import SwiftData
import UIKit

enum Fmt {
    static let locale = Locale(identifier: "de_DE")

    static func money(_ value: Decimal) -> String {
        value.formatted(.currency(code: "EUR").locale(locale))
    }

    static func number(_ value: Decimal) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).locale(locale))
    }

    static func percent(_ value: Decimal) -> String {
        "\(number(value)) %"
    }

    static func date(_ date: Date) -> String {
        date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(locale))
    }
}

extension Decimal {
    /// Kaufmännische Rundung auf zwei Nachkommastellen.
    func roundedToCents() -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, 2, .plain)
        return result
    }
}

extension ModelContext {
    /// Liefert das Firmenprofil und legt es beim ersten Start an.
    func companyProfile() -> CompanyProfile {
        if let existing = try? fetch(FetchDescriptor<CompanyProfile>()).first {
            return existing
        }
        let profile = CompanyProfile()
        insert(profile)
        return profile
    }
}

extension UIImage {
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return self }
        let scale = maxDimension / largest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
