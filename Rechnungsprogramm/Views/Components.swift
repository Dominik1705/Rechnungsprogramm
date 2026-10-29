import SwiftUI

extension Invoice {
    var displayStatusTitle: String { isOverdue ? "Überfällig" : status.title }

    var statusColor: Color {
        if isOverdue { return .red }
        switch status {
        case .draft: return .gray
        case .open: return .orange
        case .paid: return .green
        case .cancelled: return .secondary
        }
    }
}

struct StatusBadge: View {
    let invoice: Invoice

    var body: some View {
        Text(invoice.displayStatusTitle)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(invoice.statusColor)
            .background(invoice.statusColor.opacity(0.15), in: Capsule())
    }
}

struct InvoiceRow: View {
    let invoice: Invoice

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(invoice.recipientName)
                    .font(.headline)
                    .lineLimit(1)
                Text(invoice.documentTitle == "Rechnung" ? invoice.displayNumber : "\(invoice.documentTitle) \(invoice.displayNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !invoice.subject.isEmpty {
                    Text(invoice.subject)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Fmt.money(invoice.totals.gross))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                StatusBadge(invoice: invoice)
            }
        }
        .padding(.vertical, 2)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Eingabefeld für Geldbeträge und Mengen mit deutscher Dezimaldarstellung.
struct DecimalField: View {
    let title: String
    @Binding var value: Decimal
    var suffix: String? = nil

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: $value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
            if let suffix {
                Text(suffix).foregroundStyle(.secondary)
            }
        }
    }
}

struct UnitField: View {
    @Binding var unit: String

    var body: some View {
        HStack {
            Text("Einheit")
            Spacer()
            TextField("Einheit", text: $unit)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
            Menu {
                ForEach(Units.common, id: \.self) { u in
                    Button(u) { unit = u }
                }
            } label: {
                Image(systemName: "chevron.up.chevron.down")
            }
        }
    }
}

struct VatPicker: View {
    @Binding var rate: Decimal

    var body: some View {
        Picker("Umsatzsteuer", selection: $rate) {
            ForEach(VatRate.options, id: \.self) { option in
                Text(Fmt.percent(option)).tag(option)
            }
        }
    }
}
