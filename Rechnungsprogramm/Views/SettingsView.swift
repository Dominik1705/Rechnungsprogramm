import SwiftUI
import SwiftData
import PhotosUI

struct SettingsView: View {
    @Query private var profiles: [CompanyProfile]

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    ProfileForm(profile: profile)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

private struct ProfileForm: View {
    @Bindable var profile: CompanyProfile
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        Form {
            if !profile.isComplete {
                Section {
                    Label("Bitte Firmenname, Anschrift und Steuernummer bzw. USt-IdNr. eintragen – das sind Pflichtangaben auf jeder Rechnung (§ 14 Abs. 4 UStG).",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }

            Section("Firma") {
                TextField("Firmenname", text: $profile.companyName)
                    .textContentType(.organizationName)
                TextField("Inhaber", text: $profile.ownerName)
                    .textContentType(.name)
                TextField("Straße und Hausnummer", text: $profile.street)
                    .textContentType(.fullStreetAddress)
                HStack {
                    TextField("PLZ", text: $profile.zip)
                        .keyboardType(.numberPad)
                        .frame(maxWidth: 80)
                    TextField("Ort", text: $profile.city)
                }
            }

            Section("Kontakt") {
                TextField("Telefon", text: $profile.phone)
                    .keyboardType(.phonePad)
                TextField("E-Mail", text: $profile.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Website", text: $profile.website)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
            }

            Section("Logo") {
                if let data = profile.logoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 70)
                    Button("Logo entfernen", role: .destructive) { profile.logoData = nil }
                }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(profile.logoData == nil ? "Logo auswählen" : "Logo ändern", systemImage: "photo")
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        profile.logoData = image.downscaled(maxDimension: 800).pngData()
                    }
                }
            }

            Section {
                TextField("Steuernummer", text: $profile.taxNumber)
                TextField("USt-IdNr.", text: $profile.vatID)
                    .textInputAutocapitalization(.characters)
                TextField("Handwerksrolle / Register (optional)", text: $profile.registerInfo)
                Toggle("Kleinunternehmer (§ 19 UStG)", isOn: $profile.isSmallBusiness)
                if !profile.isSmallBusiness {
                    VatPicker(rate: $profile.defaultVatRate)
                }
            } header: {
                Text("Steuer")
            } footer: {
                Text("Beispiel Handwerksrolle: „Eingetragen in die Handwerksrolle der HWK München, Nr. 12345“.")
            }

            Section("Bankverbindung") {
                TextField("Bank", text: $profile.bankName)
                TextField("IBAN", text: $profile.iban)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                TextField("BIC", text: $profile.bic)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            Section {
                TextField("Präfix", text: $profile.invoicePrefix)
                    .textInputAutocapitalization(.characters)
                Stepper("Nächste Nr.: \(profile.nextInvoiceNumber)", value: $profile.nextInvoiceNumber, in: 1...99_999)
                LabeledContent("Vorschau", value: profile.previewNextInvoiceNumber)
                Stepper("Zahlungsziel: \(profile.defaultDueDays) Tage", value: $profile.defaultDueDays, in: 0...120)
                Toggle("Aufbewahrungshinweis bei Privatkunden", isOn: $profile.showRetentionNotice)
            } header: {
                Text("Rechnungen")
            } footer: {
                Text("Die Nummer wird beim Abschließen vergeben und startet jedes Jahr bei 1. Wenn du von einem anderen Programm wechselst, stelle hier die nächste freie Nummer ein.")
            }

            Section("Standardtexte") {
                TextField("Einleitung", text: $profile.defaultIntroText, axis: .vertical)
                    .lineLimit(2...6)
                TextField("Schlusstext", text: $profile.defaultClosingText, axis: .vertical)
                    .lineLimit(1...4)
            }

            Section {
                NavigationLink {
                    CatalogListView()
                } label: {
                    Label("Leistungskatalog", systemImage: "books.vertical")
                }
            }

            Section {
                Text("Alle Daten werden ausschließlich lokal auf diesem Gerät gespeichert. Es werden keine Daten an Dritte übertragen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
