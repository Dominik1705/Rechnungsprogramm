import Foundation
import SwiftData

@Model
final class InvoiceItem {
    var position: Int = 0
    var title: String = ""
    var details: String = ""
    var quantity: Decimal = 1
    var unit: String = "Stk."
    var unitPrice: Decimal = 0
    var vatRate: Decimal = 19
    var kindRaw: String = ItemKind.material.rawValue
    var invoice: Invoice?

    init(title: String = "", kind: ItemKind = .material, vatRate: Decimal = 19) {
        self.title = title
        self.kindRaw = kind.rawValue
        self.unit = kind.defaultUnit
        self.vatRate = vatRate
    }

    var kind: ItemKind {
        get { ItemKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    /// Netto-Zeilensumme, kaufmännisch auf Cent gerundet.
    var lineTotal: Decimal { (quantity * unitPrice).roundedToCents() }

    func copy() -> InvoiceItem {
        let item = InvoiceItem(title: title, kind: kind, vatRate: vatRate)
        item.position = position
        item.details = details
        item.quantity = quantity
        item.unit = unit
        item.unitPrice = unitPrice
        return item
    }
}
