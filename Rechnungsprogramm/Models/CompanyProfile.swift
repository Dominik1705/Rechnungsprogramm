import Foundation
import SwiftData

/// Firmendaten – es existiert genau ein Datensatz.
@Model
final class CompanyProfile {
    var companyName: String = ""
    var ownerName: String = ""
    var street: String = ""
    var zip: String = ""
    var city: String = ""
    var phone: String = ""
    var email: String = ""
    var website: String = ""

    var taxNumber: String = ""
    var vatID: String = ""
    var registerInfo: String = ""
    var isSmallBusiness: Bool = false
    var defaultVatRate: Decimal = 19

    var bankName: String = ""
    var iban: String = ""
    var bic: String = ""

    var invoicePrefix: String = "RE"
    var nextInvoiceNumber: Int = 1
    var numberYear: Int = 0
    var nextCustomerNumber: Int = 1001
    var defaultDueDays: Int = 14
    var defaultIntroText: String = "Vielen Dank für Ihren Auftrag. Wir erlauben uns, folgende Leistungen in Rechnung zu stellen:"
    var defaultClosingText: String = "Mit freundlichen Grüßen"
    var showRetentionNotice: Bool = true

    @Attribute(.externalStorage) var logoData: Data?

    init() {
        numberYear = Calendar.current.component(.year, from: .now)
    }

    var cityLine: String { [zip, city].filter { !$0.isEmpty }.joined(separator: " ") }

    var isComplete: Bool { !companyName.isEmpty && !street.isEmpty && !city.isEmpty && (!taxNumber.isEmpty || !vatID.isEmpty) }

    /// Vergibt die nächste fortlaufende Rechnungsnummer, z. B. RE-2026-0001. Zähler startet jedes Jahr neu.
    func issueNextInvoiceNumber(for date: Date) -> String {
        let year = Calendar.current.component(.year, from: date)
        if year > numberYear {
            numberYear = year
            nextInvoiceNumber = 1
        }
        let number = formattedNumber(nextInvoiceNumber, year: year)
        nextInvoiceNumber += 1
        return number
    }

    var previewNextInvoiceNumber: String {
        let year = Calendar.current.component(.year, from: .now)
        return formattedNumber(year > numberYear ? 1 : nextInvoiceNumber, year: year)
    }

    func issueNextCustomerNumber() -> String {
        defer { nextCustomerNumber += 1 }
        return String(nextCustomerNumber)
    }

    private func formattedNumber(_ n: Int, year: Int) -> String {
        let prefix = invoicePrefix.trimmingCharacters(in: .whitespaces)
        let counter = String(format: "%04d", n)
        return prefix.isEmpty ? "\(year)-\(counter)" : "\(prefix)-\(year)-\(counter)"
    }
}
