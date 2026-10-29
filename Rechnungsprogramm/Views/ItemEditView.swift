import SwiftUI

struct ItemEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: InvoiceItem
    var isLocked = false

    var body: some View {
        Form {
            Group {
                Section {
                    Picker("Art", selection: $item.kind) {
                        ForEach(ItemKind.allCases) { kind in
                            Label(kind.title, systemImage: kind.icon).tag(kind)
                        }
                    }
                    TextField("Bezeichnung", text: $item.title)
                    TextField("Beschreibung (optional)", text: $item.details, axis: .vertical)
                        .lineLimit(1...6)
                } footer: {
                    if item.kind.countsAsLaborCost {
                        Text("Wird bei Privatkunden als Lohnanteil nach § 35a EStG auf der Rechnung ausgewiesen.")
                    }
                }

                Section("Menge & Preis") {
                    DecimalField(title: "Menge", value: $item.quantity)
                    UnitField(unit: $item.unit)
                    DecimalField(title: "Einzelpreis netto", value: $item.unitPrice, suffix: "€")
                    VatPicker(rate: $item.vatRate)
                }

                Section {
                    LabeledContent("Gesamt netto", value: Fmt.money(item.lineTotal))
                        .bold()
                        .monospacedDigit()
                }
            }
            .disabled(isLocked)
        }
        .navigationTitle(item.title.isEmpty ? "Position" : item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fertig") { dismiss() }
            }
        }
    }
}
