import Foundation
import SwiftData

enum SolidFoodMethod: String, Codable, CaseIterable, Sendable {
    case puree        // geleneksel püre / ezme
    case fingerFood   // parmak besin (bebek liderliğinde beslenme)
    case familyMeal   // aile yemeğinden doğranmış

    var localizedTitle: String {
        switch self {
        case .puree:      return "Püre / ezme"
        case .fingerFood: return "Parmak besin"
        case .familyMeal: return "Aile yemeği"
        }
    }

    var icon: String {
        switch self {
        case .puree:      return "circle.fill"
        case .fingerFood: return "hand.raised.fingers.spread.fill"
        case .familyMeal: return "fork.knife"
        }
    }
}

/// Öğünün ne kadarının yendiği. 6-24 ay aralığında ebeveyn ml ölçmediği
/// için oransal ölçek kullanılır.
enum SolidFoodAmount: String, Codable, CaseIterable, Sendable {
    case tasted, some, most, all

    var localizedTitle: String {
        switch self {
        case .tasted: return "Tattı"
        case .some:   return "Bir kısmını yedi"
        case .most:   return "Çoğunu yedi"
        case .all:    return "Hepsini bitirdi"
        }
    }
}

enum SolidFoodReaction: String, Codable, CaseIterable, Sendable {
    case loved, neutral, refused, adverse

    var localizedTitle: String {
        switch self {
        case .loved:   return "Sevdi"
        case .neutral: return "Kararsız"
        case .refused: return "Reddetti"
        case .adverse: return "Olumsuz tepki"
        }
    }

    var icon: String {
        switch self {
        case .loved:   return "heart.fill"
        case .neutral: return "minus.circle.fill"
        case .refused: return "xmark.circle.fill"
        case .adverse: return "exclamationmark.triangle.fill"
        }
    }
}

@Model
final class SolidFoodRecord {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var servedAt: Date
    var foodIDs: [String]
    var customFoodName: String?
    var methodRaw: String
    var amountRaw: String
    var reactionRaw: String
    var isFirstTry: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var method: SolidFoodMethod {
        get { SolidFoodMethod(rawValue: methodRaw) ?? .puree }
        set { methodRaw = newValue.rawValue }
    }

    var amount: SolidFoodAmount {
        get { SolidFoodAmount(rawValue: amountRaw) ?? .some }
        set { amountRaw = newValue.rawValue }
    }

    var reaction: SolidFoodReaction {
        get { SolidFoodReaction(rawValue: reactionRaw) ?? .neutral }
        set { reactionRaw = newValue.rawValue }
    }

    /// Kayıtta yer alan katalog besinleri (bilinmeyen id'ler atlanır).
    var foods: [FoodItem] {
        foodIDs.compactMap { FoodCatalog.item(id: $0) }
    }

    /// Listelerde gösterilecek özet ad.
    var displayName: String {
        var names = foods.map(\.name)
        if let custom = customFoodName, !custom.isEmpty {
            names.append(custom)
        }
        return names.isEmpty ? "Besin belirtilmedi" : names.joined(separator: ", ")
    }

    init(
        id: UUID = UUID(),
        babyID: UUID,
        servedAt: Date = .now,
        foodIDs: [String],
        customFoodName: String? = nil,
        method: SolidFoodMethod = .puree,
        amount: SolidFoodAmount = .some,
        reaction: SolidFoodReaction = .neutral,
        isFirstTry: Bool = false,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.servedAt = servedAt
        self.foodIDs = foodIDs
        self.customFoodName = customFoodName
        self.methodRaw = method.rawValue
        self.amountRaw = amount.rawValue
        self.reactionRaw = reaction.rawValue
        self.isFirstTry = isFirstTry
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Takip ekranındaki günlük ek gıda özet kartının verisi.
struct SolidFoodDaySummary: Sendable {
    let mealCount: Int
    let firstTryCount: Int

    var detailText: String {
        if mealCount == 0 { return "—" }
        return firstTryCount > 0 ? "\(firstTryCount) yeni besin" : "yeni besin yok"
    }

    static func make(from records: [SolidFoodRecord]) -> SolidFoodDaySummary {
        SolidFoodDaySummary(
            mealCount: records.count,
            firstTryCount: records.filter(\.isFirstTry).count
        )
    }
}
