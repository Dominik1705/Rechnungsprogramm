import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Übersicht", systemImage: "chart.bar.xaxis") }
            InvoiceListView()
                .tabItem { Label("Rechnungen", systemImage: "doc.text") }
            CustomerListView()
                .tabItem { Label("Kunden", systemImage: "person.2") }
            SettingsView()
                .tabItem { Label("Einstellungen", systemImage: "gearshape") }
        }
        .task {
            _ = context.companyProfile()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CompanyProfile.self, Customer.self, Invoice.self, InvoiceItem.self, CatalogItem.self], inMemory: true)
}
