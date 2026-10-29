import SwiftUI
import SwiftData

extension Customer {
    static func makeNew(in context: ModelContext) -> Customer {
        let customer = Customer()
        customer.customerNumber = context.companyProfile().issueNextCustomerNumber()
        context.insert(customer)
        return customer
    }
}

struct CustomerRow: View {
    let customer: Customer

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(customer.displayName).font(.headline)
                if customer.isBusiness {
                    Image(systemName: "building.2").font(.caption).foregroundStyle(.secondary)
                }
            }
            Text([customer.customerNumber.isEmpty ? "" : "Nr. \(customer.customerNumber)", customer.cityLine]
                .filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct CustomerListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Customer.name) private var customers: [Customer]
    @State private var searchText = ""
    @State private var newCustomer: Customer?

    private var filtered: [Customer] {
        guard !searchText.isEmpty else { return customers }
        return customers.filter {
            [$0.name, $0.customerNumber, $0.city, $0.contactPerson].contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { customer in
                    NavigationLink {
                        CustomerEditView(customer: customer)
                    } label: {
                        CustomerRow(customer: customer)
                    }
                    .swipeActions {
                        if (customer.invoices ?? []).isEmpty {
                            Button(role: .destructive) { context.delete(customer) } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .overlay {
                if filtered.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView("Keine Kunden", systemImage: "person.2",
                                               description: Text("Tippe auf +, um einen Kunden anzulegen."))
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Name, Nummer, Ort")
            .navigationTitle("Kunden")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { newCustomer = Customer.makeNew(in: context) } label: {
                        Label("Neuer Kunde", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $newCustomer) { customer in
                NavigationStack { CustomerEditView(customer: customer, isNew: true) }
            }
            .navigationDestination(for: Invoice.self) { InvoiceDetailView(invoice: $0) }
        }
    }
}

struct CustomerEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var customer: Customer
    var isNew = false
    var onSave: ((Customer) -> Void)? = nil

    var body: some View {
        Form {
            Section {
                Picker("Kundenart", selection: $customer.isBusiness) {
                    Text("Privat").tag(false)
                    Text("Gewerblich").tag(true)
                }
                .pickerStyle(.segmented)
                TextField(customer.isBusiness ? "Firmenname" : "Name (z. B. Herr Max Mustermann)", text: $customer.name)
                    .textContentType(customer.isBusiness ? .organizationName : .name)
                TextField(customer.isBusiness ? "Ansprechpartner" : "Zusatz (optional)", text: $customer.contactPerson)
                TextField("Kunden-Nr.", text: $customer.customerNumber)
            } footer: {
                if !customer.isBusiness {
                    Text("Bei Privatkunden werden § 35a-Lohnanteil und Aufbewahrungshinweis auf der Rechnung ausgegeben.")
                }
            }

            Section("Anschrift") {
                TextField("Straße und Hausnummer", text: $customer.street)
                    .textContentType(.fullStreetAddress)
                HStack {
                    TextField("PLZ", text: $customer.zip)
                        .keyboardType(.numberPad)
                        .textContentType(.postalCode)
                        .frame(maxWidth: 80)
                    TextField("Ort", text: $customer.city)
                        .textContentType(.addressCity)
                }
            }

            Section("Kontakt") {
                TextField("E-Mail", text: $customer.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Telefon", text: $customer.phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            }

            if customer.isBusiness {
                Section("Steuer") {
                    TextField("USt-IdNr. (optional)", text: $customer.vatID)
                        .textInputAutocapitalization(.characters)
                }
            }

            Section("Notizen") {
                TextField("z. B. Schlüssel beim Nachbarn, Zählernummer …", text: $customer.notes, axis: .vertical)
                    .lineLimit(2...6)
            }

            if !isNew {
                let invoices = (customer.invoices ?? []).sorted { $0.createdAt > $1.createdAt }
                if !invoices.isEmpty {
                    Section("Rechnungen") {
                        ForEach(invoices) { invoice in
                            NavigationLink(value: invoice) { InvoiceRow(invoice: invoice) }
                        }
                    }
                }
            }
        }
        .navigationTitle(isNew ? "Neuer Kunde" : customer.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(isNew)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        context.delete(customer)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        onSave?(customer)
                        dismiss()
                    }
                    .disabled(customer.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct CustomerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Customer.name) private var customers: [Customer]
    @Binding var selection: Customer?
    @State private var searchText = ""
    @State private var newCustomer: Customer?

    private var filtered: [Customer] {
        guard !searchText.isEmpty else { return customers }
        return customers.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.city.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(filtered) { customer in
            Button {
                selection = customer
                dismiss()
            } label: {
                HStack {
                    CustomerRow(customer: customer)
                    Spacer()
                    if selection == customer {
                        Image(systemName: "checkmark").foregroundStyle(.tint)
                    }
                }
            }
            .foregroundStyle(.primary)
        }
        .overlay {
            if customers.isEmpty {
                ContentUnavailableView("Noch keine Kunden", systemImage: "person.crop.circle.badge.plus",
                                       description: Text("Lege oben rechts einen neuen Kunden an."))
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Kunde wählen")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { newCustomer = Customer.makeNew(in: context) } label: {
                    Label("Neuer Kunde", systemImage: "plus")
                }
            }
        }
        .sheet(item: $newCustomer) { customer in
            NavigationStack {
                CustomerEditView(customer: customer, isNew: true) { saved in selection = saved }
            }
        }
    }
}
