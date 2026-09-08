import Foundation
import SwiftData

/// Katı gıda kaydı ve buna bağlı alerjen durumu güncellemesi.
///
/// Alerjen durumu view'da değil burada ilerler: kayıt eklendiğinde
/// besinin alerjen bayrağı okunur ve ilgili `AllergenIntroduction`
/// güncellenir.
@MainActor
enum SolidFoodService {

    @discardableResult
    static func log(
        foodIDs: [String],
        customName: String? = nil,
        method: SolidFoodMethod,
        amount: SolidFoodAmount,
        reaction: SolidFoodReaction,
        servedAt: Date = .now,
        notes: String? = nil,
        for baby: Baby,
        in context: ModelContext
    ) throws -> SolidFoodRecord {
        let firstTry = foodIDs.contains { isFirstTry(foodID: $0, babyID: baby.id, in: context) }

        let record = SolidFoodRecord(
            babyID: baby.id,
            servedAt: servedAt,
            foodIDs: foodIDs,
            customFoodName: customName,
            method: method,
            amount: amount,
            reaction: reaction,
            isFirstTry: firstTry,
            notes: notes
        )
        context.insert(record)

        updateAllergenStatus(
            foodIDs: foodIDs, reaction: reaction, servedAt: servedAt,
            babyID: baby.id, in: context
        )

        try context.save()
        return record
    }

    /// Bu besin bu bebeğe daha önce verilmiş mi.
    static func isFirstTry(foodID: String, babyID: UUID, in context: ModelContext) -> Bool {
        let targetID = babyID
        let descriptor = FetchDescriptor<SolidFoodRecord>(
            predicate: #Predicate { $0.babyID == targetID }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        return !existing.contains { $0.foodIDs.contains(foodID) }
    }

    /// Bebeğin dokuz alerjen kaydını döner; eksik olanları oluşturur.
    static func introductions(for babyID: UUID, in context: ModelContext) -> [AllergenIntroduction] {
        let targetID = babyID
        let descriptor = FetchDescriptor<AllergenIntroduction>(
            predicate: #Predicate { $0.babyID == targetID }
        )
        var records = (try? context.fetch(descriptor)) ?? []
        let present = Set(records.map(\.allergen))
        let missing = Allergen.allCases.filter { !present.contains($0) }

        for allergen in missing {
            let intro = AllergenIntroduction(babyID: babyID, allergen: allergen)
            context.insert(intro)
            records.append(intro)
        }
        if !missing.isEmpty { try? context.save() }

        return records.sorted {
            let lhs = Allergen.allCases.firstIndex(of: $0.allergen) ?? 0
            let rhs = Allergen.allCases.firstIndex(of: $1.allergen) ?? 0
            return lhs < rhs
        }
    }

    // MARK: - Private

    private static func updateAllergenStatus(
        foodIDs: [String],
        reaction: SolidFoodReaction,
        servedAt: Date,
        babyID: UUID,
        in context: ModelContext
    ) {
        let allergens = Set(foodIDs.compactMap { FoodCatalog.item(id: $0)?.allergen })
        guard !allergens.isEmpty else { return }

        let all = introductions(for: babyID, in: context)

        for allergen in allergens {
            guard let intro = all.first(where: { $0.allergen == allergen }) else { continue }

            if reaction == .adverse {
                intro.status = .reacted
                intro.firstTriedAt = intro.firstTriedAt ?? servedAt
                intro.lastServedAt = servedAt
                intro.updatedAt = .now
                continue
            }

            // Tepki gözlenmiş alerjen kendiliğinden "sorunsuz"a dönmez —
            // bu karar hekimindir.
            if intro.status == .reacted { continue }

            // Reddedilen öğün besin alınmadığı anlamına gelir; durumu ilerletmez.
            guard reaction != .refused else { continue }

            switch intro.status {
            case .notIntroduced:
                intro.status = .introduced
                intro.firstTriedAt = servedAt
            case .introduced:
                intro.status = .tolerated
            case .tolerated, .reacted:
                break
            }
            intro.lastServedAt = servedAt
            intro.updatedAt = .now
        }
    }
}
