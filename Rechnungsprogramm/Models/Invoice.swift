import Foundation
import SwiftData

@Model
final class Invoice {
    var number: String = ""
    var documentTitle: String = "Rechnung"
    var referenceNumber: String = ""
    var issueDate: Date = Date()
    var serviceDate: Date = Date()
    var serviceEndDate: Date?
    var dueDays: Int = 14
    var statusRaw: String = InvoiceStatus.draft.rawValue
    var paidDate: Date?
    var subject: String = ""
    var introText: String = ""
    var closingText: String = ""
    var isSmallBusiness: Bool = false
    var createdAt: Date = Date()

    // Beim Abschließen eingefrorene Empfängerdaten (GoBD: Rechnung darf sich nachträglich nicht ändern)
    var recipientSnapshot: String = ""
    var customerNumberSnapshot: String = ""
    var recipientIsBusinessSnapshot: Bool = false

    var customer: Customer?

    @Relationship(deleteRule: .cascade, inverse: \InvoiceItem.invoice)
    var items: [InvoiceItem]? = []

    init() {}

    static func makeDraft(profile: CompanyProfile) -> Invoice {
        let invoice = Invoice()
        invoice.dueDays = profile.defaultDueDays
        invoice.introText = profile.defaultIntroText
        invoice.closingText = profile.defaultClosingText
        invoice.isSmallBusiness = profile.isSmallBusiness
        return invoice
    }

    // MARK: Status

    var status: InvoiceStatus {
        get { InvoiceStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var isLocked: Bool { status != .draft }

    var dueDate: Date { Calendar.current.date(byAdding: .day, value: dueDays, to: issueDate) ?? issueDate }

    var isOverdue: Bool { status == .open && Calendar.current.startOfDay(for: .now) > Calendar.current.startOfDay(for: dueDate) }

    var displayNumber: String { number.isEmpty ? "Entwurf" : number }

    var sortedItems: [InvoiceItem] { (items ?? []).sorted { $0.position < $1.position } }

    // MARK: Empfänger

    var recipientLines: [String] {
        if isLocked && !recipientSnapshot.isEmpty {
            return recipientSnapshot.components(separatedBy: "\n")
        }
        return customer?.addressLines ?? []
    }

    var recipientName: String { recipientLines.first ?? "Kein Kunde" }

    var recipientIsBusiness: Bool { isLocked ? recipientIsBusinessSnapshot : (customer?.isBusiness ?? false) }

    var customerNumber: String { isLocked ? customerNumberSnapshot : (customer?.customerNumber ?? "") }

    // MARK: Abschließen

    /// Probleme, die vor dem Abschließen behoben werden müssen (Pflichtangaben nach § 14 Abs. 4 UStG).
    func finalizeProblems(profile: CompanyProfile) -> [String] {
        var problems: [String] = []
        if customer == nil { problems.append("Kein Kunde ausgewählt.") }
        if (items ?? []).isEmpty { problems.append("Keine Positionen vorhanden.") }
        if profile.companyName.isEmpty || profile.street.isEmpty || profile.city.isEmpty {
            problems.append("Firmenname und Anschrift in den Einstellungen fehlen.")
        }
        if profile.taxNumber.isEmpty && profile.vatID.isEmpty {
            problems.append("Steuernummer oder USt-IdNr. in den Einstellungen fehlt.")
        }
        return problems
    }

    func finalize(profile: CompanyProfile) {
        number = profile.issueNextInvoiceNumber(for: issueDate)
        isSmallBusiness = profile.isSmallBusiness
        recipientSnapshot = (customer?.addressLines ?? []).joined(separator: "\n")
        customerNumberSnapshot = customer?.customerNumber ?? ""
        recipientIsBusinessSnapshot = customer?.isBusiness ?? false
        status = .open
    }

    /// Erstellt einen neuen Entwurf als Kopie. Bei `asCancellation` werden die Mengen negiert (Stornorechnung).
    func duplicate(in context: ModelContext, profile: CompanyProfile, asCancellation: Bool = false) -> Invoice {
        let copy = Invoice.makeDraft(profile: profile)
        copy.customer = customer
        copy.subject = subject
        copy.serviceDate = serviceDate
        copy.serviceEndDate = serviceEndDate
        if asCancellation {
            copy.documentTitle = "Stornorechnung"
            copy.referenceNumber = number
            copy.introText = "Hiermit stornieren wir die Rechnung \(number) vom \(Fmt.date(issueDate)) in voller Höhe."
            copy.closingText = profile.defaultClosingText
            copy.dueDays = 0
        } else {
            copy.introText = introText
            copy.closingText = closingText
            copy.dueDays = dueDays
        }
        context.insert(copy)
        for item in sortedItems {
            let newItem = item.copy()
            if asCancellation { newItem.quantity = -item.quantity }
            context.insert(newItem)
            newItem.invoice = copy
        }
        return copy
    }

    // MARK: Summen

    var totals: InvoiceTotals {
        var result = InvoiceTotals()
        var netByRate: [Decimal: Decimal] = [:]
        var laborByRate: [Decimal: Decimal] = [:]

        for item in items ?? [] {
            let line = item.lineTotal
            result.net += line
            netByRate[item.vatRate, default: 0] += line
            if item.kind.countsAsLaborCost {
                result.laborNet += line
                laborByRate[item.vatRate, default: 0] += line
            }
        }

        if isSmallBusiness {
            result.gross = result.net
        } else {
            result.vatGroups = netByRate.keys.sorted(by: >).map { rate in
                let net = netByRate[rate] ?? 0
                return VatGroup(rate: rate, net: net, vat: (net * rate / 100).roundedToCents())
            }
            result.vat = result.vatGroups.reduce(0) { $0 + $1.vat }
            result.gross = result.net + result.vat
            result.laborVat = laborByRate.reduce(0) { $0 + ($1.value * $1.key / 100).roundedToCents() }
        }
        return result
    }
}

struct VatGroup: Identifiable {
    let rate: Decimal
    let net: Decimal
    let vat: Decimal
    var id: Decimal { rate }
}

struct InvoiceTotals {
    var net: Decimal = 0
    var vatGroups: [VatGroup] = []
    var vat: Decimal = 0
    var gross: Decimal = 0
    var laborNet: Decimal = 0
    var laborVat: Decimal = 0
    var laborGross: Decimal { laborNet + laborVat }
}
