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

## Starten

1. Mac mit **Xcode 16** oder neuer.
2. `Rechnungsprogramm.xcodeproj` öffnen.
3. Target *Rechnungsprogramm* → *Signing & Capabilities* → dein **Team** wählen.
4. Simulator oder iPhone auswählen → ▶︎ Run.

## Veröffentlichung im App Store

1. **Apple Developer Program** beitreten (99 €/Jahr): <https://developer.apple.com/programs/>
2. Bundle-ID anpassen (aktuell `de.bujak.rechnungen`) – muss weltweit eindeutig sein.
3. In **App Store Connect** eine neue App mit dieser Bundle-ID anlegen.
4. App-Icon ersetzen: `Rechnungsprogramm/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (1024 × 1024 px, ohne Transparenz). Das mitgelieferte Icon ist ein Platzhalter.
5. In Xcode: *Product → Archive* → *Distribute App* → *App Store Connect*.
6. In App Store Connect ausfüllen:
   - Screenshots (iPhone 6,9" und 6,5", bei iPad-Unterstützung auch 13")
   - Beschreibung, Keywords, Kategorie *Wirtschaft*
   - **Datenschutzerklärung-URL** (Pflicht, auch wenn keine Daten erhoben werden)
   - App-Datenschutz: „Keine Daten erfasst“
   - Exportkonformität ist bereits gesetzt (`ITSAppUsesNonExemptEncryption = NO`)
7. Zur Prüfung einreichen – üblicherweise 1–3 Tage.

Tipp: Vorher per **TestFlight** auf dem eigenen iPhone im Alltag testen.

## Rechtliche Hinweise

Die App deckt die Pflichtangaben nach § 14 Abs. 4 UStG ab, ersetzt aber keine Steuerberatung.

**E-Rechnung:** Seit 01.01.2025 müssen Unternehmen E-Rechnungen *empfangen* können. Beim *Versand* an
Geschäftskunden (B2B) sind PDF-Rechnungen nur noch übergangsweise zulässig – bis Ende 2026, bei
Vorjahresumsatz bis 800.000 € bis Ende 2027. Danach ist für B2B ein strukturiertes Format
(XRechnung / ZUGFeRD) Pflicht. Rechnungen an Privatkunden sind davon nicht betroffen.
Ein ZUGFeRD-Export ist als nächster Ausbauschritt vorgesehen.
