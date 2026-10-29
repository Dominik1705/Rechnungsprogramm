import SwiftUI
import SwiftData

struct CatalogListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CatalogItem.title) private var items: [CatalogItem]
    @State private var editing: CatalogItem?

    var body: some View {
        List {
            ForEach(items) { item in
                Button { editing = item } label: { CatalogRow(item: item) }
                    .foregroundStyle(.primary)
            }
            .onDelete { offsets in
                for index in offsets { context.delete(items[index]) }
            }
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("Katalog leer", systemImage: "books.vertical",
                                       description: Text("Lege häufige Leistungen und Material an, z. B. „Steckdose setzen“ oder „Stundensatz Geselle“."))
            }
        }
        .navigationTitle("Leistungskatalog")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let item = CatalogItem(vatRate: context.companyProfile().defaultVatRate)
                    context.insert(item)
                    editing = item
                } label: {
                    Label("Neu", systemImage: "plus")
                }
            }
        }
        .sheet(item: $editing) { item in
            NavigationStack { CatalogItemEditView(item: item) }
        }
    }
}

struct CatalogRow: View {
    let item: CatalogItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.kind.icon)
                .foregroundStyle(.tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? "Ohne Bezeichnung" : item.title)
                Text(item.kind.title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Fmt.money(item.unitPrice)) / \(item.unit)")
                .font(.subheadline)
                .monospacedDigit()
        }
    }
}

struct CatalogItemEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: CatalogItem

    var body: some View {
        Form {
            Section {
                Picker("Art", selection: $item.kind) {
                    ForEach(ItemKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.icon).tag(kind)
                    }
                }
                TextField("Bezeichnung", text: $item.title)
                TextField("Beschreibung (optional)", text: $item.details, axis: .vertical)
                    .lineLimit(1...6)
            }
            Section("Preis") {
                UnitField(unit: $item.unit)
                DecimalField(title: "Einzelpreis netto", value: $item.unitPrice, suffix: "€")
                VatPicker(rate: $item.vatRate)
            }
        }
        .navigationTitle(item.title.isEmpty ? "Neuer Eintrag" : item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fertig") { dismiss() }
            }
        }
    }
}

struct CatalogPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CatalogItem.title) private var items: [CatalogItem]
    @State private var searchText = ""
    let onSelect: (CatalogItem) -> Void

    private var filtered: [CatalogItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.details.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { item in
                Button {
                    onSelect(item)
                    dismiss()
                } label: {
                    CatalogRow(item: item)
                }
                .foregroundStyle(.primary)
            }
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView("Katalog leer", systemImage: "books.vertical",
                                           description: Text("Einträge legst du unter Einstellungen → Leistungskatalog an."))
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Aus Katalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}
