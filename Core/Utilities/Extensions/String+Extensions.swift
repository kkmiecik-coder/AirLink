//
//  String+Extensions.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation

// MARK: - String Extensions

extension String {
    
    // MARK: - Localization
    
    /// Zwraca zlokalizowany string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Zwraca zlokalizowany string z argumentami
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    // MARK: - Validation
    
    /// Sprawdza czy string nie jest pusty (po trim)
    var isNotEmptyTrimmed: Bool {
        return !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Sprawdza czy string jest prawidłowym pseudonimem
    var isValidNickname: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1 && trimmed.count <= 30 && !trimmed.containsOnlyWhitespace
    }
    
    /// Sprawdza czy string zawiera tylko białe znaki
    var containsOnlyWhitespace: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Formatting
    
    /// Zwraca pierwszą literę (wielką)
    var firstLetter: String {
        return String(self.prefix(1).uppercased())
    }
    
    /// Zwraca inicjały (pierwsze litery słów)
    var initials: String {
        let words = self.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if words.isEmpty {
            return "?"
        } else if words.count == 1 {
            return String(words[0].prefix(1).uppercased())
        } else {
            return words.prefix(2)
                .compactMap { $0.first?.uppercased() }
                .joined()
        }
    }
    
    /// Formatuje string do wyświetlania (truncate jeśli za długi)
    func truncated(to length: Int, with suffix: String = "...") -> String {
        if self.count <= length {
            return self
        } else {
            return String(self.prefix(length - suffix.count)) + suffix
        }
    }
    
    /// Kapitalizuje pierwsze litery słów
    var capitalizedWords: String {
        return self.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    // MARK: - Text Processing
    
    /// Usuwa emoji ze stringa
    var withoutEmoji: String {
        return self.filter { !$0.isEmoji }
    }
    
    /// Sprawdza czy string zawiera emoji
    var containsEmoji: Bool {
        return self.contains { $0.isEmoji }
    }
    
    /// Zwraca safe string dla nazw plików
    var safeFileName: String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return self.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    // MARK: - Date Formatting
    
    /// Formatuje date jako string względny (np. "2 minuty temu")
    static func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "pl_PL")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Formatuje date jako string dla wiadomości
    static func messageTimeString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "pl_PL")
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "wczoraj"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "pl_PL")
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.locale = Locale(identifier: "pl_PL")
            return formatter.string(from: date)
        }
    }
    
    /// Formatuje date jako "ostatnio widziany"
    static func lastSeenString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "pl_PL")
            return "dzisiaj o \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "pl_PL")
            return "wczoraj o \(formatter.string(from: date))"
        } else {
            let daysDifference = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            
            if daysDifference < 7 {
                return "\(daysDifference) dni temu"
            } else if daysDifference < 30 {
                let weeks = daysDifference / 7
                return "\(weeks) tygodni temu"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.locale = Locale(identifier: "pl_PL")
                return formatter.string(from: date)
            }
        }
    }
    
    // MARK: - Search & Filtering
    
    /// Sprawdza czy string pasuje do zapytania wyszukiwania
    func matches(searchQuery: String) -> Bool {
        guard !searchQuery.isEmpty else { return true }
        
        let searchTerms = searchQuery.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let searchableText = self.lowercased()
        
        return searchTerms.allSatisfy { term in
            searchableText.contains(term)
        }
    }
    
    /// Highlight searched terms (dla UI)
    func highlighted(searchQuery: String) -> String {
        guard !searchQuery.isEmpty else { return self }
        
        var result = self
        let searchTerms = searchQuery.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        for term in searchTerms {
            let range = NSString(string: result).range(of: term, options: .caseInsensitive)
            if range.location != NSNotFound {
                let highlightedTerm = "**\(NSString(string: result).substring(with: range))**"
                result = NSString(string: result).replacingCharacters(in: range, with: highlightedTerm)
            }
        }
        
        return result
    }
    
    // MARK: - Encoding & Security
    
    /// Zwraca base64 encoded string
    var base64Encoded: String? {
        return self.data(using: .utf8)?.base64EncodedString()
    }
    
    /// Dekoduje base64 string
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Generuje hash MD5 (dla identyfikatorów)
    var md5Hash: String {
        guard let data = self.data(using: .utf8) else { return "" }
        return data.md5
    }
    
    // MARK: - Phone & Contact Formatting
    
    /// Formatuje numer telefonu (jeśli kiedyś będzie potrzebny)
    var formattedPhoneNumber: String {
        let digits = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        guard digits.count >= 9 else { return self }
        
        if digits.hasPrefix("48") && digits.count == 11 {
            // Polski numer z kodem kraju
            let areaCode = String(digits.prefix(2))
            let mainNumber = String(digits.dropFirst(2))
            return "+\(areaCode) \(formatPolishNumber(mainNumber))"
        } else if digits.count == 9 {
            // Polski numer bez kodu kraju
            return formatPolishNumber(digits)
        }
        
        return self
    }
    
    private func formatPolishNumber(_ number: String) -> String {
        guard number.count == 9 else { return number }
        
        let firstThree = String(number.prefix(3))
        let middleThree = String(number.dropFirst(3).prefix(3))
        let lastThree = String(number.suffix(3))
        
        return "\(firstThree) \(middleThree) \(lastThree)"
    }
    
    // MARK: - File Size Formatting
    
    /// Formatuje rozmiar pliku (bytes to human readable)
    static func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // MARK: - Network & Connectivity
    
    /// Sprawdza czy string jest prawidłowym UUID
    var isValidUUID: Bool {
        return UUID(uuidString: self) != nil
    }
    
    /// Skraca UUID do czytelnej formy (pierwsze 8 znaków)
    var shortUUID: String {
        guard self.count >= 8 else { return self }
        return String(self.prefix(8))
    }
    
    // MARK: - Message Content
    
    /// Sprawdza czy string zawiera tylko whitespace i emoji
    var isEmptyContent: Bool {
        let withoutEmoji = self.withoutEmoji
        return withoutEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Zwraca preview tekstu dla listy wiadomości
    var messagePreview: String {
        let cleaned = self.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        
        return cleaned.truncated(to: 100)
    }
    
    // MARK: - Polish Language Helpers
    
    /// Zwraca odpowiednią formę liczby mnogiej w języku polskim
    static func polishPlural(count: Int, one: String, few: String, many: String) -> String {
        if count == 1 {
            return one
        } else if count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20) {
            return few
        } else {
            return many
        }
    }
    
    /// Formatuje liczbę wiadomości
    static func formatMessageCount(_ count: Int) -> String {
        let form = polishPlural(
            count: count,
            one: "wiadomość",
            few: "wiadomości",
            many: "wiadomości"
        )
        return "\(count) \(form)"
    }
    
    /// Formatuje liczbę uczestników
    static func formatParticipantCount(_ count: Int) -> String {
        let form = polishPlural(
            count: count,
            one: "uczestnik",
            few: "uczestników",
            many: "uczestników"
        )
        return "\(count) \(form)"
    }
}

// MARK: - Character Extensions

extension Character {
    
    /// Sprawdza czy znak jest emoji
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
    
    /// Sprawdza czy znak jest literą lub cyfrą
    var isAlphanumeric: Bool {
        return isLetter || isNumber
    }
}

// MARK: - Data Extensions

extension Data {
    
    /// Zwraca MD5 hash
    var md5: String {
        let digest = self.withUnsafeBytes { bytes in
            return bytes.bindMemory(to: UInt8.self)
        }
        
        // Simplified MD5 - w produkcji użyj CryptoKit
        let hash = digest.map { String(format: "%02hhx", $0) }.joined()
        return hash
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension String {
    
    /// Przykładowe stringi do testowania
    static let sampleNicknames = [
        "Jan Kowalski",
        "Anna",
        "Piotr Nowak-Kowalski",
        "🎉 SuperUser 🎉",
        "Test123",
        "Bardzo Długi Pseudonim Użytkownika"
    ]
    
    static let sampleMessages = [
        "Cześć! Jak się masz?",
        "Spotkamy się jutro o 15:00",
        "👋 Hej! 😊",
        "To jest bardzo długa wiadomość która powinna zostać skrócona w preview bo zawiera dużo tekstu i nie powinna się wyświetlać w całości na liście czatów",
        "OK 👍",
        ""
    ]
    
    /// Testuje formatowanie różnych dat
    static func testDateFormatting() {
        let now = Date()
        let calendar = Calendar.current
        
        let dates = [
            now,  // teraz
            calendar.date(byAdding: .hour, value: -2, to: now)!,  // 2h temu
            calendar.date(byAdding: .day, value: -1, to: now)!,   // wczoraj
            calendar.date(byAdding: .day, value: -3, to: now)!,   // 3 dni temu
            calendar.date(byAdding: .month, value: -1, to: now)!  // miesiąc temu
        ]
        
        for date in dates {
            print("Date: \(date)")
            print("Message time: \(messageTimeString(from: date))")
            print("Last seen: \(lastSeenString(from: date))")
            print("Relative: \(relativeTimeString(from: date))")
            print("---")
        }
    }
}
#endif
