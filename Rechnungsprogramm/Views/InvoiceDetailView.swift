import SwiftUI
import SwiftData

struct InvoiceDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var invoice: Invoice

    @State private var editingItem: InvoiceItem?
    @State private var showCatalog = false
    @State private var showPreview = false
    @State private var showFinalizeConfirm = false
    @State private var showCancelConfirm = false
    @State private var problems: [String] = []
    @State private var newInvoice: Invoice?

    private var locked: Bool { invoice.isLocked }

    var body: some View {
        Form {
            if locked {
                Section {
                    Label("Abgeschlossene Rechnungen können nicht mehr geändert werden. Für Korrekturen eine Stornorechnung erstellen.",
                          systemImage: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            customerSection
            detailsSection
            itemsSection
            totalsSection

            Section("Texte") {
                TextField("Einleitung", text: $invoice.introText, axis: .vertical)
                    .lineLimit(2...6)
                TextField("Schlusstext", text: $invoice.closingText, axis: .vertical)
                    .lineLimit(1...4)
            }
            .disabled(locked)

            actionsSection
        }
        .navigationTitle(invoice.documentTitle == "Rechnung" ? invoice.displayNumber : "Storno \(invoice.displayNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showPreview = true } label: {
                    Label("PDF", systemImage: "doc.richtext")
                }
            }
        }
        .sheet(item: $editingItem) { item in
            NavigationStack { ItemEditView(item: item, isLocked: locked) }
        }
        .sheet(isPresented: $showCatalog) {
            CatalogPickerView { catalogItem in addItem(catalogItem.makeInvoiceItem(), edit: false) }
        }
        .sheet(isPresented: $showPreview) {
            PDFPreviewView(invoice: invoice, profile: context.companyProfile())
        }
        .navigationDestination(item: $newInvoice) { InvoiceDetailView(invoice: $0) }
        .confirmationDialog("Rechnung abschließen?", isPresented: $showFinalizeConfirm, titleVisibility: .visible) {
            Button("Abschließen & Nummer vergeben", action: finalize)
        } message: {
            Text("Die Rechnung erhält die Nummer \(context.companyProfile().previewNextInvoiceNumber) und kann danach nicht mehr bearbeitet werden.")
        }
        .confirmationDialog("Rechnung stornieren?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("Stornieren & Stornorechnung erstellen", role: .destructive, action: cancelInvoice)
        } message: {
            Text("Die Rechnung wird als storniert markiert und eine Stornorechnung mit negativen Beträgen als Entwurf angelegt.")
        }
        .alert("Rechnung unvollständig", isPresented: Binding(get: { !problems.isEmpty }, set: { if !$0 { problems = [] } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(problems.joined(separator: "\n"))
        }
        .onAppear {
            if !locked { invoice.isSmallBusiness = context.companyProfile().isSmallBusiness }
        }
    }

    // MARK: Abschnitte

    private var customerSection: some View {
        Section("Kunde") {
            NavigationLink {
                CustomerPickerView(selection: $invoice.customer)
            } label: {
                if invoice.recipientLines.isEmpty {
                    Label("Kunde auswählen", systemImage: "person.crop.circle.badge.plus")
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(invoice.recipientName).font(.headline)
                        Text(invoice.recipientLines.dropFirst().joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(locked)
        }
    }

    private var detailsSection: some View {
        Section("Rechnungsdaten") {
            LabeledContent("Nummer", value: invoice.displayNumber)
            LabeledContent("Status") { StatusBadge(invoice: invoice) }
            DatePicker("Rechnungsdatum", selection: $invoice.issueDate, displayedComponents: .date)
                .disabled(locked)
            DatePicker(invoice.serviceEndDate == nil ? "Leistungsdatum" : "Leistung von",
                       selection: $invoice.serviceDate, displayedComponents: .date)
                .disabled(locked)
            Toggle("Leistungszeitraum", isOn: hasServicePeriod)
                .disabled(locked)
            if invoice.serviceEndDate != nil {
                DatePicker("Leistung bis", selection: serviceEndDate, in: invoice.serviceDate..., displayedComponents: .date)
                    .disabled(locked)
            }
            Stepper("Zahlungsziel: \(invoice.dueDays) Tage", value: $invoice.dueDays, in: 0...120)
                .disabled(locked)
            TextField("Betreff / Bauvorhaben", text: $invoice.subject)
                .disabled(locked)
        }
    }

    private var itemsSection: some View {
        Section("Positionen") {
            ForEach(invoice.sortedItems) { item in
                Button { editingItem = item } label: { ItemRow(item: item) }
                    .foregroundStyle(.primary)
            }
            .onDelete(perform: deleteItems)
            .onMove(perform: moveItems)
            .deleteDisabled(locked)
            .moveDisabled(locked)

            if !locked {
                Menu {
                    ForEach(ItemKind.allCases) { kind in
                        Button {
                            addItem(InvoiceItem(kind: kind, vatRate: context.companyProfile().defaultVatRate), edit: true)
                        } label: {
                            Label(kind.title, systemImage: kind.icon)
                        }
                    }
                    Divider()
                    Button { showCatalog = true } label: {
                        Label("Aus Katalog", systemImage: "books.vertical")
                    }
                } label: {
                    Label("Position hinzufügen", systemImage: "plus.circle.fill")
                }
            }
        }
    }

    private var totalsSection: some View {
        let totals = invoice.totals
        return Section("Summen") {
            if invoice.isSmallBusiness {
                LabeledContent("Gesamtbetrag", value: Fmt.money(totals.gross)).bold()
                Text("Kleinunternehmer – keine USt. (§ 19 UStG)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LabeledContent("Netto", value: Fmt.money(totals.net))
                ForEach(totals.vatGroups) { group in
                    LabeledContent("USt. \(Fmt.percent(group.rate))", value: Fmt.money(group.vat))
                }
                LabeledContent("Brutto", value: Fmt.money(totals.gross)).bold()
            }
            if totals.laborNet != 0 {
                LabeledContent("davon Lohn/Anfahrt (§ 35a)", value: Fmt.money(totals.laborGross))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .monospacedDigit()
    }

    @ViewBuilder
    private var actionsSection: some View {
        Section {
            switch invoice.status {
            case .draft:
                Button {
                    problems = invoice.finalizeProblems(profile: context.companyProfile())
                    if problems.isEmpty { showFinalizeConfirm = true }
                } label: {
                    Label("Rechnung abschließen", systemImage: "checkmark.seal")
                }
            case .open:
                Button {
                    invoice.status = .paid
                    invoice.paidDate = .now
                } label: {
                    Label("Als bezahlt markieren", systemImage: "eurosign.circle")
                }
                Button(role: .destructive) { showCancelConfirm = true } label: {
                    Label("Stornieren", systemImage: "arrow.uturn.backward.circle")
                }
            case .paid:
                DatePicker("Bezahlt am", selection: paidDate, displayedComponents: .date)
                Button {
                    invoice.status = .open
                    invoice.paidDate = nil
                } label: {
                    Label("Zahlung zurücksetzen", systemImage: "arrow.counterclockwise")
                }
            case .cancelled:
                EmptyView()
            }
            Button {
                newInvoice = invoice.duplicate(in: context, profile: context.companyProfile())
            } label: {
                Label("Als neue Rechnung duplizieren", systemImage: "doc.on.doc")
            }
        }
    }

    // MARK: Bindings

    private var hasServicePeriod: Binding<Bool> {
        Binding(get: { invoice.serviceEndDate != nil },
                set: { invoice.serviceEndDate = $0 ? invoice.serviceDate : nil })
    }

    private var serviceEndDate: Binding<Date> {
        Binding(get: { invoice.serviceEndDate ?? invoice.serviceDate },
                set: { invoice.serviceEndDate = $0 })
    }

    private var paidDate: Binding<Date> {
        Binding(get: { invoice.paidDate ?? .now },
                set: { invoice.paidDate = $0 })
    }

    // MARK: Aktionen

    private func addItem(_ item: InvoiceItem, edit: Bool) {
        item.position = (invoice.sortedItems.last?.position ?? 0) + 1
        context.insert(item)
        item.invoice = invoice
        if edit { editingItem = item }
    }

    private func deleteItems(at offsets: IndexSet) {
        let sorted = invoice.sortedItems
        for index in offsets { context.delete(sorted[index]) }
        renumber(sorted.enumerated().filter { !offsets.contains($0.offset) }.map(\.element))
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var sorted = invoice.sortedItems
        sorted.move(fromOffsets: source, toOffset: destination)
        renumber(sorted)
    }

    private func renumber(_ items: [InvoiceItem]) {
        for (index, item) in items.enumerated() { item.position = index + 1 }
    }

    private func finalize() {
        invoice.finalize(profile: context.companyProfile())
        try? context.save()
    }

    private func cancelInvoice() {
        invoice.status = .cancelled
        newInvoice = invoice.duplicate(in: context, profile: context.companyProfile(), asCancellation: true)
        try? context.save()
    }
}

struct ItemRow: View {
    let item: InvoiceItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.kind.icon)
                .foregroundStyle(.tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? "Ohne Bezeichnung" : item.title)
                    .lineLimit(2)
                Text("\(Fmt.number(item.quantity)) \(item.unit) × \(Fmt.money(item.unitPrice))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Fmt.money(item.lineTotal))
                .monospacedDigit()
        }
    }
}
