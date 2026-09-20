import Testing
import Foundation
@testable import Baby_Care

struct SolidFoodAssistantTests {

    private let babyID = UUID()

    private func record(_ foods: [String], daysAgo: Int = 0, method: SolidFoodMethod = .puree) -> SolidFoodRecord {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        return SolidFoodRecord(babyID: babyID, servedAt: date, foodIDs: foods, method: method)
    }

    private func intro(_ allergen: Allergen, _ status: AllergenStatus) -> AllergenIntroduction {
        AllergenIntroduction(babyID: babyID, allergen: allergen, status: status)
    }

    @Test func contextCollectsTriedAndRecentFoods() {
        let context = AssistantContext.make(
            ageMonths: 8,
            solids: [record(["carrot"], daysAgo: 20), record(["apple", "carrot"], daysAgo: 2)],
            introductions: []
        )
        #expect(context.stage == .complementary)
        #expect(Set(context.triedFoodNames) == ["Havuç (pişmiş)", "Elma"])
        #expect(Set(context.recentFoodNames) == ["Havuç (pişmiş)", "Elma"])
        #expect(context.triedFoodNames.count == 2, "aynı besin iki kez sayılmaz")
    }

    @Test func contextGroupsAllergensByStatus() {
        let context = AssistantContext.make(
            ageMonths: 7,
            solids: [],
            introductions: [intro(.egg, .reacted), intro(.milk, .tolerated), intro(.peanut, .introduced), intro(.wheat, .notIntroduced)]
        )
        #expect(context.reactedAllergens == [.egg])
        #expect(context.toleratedAllergens == [.milk])
        #expect(context.introducedAllergens == [.peanut])
        #expect(context.notIntroducedAllergens == [.wheat])
    }

    @Test func barredFoodsFollowAge() {
        let seven = AssistantContext.make(ageMonths: 7, solids: [], introductions: [])
        #expect(seven.barredFoods.contains { $0.name == "Bal" })
        #expect(!seven.ageAppropriateFoodNames.contains("Bal"))

        let fourteen = AssistantContext.make(ageMonths: 14, solids: [], introductions: [])
        #expect(!fourteen.barredFoods.contains { $0.name == "Bal" })
        #expect(fourteen.barredFoods.contains { $0.name == "İlave şeker" })
    }

    @Test func preferredMethodIsMostFrequent() {
        let context = AssistantContext.make(
            ageMonths: 9,
            solids: [record(["carrot"], method: .fingerFood), record(["apple"], method: .fingerFood), record(["pear"], method: .puree)],
            introductions: []
        )
        #expect(context.preferredMethod == .fingerFood)
    }

    @Test func systemPromptCarriesSafetyRulesAndContext() {
        let context = AssistantContext.make(
            ageMonths: 7,
            solids: [record(["yogurt"])],
            introductions: [intro(.egg, .reacted)]
        )
        let prompt = SolidFoodAssistant.systemPrompt(for: context)

        #expect(prompt.contains("112"))
        #expect(prompt.contains("Tanı koyma"))
        #expect(prompt.contains("TEPKİ GÖZLENDİ (önerme): Yumurta"))
        #expect(prompt.contains("Yaş: 7 ay"))
        #expect(prompt.contains("Bal"))
        #expect(prompt.contains("Yoğurt"))
    }

    @Test func systemPromptNeverContainsIdentity() {
        // Bağlam yapısında ad alanı yoktur; bu test alan eklenirse kırılsın diye var.
        let context = AssistantContext.make(ageMonths: 10, solids: [], introductions: [])
        let mirror = Mirror(reflecting: context)
        let labels = mirror.children.compactMap(\.label)
        #expect(!labels.contains("name"))
        #expect(!labels.contains("birthDate"))
        #expect(!labels.contains("photoURL"))
    }

    @Test func messagesTrimHistoryAndAppendQuestion() {
        let context = AssistantContext.make(ageMonths: 8, solids: [], introductions: [])
        let history = (0..<20).map { ChatMessage.user("m\($0)") }
        let messages = SolidFoodAssistant.messages(context: context, history: history, question: "  soru  ", historyLimit: 4)

        #expect(messages.count == 6)
        #expect(messages.first?.role == .system)
        #expect(messages[1].content == "m16")
        #expect(messages.last == .user("soru"))
    }

    @Test func suggestedQuestionsFitStage() {
        let fresh = AssistantContext.make(ageMonths: 6, solids: [], introductions: [intro(.egg, .notIntroduced)])
        let questions = SolidFoodAssistant.suggestedQuestions(for: fresh)
        #expect(questions.first == "Ek gıdaya hangi besinlerle başlayabilirim?")
        #expect(questions.contains("Yumurta tanıtımına nasıl başlarım?"))
        #expect(questions.count <= 4)

        let toddler = AssistantContext.make(ageMonths: 15, solids: [record(["beef"])], introductions: [])
        #expect(SolidFoodAssistant.suggestedQuestions(for: toddler).contains("Yemek reddediyor, ne yapabilirim?"))
    }
}
