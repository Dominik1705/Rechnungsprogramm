import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let invoice: Invoice
    let profile: CompanyProfile
    @State private var fileURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if let fileURL {
                    PDFKitView(url: fileURL)
                } else {
                    ProgressView("PDF wird erstellt …")
                }
            }
            .navigationTitle("\(invoice.documentTitle) \(invoice.displayNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if let fileURL {
                        ShareLink(item: fileURL,
                                  subject: Text("\(invoice.documentTitle) \(invoice.displayNumber)"),
                                  message: Text("Anbei erhalten Sie unsere \(invoice.documentTitle) \(invoice.displayNumber)."))
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !invoice.isLocked {
                    Text("Entwurf – zum Versenden zuerst abschließen.")
                        .font(.footnote)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(.yellow.opacity(0.3))
                }
            }
            .task { fileURL = makeFile() }
        }
    }

    private func makeFile() -> URL? {
        let data = InvoicePDFRenderer(invoice: invoice, profile: profile).render()
        let base = "\(invoice.documentTitle)_\(invoice.displayNumber)"
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(base).pdf")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.backgroundColor = .secondarySystemBackground
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
    }
}
