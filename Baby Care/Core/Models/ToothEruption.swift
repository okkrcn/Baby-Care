import Foundation
import SwiftData

/// Süt dişleri kataloğu (20 diş).
///
/// Çıkış yaşları Amerikan Diş Hekimleri Birliği (ADA) "Primary Tooth
/// Development" tablosundan alınmıştır. Aralıklar tipik dönemi gösterir;
/// uygulama bu aralığa göre uyarı üretmez, yalnızca bilgi verir.
enum ToothJaw: String, CaseIterable, Sendable {
    case upper
    case lower

    var localizedTitle: String { self == .upper ? "Üst" : "Alt" }
}

/// Bebeğin kendi sağı / solu (diş hekimi şemalarındaki gibi).
enum ToothSide: String, CaseIterable, Sendable {
    case right
    case left

    var localizedTitle: String { self == .right ? "sağ" : "sol" }
}

enum ToothKind: String, CaseIterable, Sendable {
    case centralIncisor
    case lateralIncisor
    case canine
    case firstMolar
    case secondMolar

    var localizedTitle: String {
        switch self {
        case .centralIncisor: return "orta kesici"
        case .lateralIncisor: return "yan kesici"
        case .canine:         return "köpek dişi"
        case .firstMolar:     return "birinci azı"
        case .secondMolar:    return "ikinci azı"
        }
    }

    /// "Üst yan kesiciler" gibi çiftler için çoğul ad.
    var pluralTitle: String {
        switch self {
        case .centralIncisor: return "orta kesiciler"
        case .lateralIncisor: return "yan kesiciler"
        case .canine:         return "köpek dişleri"
        case .firstMolar:     return "birinci azılar"
        case .secondMolar:    return "ikinci azılar"
        }
    }

    var isMolar: Bool { self == .firstMolar || self == .secondMolar }
}

struct PrimaryTooth: Identifiable, Hashable, Sendable {
    let jaw: ToothJaw
    let side: ToothSide
    let kind: ToothKind

    /// Kalıcı kimlik: "upper.left.lateralIncisor". Yedek formatında saklanır,
    /// değiştirilmemelidir.
    var id: String { "\(jaw.rawValue).\(side.rawValue).\(kind.rawValue)" }

    /// "Üst sol yan kesici"
    var name: String { "\(jaw.localizedTitle) \(side.localizedTitle) \(kind.localizedTitle)" }

    /// ADA tablosuna göre tipik çıkış aralığı (ay).
    var typicalMonths: ClosedRange<Int> {
        switch (jaw, kind) {
        case (.upper, .centralIncisor): return 8...12
        case (.upper, .lateralIncisor): return 9...13
        case (.upper, .canine):         return 16...22
        case (.upper, .firstMolar):     return 13...19
        case (.upper, .secondMolar):    return 25...33
        case (.lower, .centralIncisor): return 6...10
        case (.lower, .lateralIncisor): return 10...16
        case (.lower, .canine):         return 17...23
        case (.lower, .firstMolar):     return 14...18
        case (.lower, .secondMolar):    return 23...31
        }
    }

    /// "genellikle 9–13 ay"
    var typicalRangeText: String {
        "genellikle \(typicalMonths.lowerBound)–\(typicalMonths.upperBound) ay"
    }

    static let all: [PrimaryTooth] = ToothJaw.allCases.flatMap { jaw in
        ToothSide.allCases.flatMap { side in
            ToothKind.allCases.map { PrimaryTooth(jaw: jaw, side: side, kind: $0) }
        }
    }

    static func with(id: String) -> PrimaryTooth? {
        all.first { $0.id == id }
    }
}

enum TeethCatalog {
    static let sourceTitle = "Amerikan Diş Hekimleri Birliği (ADA)"
    static let sourceURL = URL(string: "https://www.mouthhealthy.org/all-topics-a-z/eruption-charts")!
    static let firstVisitSourceURL = URL(string: "https://www.aapd.org/resources/parent/faq/")!
    static let teethingSafetySourceURL = URL(string: "https://www.fda.gov/consumers/consumer-updates/safely-soothing-teething-pain-infants-and-children")!

    /// Henüz çıkmamış dişler içinde tipik aralığına en yakın olanlar.
    /// Aynı aralığı paylaşan dişler (sağ/sol) tek grup olarak döner.
    static func upcoming(erupted: Set<String>, limit: Int = 2) -> [(jaw: ToothJaw, kind: ToothKind, months: ClosedRange<Int>)] {
        var seen = Set<String>()
        var groups: [(jaw: ToothJaw, kind: ToothKind, months: ClosedRange<Int>)] = []
        let pending = PrimaryTooth.all
            .filter { !erupted.contains($0.id) }
            .sorted { ($0.typicalMonths.lowerBound, $0.typicalMonths.upperBound) < ($1.typicalMonths.lowerBound, $1.typicalMonths.upperBound) }
        for tooth in pending {
            let key = "\(tooth.jaw.rawValue).\(tooth.kind.rawValue)"
            guard seen.insert(key).inserted else { continue }
            groups.append((tooth.jaw, tooth.kind, tooth.typicalMonths))
            if groups.count == limit { break }
        }
        return groups
    }

    /// Bebeğin yaşı dişin tipik aralığına girmiş ve diş henüz işaretlenmemişse.
    static func isInTypicalWindow(_ tooth: PrimaryTooth, ageInMonths: Int, erupted: Set<String>) -> Bool {
        !erupted.contains(tooth.id) && ageInMonths >= tooth.typicalMonths.lowerBound
    }
}

/// Bir bebeğin çıkmış bir süt dişi. Diş başına en fazla bir kayıt tutulur;
/// "çıktı" işareti kaldırılınca kayıt silinir.
@Model
final class ToothEruption {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    /// `PrimaryTooth.id`
    var toothID: String
    var eruptedAt: Date
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var tooth: PrimaryTooth? { PrimaryTooth.with(id: toothID) }

    init(
        id: UUID = UUID(),
        babyID: UUID,
        toothID: String,
        eruptedAt: Date = .now,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.toothID = toothID
        self.eruptedAt = eruptedAt
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
