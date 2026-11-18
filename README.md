# Rechnungen – Rechnungs-App für iPhone & iPad

Native iOS-App (SwiftUI + SwiftData, iOS 17+) zum Schreiben von Rechnungen für Handwerksbetriebe.
Alle Daten bleiben lokal auf dem Gerät – kein Server, kein Abo, keine Tracking-SDKs.

## Funktionen

- **Rechnungen** mit Positionen (Arbeitslohn, Anfahrt, Material, Sonstiges), Menge, Einheit, Einzelpreis, USt. 19 / 7 / 0 %
- **Fortlaufende Rechnungsnummern** (`RE-2026-0001`), vergeben erst beim Abschließen → keine Lücken durch gelöschte Entwürfe
- **GoBD-freundlich**: abgeschlossene Rechnungen sind gesperrt, Empfängeradresse wird eingefroren, Korrektur nur per **Stornorechnung**
- **PDF nach DIN 5008** (passt in Fensterumschläge) mit Logo, Fußzeile mit Steuer- und Bankdaten, mehrseitig
- **GiroCode (EPC-QR)** auf der Rechnung – Kunde scannt mit der Banking-App, Betrag und Verwendungszweck sind vorausgefüllt
- **§ 35a EStG**: Lohn- und Anfahrtskosten werden bei Privatkunden automatisch separat ausgewiesen
- **Aufbewahrungshinweis** für Privatkunden (§ 14b UStG, Leistungen am Grundstück)
- **Kleinunternehmerregelung** (§ 19 UStG) per Schalter
- **Kundenverwaltung** (privat/gewerblich, automatische Kundennummern)
- **Leistungskatalog** für wiederkehrende Positionen
- **Übersicht**: offene und überfällige Beträge, Umsatz Monat/Jahr
- PDF teilen per Mail, WhatsApp, AirDrop, Dateien usw.

## Projektstruktur

```
Rechnungsprogramm.xcodeproj   Xcode-Projekt (Xcode 16+)
Rechnungsprogramm/
  App/        Einstiegspunkt
  Models/     SwiftData-Modelle (Firma, Kunde, Rechnung, Position, Katalog)
  Services/   PDF-Erzeugung, GiroCode, Formatierung
  Views/      SwiftUI-Oberfläche
Support/Info.plist
```

## Kostenlos testen

Alles hier ist kostenlos. Du brauchst nur einen Mac und deine normale Apple-ID, kein Abo.

### Im Simulator

1. **Xcode** kostenlos aus dem Mac App Store installieren.
2. `Rechnungsprogramm.xcodeproj` öffnen.
3. Oben ein iPhone-Modell als Ziel wählen und auf ▶︎ klicken.

### Auf dem eigenen iPhone

1. Xcode → *Settings → Accounts* → mit deiner Apple-ID anmelden.
2. Target *Rechnungsprogramm* → *Signing & Capabilities* → Team *„(Dein Name) (Personal Team)“* wählen.
3. Falls Xcode meckert, dass die Bundle-ID vergeben ist: sie auf etwas Eigenes ändern, z. B. `de.deinname.rechnungen`.
4. iPhone per Kabel anschließen, auf dem iPhone *Einstellungen → Datenschutz & Sicherheit → Entwicklermodus* einschalten (Neustart).
5. In Xcode das iPhone als Ziel wählen und ▶︎ klicken.
6. Auf dem iPhone *Einstellungen → Allgemein → VPN & Geräteverwaltung* → deinem Entwicklerprofil vertrauen.

Bei der kostenlosen Variante läuft die App **7 Tage**. Danach einfach in Xcode wieder ▶︎ klicken,
die gespeicherten Rechnungen und Kunden bleiben erhalten.

## Rechtliche Hinweise

Die App deckt die Pflichtangaben nach § 14 Abs. 4 UStG ab, ersetzt aber keine Steuerberatung.

**E-Rechnung:** Seit 01.01.2025 müssen Unternehmen E-Rechnungen *empfangen* können. Beim *Versand* an
Geschäftskunden (B2B) sind PDF-Rechnungen nur noch übergangsweise zulässig – bis Ende 2026, bei
Vorjahresumsatz bis 800.000 € bis Ende 2027. Danach ist für B2B ein strukturiertes Format
(XRechnung / ZUGFeRD) Pflicht. Rechnungen an Privatkunden sind davon nicht betroffen.
Ein ZUGFeRD-Export ist als nächster Ausbauschritt vorgesehen.
