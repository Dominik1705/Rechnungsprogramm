import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Invoice.createdAt, order: .reverse) private var invoices: [Invoice]

    private var open: [Invoice] { invoices.filter { $0.status == .open } }
    private var overdue: [Invoice] { open.filter(\.isOverdue) }

    private func paidNet(_ component: Calendar.Component) -> Decimal {
        invoices
            .filter { $0.status == .paid }
            .filter { Calendar.current.isDate($0.paidDate ?? $0.issueDate, equalTo: .now, toGranularity: component) }
            .reduce(0) { $0 + $1.totals.net }
    }

    private func sum(_ list: [Invoice]) -> Decimal { list.reduce(0) { $0 + $1.totals.gross } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Offen", value: Fmt.money(sum(open)),
                                 subtitle: "\(open.count) Rechnung(en)", icon: "clock", color: .orange)
                        StatCard(title: "Überfällig", value: Fmt.money(sum(overdue)),
                                 subtitle: "\(overdue.count) Rechnung(en)", icon: "exclamationmark.triangle", color: .red)
                        StatCard(title: "Umsatz Monat", value: Fmt.money(paidNet(.month)),
                                 subtitle: "netto, bezahlt", icon: "calendar", color: .blue)
                        StatCard(title: "Umsatz Jahr", value: Fmt.money(paidNet(.year)),
                                 subtitle: "netto, bezahlt", icon: "chart.line.uptrend.xyaxis", color: .green)
                    }

                    if !overdue.isEmpty {
                        invoiceSection("Überfällig – nachhaken", overdue)
                    }

                    if invoices.isEmpty {
                        ContentUnavailableView("Willkommen",
                                               systemImage: "bolt.fill",
                                               description: Text("Hinterlege zuerst deine Firmendaten unter Einstellungen, dann kannst du im Tab Rechnungen loslegen."))
                    } else {
                        invoiceSection("Zuletzt erstellt", Array(invoices.prefix(5)))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Übersicht")
            .navigationDestination(for: Invoice.self) { InvoiceDetailView(invoice: $0) }
        }
    }

    private func invoiceSection(_ title: String, _ list: [Invoice]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            VStack(spacing: 0) {
                ForEach(list) { invoice in
                    NavigationLink(value: invoice) {
                        InvoiceRow(invoice: invoice)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    if invoice.id != list.last?.id { Divider().padding(.leading) }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
