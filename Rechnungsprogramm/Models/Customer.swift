import Foundation
import SwiftData

@Model
final class Customer {
    var customerNumber: String = ""
    var name: String = ""
    var contactPerson: String = ""
    var street: String = ""
    var zip: String = ""
    var city: String = ""
    var email: String = ""
    var phone: String = ""
    var isBusiness: Bool = false
    var vatID: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Invoice.customer)
    var invoices: [Invoice]? = []

    init(name: String = "") {
        self.name = name
    }

    var cityLine: String { [zip, city].filter { !$0.isEmpty }.joined(separator: " ") }

    var addressLines: [String] {
        let contact = contactPerson.isEmpty ? "" : (isBusiness ? "z. Hd. \(contactPerson)" : contactPerson)
        return [name, contact, street, cityLine].filter { !$0.isEmpty }
    }

    var displayName: String { name.isEmpty ? "Ohne Namen" : name }
}
