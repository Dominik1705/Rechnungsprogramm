import SwiftUI
import SwiftData

@main
struct RechnungsprogrammApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            CompanyProfile.self,
            Customer.self,
            Invoice.self,
            InvoiceItem.self,
            CatalogItem.self
        ])
    }
}
