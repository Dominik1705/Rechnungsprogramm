import SwiftUI
import SwiftData

enum InvoiceFilter: String, CaseIterable, Identifiable {
    case all = "Alle"
    case draft = "Entwürfe"
    case open = "Offen"
    case overdue = "Überfällig"
    case paid = "Bezahlt"

    var id: Self { self }

    func matches(_ invoice: Invoice) -> Bool {
        switch self {
        case .all: true
        case .draft: invoice.status == .draft
        case .open: invoice.status == .open
        case .overdue: invoice.isOverdue
        case .paid: invoice.status == .paid
        }
    }
}

struct InvoiceListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Invoice.createdAt, order: .reverse) private var invoices: [Invoice]
    @State private var filter: InvoiceFilter = .all
    @State private var searchText = ""
    @State private var path: [Invoice] = []

    private var filtered: [Invoice] {
        invoices.filter { invoice in
            guard filter.matches(invoice) else { return false }
            guard !searchText.isEmpty else { return true }
            return [invoice.number, invoice.recipientName, invoice.subject]
                .contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(filtered) { invoice in
                    NavigationLink(value: invoice) {
                        InvoiceRow(invoice: invoice)
                    }
                    .swipeActions {
                        if invoice.status == .draft {
                            Button(role: .destructive) {
                                context.delete(invoice)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .overlay {
                if filtered.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView("Keine Rechnungen",
                                               systemImage: "doc.text",
                                               description: Text("Tippe auf +, um eine neue Rechnung zu erstellen."))
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Nummer, Kunde, Betreff")
            .navigationTitle(filter == .all ? "Rechnungen" : filter.rawValue)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Filter", selection: $filter) {
                            ForEach(InvoiceFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label("Filter", systemImage: filter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: createInvoice) {
                        Label("Neue Rechnung", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Invoice.self) { InvoiceDetailView(invoice: $0) }
        }
    }

    private func createInvoice() {
        let invoice = Invoice.makeDraft(profile: context.companyProfile())
        context.insert(invoice)
        path.append(invoice)
    }
}
