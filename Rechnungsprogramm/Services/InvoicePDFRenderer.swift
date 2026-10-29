import UIKit
import CoreImage.CIFilterBuiltins

private let mm: CGFloat = 72 / 25.4

/// Erzeugt ein A4-PDF im Layout nach DIN 5008 (Form B, passend für Fensterumschläge).
final class InvoicePDFRenderer {
    private struct Column {
        let title: String
        var width: CGFloat
        let alignment: NSTextAlignment
    }

    private let invoice: Invoice
    private let profile: CompanyProfile
    private let totals: InvoiceTotals

    private let pageRect = CGRect(x: 0, y: 0, width: 210 * mm, height: 297 * mm)
    private let marginLeft = 25 * mm
    private let marginRight = 20 * mm
    private let marginTop = 18 * mm
    private let footerHeight = 30 * mm

    private let fontBody = UIFont.systemFont(ofSize: 9.5)
    private let fontBodyBold = UIFont.boldSystemFont(ofSize: 9.5)
    private let fontSmall = UIFont.systemFont(ofSize: 8.5)
    private let fontSmallBold = UIFont.boldSystemFont(ofSize: 8.5)
    private let fontTiny = UIFont.systemFont(ofSize: 7)
    private let textColor = UIColor(white: 0.1, alpha: 1)
    private let grayColor = UIColor(white: 0.42, alpha: 1)
    private let lineColor = UIColor(white: 0.82, alpha: 1)
    private let accentColor = UIColor(red: 0.0, green: 0.36, blue: 0.68, alpha: 1)

    private var context: UIGraphicsPDFRendererContext?
    private var y: CGFloat = 0
    private var pageNumber = 0

    private var right: CGFloat { pageRect.width - marginRight }
    private var contentWidth: CGFloat { right - marginLeft }
    private var contentBottom: CGFloat { pageRect.height - footerHeight - 4 * mm }

    init(invoice: Invoice, profile: CompanyProfile) {
        self.invoice = invoice
        self.profile = profile
        self.totals = invoice.totals
    }

    func render() -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(invoice.documentTitle) \(invoice.displayNumber)",
            kCGPDFContextAuthor as String: profile.companyName,
            kCGPDFContextCreator as String: "Rechnungen"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return renderer.pdfData { ctx in
            context = ctx
            pageNumber = 0
            startPage()
            drawLetterhead()
            drawAddressAndInfoBlock()
            drawTitleAndIntro()
            drawItemsTable()
            drawTotals()
            drawNotes()
            drawPayment()
            drawClosing()
        }
    }

    // MARK: Seitenverwaltung

    private func startPage() {
        context?.beginPage()
        pageNumber += 1
        drawFooter()
        y = marginTop
        if pageNumber > 1 {
            let header = "\(invoice.documentTitle) \(invoice.displayNumber) · Seite \(pageNumber)"
            y += draw(header, font: fontSmall, color: grayColor, in: CGRect(x: marginLeft, y: y, width: contentWidth, height: 0))
            y += 6 * mm
        }
    }

    /// Startet eine neue Seite, wenn der Platz nicht reicht. Gibt `true` zurück, wenn umgebrochen wurde.
    @discardableResult
    private func ensureSpace(_ height: CGFloat) -> Bool {
        guard y + height > contentBottom else { return false }
        startPage()
        return true
    }

    // MARK: Briefkopf

    private func drawLetterhead() {
        if let data = profile.logoData, let logo = UIImage(data: data) {
            let maxSize = CGSize(width: 55 * mm, height: 22 * mm)
            let scale = min(maxSize.width / logo.size.width, maxSize.height / logo.size.height)
            let size = CGSize(width: logo.size.width * scale, height: logo.size.height * scale)
            logo.draw(in: CGRect(x: right - size.width, y: 12 * mm, width: size.width, height: size.height))
        }

        var headY = 14 * mm
        headY += draw(profile.companyName, font: .boldSystemFont(ofSize: 15), color: accentColor,
                      in: CGRect(x: marginLeft, y: headY, width: 100 * mm, height: 0))
        let sub = [profile.ownerName, profile.street, profile.cityLine].filter { !$0.isEmpty }.joined(separator: " · ")
        let contact = [profile.phone.isEmpty ? "" : "Tel. \(profile.phone)", profile.email].filter { !$0.isEmpty }.joined(separator: " · ")
        headY += 1
        headY += draw(sub, font: fontSmall, color: grayColor, in: CGRect(x: marginLeft, y: headY, width: 100 * mm, height: 0))
        draw(contact, font: fontSmall, color: grayColor, in: CGRect(x: marginLeft, y: headY, width: 100 * mm, height: 0))
    }

    private func drawAddressAndInfoBlock() {
        // Rücksendeangabe direkt über dem Anschriftfeld
        let sender = [profile.companyName, profile.street, profile.cityLine].filter { !$0.isEmpty }.joined(separator: " · ")
        let senderY = 57 * mm
        let senderHeight = draw(sender, font: fontTiny, color: grayColor, in: CGRect(x: marginLeft, y: senderY, width: 80 * mm, height: 0))
        line(from: marginLeft, to: marginLeft + 80 * mm, at: senderY + senderHeight + 1, color: grayColor, width: 0.3)

        var addressY = 63 * mm
        for lineText in invoice.recipientLines {
            addressY += draw(lineText, font: .systemFont(ofSize: 10.5), in: CGRect(x: marginLeft, y: addressY, width: 85 * mm, height: 0))
        }

        // Informationsblock rechts
        let infoX = right - 70 * mm
        let infoWidth = 70 * mm
        var infoY = 50 * mm
        var rows: [(String, String)] = [
            ("\(invoice.documentTitle)s-Nr.", invoice.displayNumber),
            ("Datum", Fmt.date(invoice.issueDate))
        ]
        if let end = invoice.serviceEndDate {
            rows.append(("Leistungszeitraum", "\(Fmt.date(invoice.serviceDate)) – \(Fmt.date(end))"))
        } else {
            rows.append(("Leistungsdatum", Fmt.date(invoice.serviceDate)))
        }
        if !invoice.customerNumber.isEmpty { rows.append(("Kunden-Nr.", invoice.customerNumber)) }
        if !invoice.referenceNumber.isEmpty { rows.append(("Bezug", invoice.referenceNumber)) }
        if totals.gross > 0 && invoice.status != .paid { rows.append(("Fällig am", Fmt.date(invoice.dueDate))) }

        for (label, value) in rows {
            let h = draw(label, font: fontSmall, color: grayColor, in: CGRect(x: infoX, y: infoY, width: infoWidth / 2, height: 0))
            draw(value, font: fontSmallBold, in: CGRect(x: infoX + infoWidth / 2, y: infoY, width: infoWidth / 2, height: 0), alignment: .right)
            infoY += h + 2
        }

        y = max(103 * mm, infoY + 6 * mm)
    }

    private func drawTitleAndIntro() {
        let title = invoice.isLocked ? "\(invoice.documentTitle) \(invoice.number)" : "\(invoice.documentTitle) (Entwurf)"
        y += draw(title, font: .boldSystemFont(ofSize: 15), in: CGRect(x: marginLeft, y: y, width: contentWidth, height: 0))
        if !invoice.subject.isEmpty {
            y += 2
            y += draw(invoice.subject, font: fontBodyBold, in: CGRect(x: marginLeft, y: y, width: contentWidth, height: 0))
        }
        if !invoice.introText.isEmpty {
            y += 4 * mm
            y += draw(invoice.introText, font: fontBody, in: CGRect(x: marginLeft, y: y, width: contentWidth, height: 0))
        }
        y += 5 * mm
    }

    // MARK: Positionen

    private var columns: [Column] {
        var cols = [
            Column(title: "Pos.", width: 9 * mm, alignment: .left),
            Column(title: "Bezeichnung", width: 0, alignment: .left),
            Column(title: "Menge", width: 15 * mm, alignment: .right),
            Column(title: "Einheit", width: 15 * mm, alignment: .left),
            Column(title: "Einzelpreis", width: 22 * mm, alignment: .right)
        ]
        if !invoice.isSmallBusiness {
            cols.append(Column(title: "USt.", width: 12 * mm, alignment: .right))
        }
        cols.append(Column(title: "Gesamt", width: 24 * mm, alignment: .right))
        let fixed = cols.reduce(0) { $0 + $1.width }
        cols[1].width = contentWidth - fixed
        return cols
    }

    private func drawTableHeader() {
        let height: CGFloat = 6 * mm
        UIColor(white: 0.94, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: marginLeft, y: y, width: contentWidth, height: height)).fill()
        var x = marginLeft
        for column in columns {
            draw(column.title, font: fontSmallBold, in: CGRect(x: x + 2, y: y + 4.5, width: column.width - 4, height: 0), alignment: column.alignment)
            x += column.width
        }
        y += height + 2
    }

    private func drawItemsTable() {
        ensureSpace(20 * mm)
        drawTableHeader()
        let cols = columns
        let descWidth = cols[1].width - 4

        for (index, item) in invoice.sortedItems.enumerated() {
            let titleHeight = height(of: item.title, font: fontBodyBold, width: descWidth)
            let detailHeight = item.details.isEmpty ? 0 : height(of: item.details, font: fontSmall, width: descWidth) + 1
            let rowHeight = max(titleHeight + detailHeight, 12) + 5

            if ensureSpace(rowHeight) { drawTableHeader() }

            var values = [
                "\(index + 1)",
                "",
                Fmt.number(item.quantity),
                item.unit,
                Fmt.money(item.unitPrice)
            ]
            if !invoice.isSmallBusiness { values.append(Fmt.percent(item.vatRate)) }
            values.append(Fmt.money(item.lineTotal))

            var x = marginLeft
            for (col, value) in zip(cols, values) {
                let rect = CGRect(x: x + 2, y: y + 2, width: col.width - 4, height: 0)
                if col.title == "Bezeichnung" {
                    let h = draw(item.title, font: fontBodyBold, in: rect)
                    if !item.details.isEmpty {
                        draw(item.details, font: fontSmall, color: grayColor, in: rect.offsetBy(dx: 0, dy: h + 1))
                    }
                } else {
                    draw(value, font: fontBody, in: rect, alignment: col.alignment)
                }
                x += col.width
            }
            y += rowHeight
            line(from: marginLeft, to: right, at: y - 1)
        }
        y += 3 * mm
    }

    private func drawTotals() {
        var rows: [(label: String, value: String, bold: Bool)] = []
        if invoice.isSmallBusiness {
            rows.append(("Gesamtbetrag", Fmt.money(totals.gross), true))
        } else {
            rows.append(("Summe netto", Fmt.money(totals.net), false))
            for group in totals.vatGroups {
                rows.append(("zzgl. \(Fmt.percent(group.rate)) USt. auf \(Fmt.money(group.net))", Fmt.money(group.vat), false))
            }
            rows.append(("Gesamtbetrag", Fmt.money(totals.gross), true))
        }

        let blockWidth = 95 * mm
        let x = right - blockWidth
        let rowHeight: CGFloat = 14
        ensureSpace(CGFloat(rows.count) * rowHeight + 10)

        for row in rows {
            if row.bold {
                line(from: x, to: right, at: y + 1, color: textColor, width: 0.8)
                y += 4
            }
            let font = row.bold ? UIFont.boldSystemFont(ofSize: 11) : fontBody
            draw(row.label, font: font, in: CGRect(x: x, y: y, width: blockWidth - 30 * mm, height: 0))
            draw(row.value, font: font, in: CGRect(x: right - 30 * mm, y: y, width: 30 * mm, height: 0), alignment: .right)
            y += row.bold ? rowHeight + 2 : rowHeight
        }
        y += 4 * mm
    }

    // MARK: Hinweise, Zahlung, Gruß

    private func drawNotes() {
        var notes: [String] = []
        if invoice.isSmallBusiness {
            notes.append("Gemäß § 19 UStG wird keine Umsatzsteuer berechnet.")
        }
        if !invoice.recipientIsBusiness && totals.laborNet > 0 {
            if invoice.isSmallBusiness {
                notes.append("Im Rechnungsbetrag sind Arbeits- und Fahrtkosten in Höhe von \(Fmt.money(totals.laborGross)) enthalten (steuerlich absetzbar nach § 35a EStG).")
            } else {
                notes.append("Im Rechnungsbetrag sind Arbeits- und Fahrtkosten in Höhe von \(Fmt.money(totals.laborNet)) netto zzgl. \(Fmt.money(totals.laborVat)) USt., gesamt \(Fmt.money(totals.laborGross)) enthalten (steuerlich absetzbar nach § 35a EStG).")
            }
        }
        if !invoice.recipientIsBusiness && profile.showRetentionNotice {
            notes.append("Hinweis: Als Privatperson sind Sie verpflichtet, diese Rechnung zwei Jahre aufzubewahren (§ 14b Abs. 1 Satz 5 UStG).")
        }
        for note in notes {
            let h = height(of: note, font: fontSmall, width: contentWidth)
            ensureSpace(h + 3)
            y += draw(note, font: fontSmall, color: grayColor, in: CGRect(x: marginLeft, y: y, width: contentWidth, height: 0)) + 3
        }
        if !notes.isEmpty { y += 3 * mm }
    }

    private func drawPayment() {
        let text: String
        var showQR = false
        if invoice.status == .paid {
            text = "Der Rechnungsbetrag wurde am \(Fmt.date(invoice.paidDate ?? .now)) dankend erhalten."
        } else if totals.gross < 0 {
            text = "Der Betrag von \(Fmt.money(-totals.gross)) wird Ihnen erstattet bzw. mit offenen Forderungen verrechnet."
        } else if totals.gross == 0 {
            return
        } else {
            var parts = ["Bitte überweisen Sie den Betrag von \(Fmt.money(totals.gross)) bis zum \(Fmt.date(invoice.dueDate)) ohne Abzug unter Angabe der Rechnungsnummer \(invoice.displayNumber)."]
            if !profile.iban.isEmpty {
                let bank = [profile.bankName, "IBAN \(profile.iban)", profile.bic.isEmpty ? "" : "BIC \(profile.bic)"].filter { !$0.isEmpty }
                parts.append(bank.joined(separator: " · "))
                showQR = invoice.isLocked
            }
            text = parts.joined(separator: "\n")
        }

        let qrSize = 24 * mm
        let textWidth = showQR ? contentWidth - qrSize - 6 * mm : contentWidth
        let textHeight = height(of: text, font: fontBody, width: textWidth)
        ensureSpace(max(textHeight, showQR ? qrSize + 12 : 0) + 4)

        draw(text, font: fontBody, in: CGRect(x: marginLeft, y: y, width: textWidth, height: 0))

        if showQR, let qr = GiroCode.image(name: profile.companyName, iban: profile.iban, bic: profile.bic,
                                            amount: totals.gross, reference: invoice.number) {
            let qrRect = CGRect(x: right - qrSize, y: y, width: qrSize, height: qrSize)
            UIGraphicsGetCurrentContext()?.interpolationQuality = .none
            qr.draw(in: qrRect)
            draw("GiroCode – mit Banking-App scannen", font: fontTiny, color: grayColor,
                 in: CGRect(x: qrRect.minX - 8 * mm, y: qrRect.maxY + 2, width: qrSize + 8 * mm, height: 0), alignment: .right)
            y += max(textHeight, qrSize + 12)
        } else {
            y += textHeight
        }
        y += 5 * mm
    }

    private func drawClosing() {
        guard !invoice.closingText.isEmpty else { return }
        let text = invoice.closingText + (profile.ownerName.isEmpty ? "" : "\n\n\(profile.ownerName)")
        let h = height(of: text, font: fontBody, width: contentWidth)
        ensureSpace(h)
        y += draw(text, font: fontBody, in: CGRect(x: marginLeft, y: y, width: contentWidth, height: 0))
    }

    private func drawFooter() {
        let top = pageRect.height - footerHeight
        line(from: marginLeft, to: right, at: top, color: lineColor, width: 0.5)

        let columns: [String] = [
            [profile.companyName, profile.ownerName, profile.street, profile.cityLine],
            [profile.phone.isEmpty ? "" : "Tel. \(profile.phone)", profile.email, profile.website],
            [profile.taxNumber.isEmpty ? "" : "Steuernr. \(profile.taxNumber)",
             profile.vatID.isEmpty ? "" : "USt-IdNr. \(profile.vatID)",
             profile.registerInfo],
            [profile.bankName, profile.iban.isEmpty ? "" : "IBAN \(profile.iban)", profile.bic.isEmpty ? "" : "BIC \(profile.bic)"]
        ].map { $0.filter { !$0.isEmpty }.joined(separator: "\n") }

        let columnWidth = contentWidth / CGFloat(columns.count)
        for (i, text) in columns.enumerated() {
            draw(text, font: fontTiny, color: grayColor,
                 in: CGRect(x: marginLeft + CGFloat(i) * columnWidth, y: top + 3 * mm, width: columnWidth - 3 * mm, height: 0))
        }
        draw("Seite \(pageNumber)", font: fontTiny, color: grayColor,
             in: CGRect(x: right - 30 * mm, y: pageRect.height - 9 * mm, width: 30 * mm, height: 0), alignment: .right)
    }

    // MARK: Zeichen-Helfer

    private func attributed(_ text: String, font: UIFont, color: UIColor, alignment: NSTextAlignment) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        return NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ])
    }

    private func height(of text: String, font: UIFont, width: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let bounds = attributed(text, font: font, color: textColor, alignment: .left)
            .boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                          options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(bounds.height)
    }

    /// Zeichnet Text ab `rect.origin` mit Umbruch auf `rect.width` und gibt die belegte Höhe zurück.
    @discardableResult
    private func draw(_ text: String, font: UIFont, color: UIColor? = nil, in rect: CGRect, alignment: NSTextAlignment = .left) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let h = height(of: text, font: font, width: rect.width)
        attributed(text, font: font, color: color ?? textColor, alignment: alignment)
            .draw(with: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: h),
                  options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return h
    }

    private func line(from x1: CGFloat, to x2: CGFloat, at y: CGFloat, color: UIColor? = nil, width: CGFloat = 0.5) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x1, y: y))
        path.addLine(to: CGPoint(x: x2, y: y))
        path.lineWidth = width
        (color ?? lineColor).setStroke()
        path.stroke()
    }
}

/// EPC-QR-Code ("GiroCode") für SEPA-Überweisungen.
enum GiroCode {
    static func payload(name: String, iban: String, bic: String, amount: Decimal, reference: String) -> String {
        let amountString = String(format: "%.2f", NSDecimalNumber(decimal: amount.roundedToCents()).doubleValue)
        return [
            "BCD",
            "002",
            "1",
            "SCT",
            bic.replacingOccurrences(of: " ", with: "").uppercased(),
            String(name.prefix(70)),
            iban.replacingOccurrences(of: " ", with: "").uppercased(),
            "EUR\(amountString)",
            "",
            "",
            String(reference.prefix(140))
        ].joined(separator: "\n")
    }

    static func image(name: String, iban: String, bic: String, amount: Decimal, reference: String) -> UIImage? {
        guard amount > 0, !iban.isEmpty, !name.isEmpty else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload(name: name, iban: iban, bic: bic, amount: amount, reference: reference).utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
