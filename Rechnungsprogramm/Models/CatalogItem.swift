import Foundation
import SwiftData

/// Wiederkehrende Leistungen und Material (z. B. "Steckdose setzen", "NYM-J 3x1,5").
@Model
final class CatalogItem {
    var title: String = ""
    var details: String = ""
    var unit: String = "Stk."
    var unitPrice: Decimal = 0
    var vatRate: Decimal = 19
    var kindRaw: String = ItemKind.material.rawValue

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

    func makeInvoiceItem() -> InvoiceItem {
        let item = InvoiceItem(title: title, kind: kind, vatRate: vatRate)
        item.details = details
        item.unit = unit
        item.unitPrice = unitPrice
        return item
    }
}
