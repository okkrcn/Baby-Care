import Foundation

/// Modele gönderilen, kimlik içermeyen bebek özeti.
///
/// Bebeğin adı, doğum tarihi, fotoğrafı ve ölçümleri **gönderilmez**.
/// Yalnız ay cinsinden yaş, denenen besinler ve alerjen durumları gider —
/// bunlar asistanın yaşa uygun ve güvenli öneri vermesi için gereken
/// asgari bilgidir. Gizlilik politikasındaki "Yapay Zeka Asistanı"
/// bölümü bu yapıyı tarif eder; alan eklerken orayı da güncelleyin.
struct AssistantContext: Sendable, Equatable {
    struct BarredFood: Sendable, Equatable {
        let name: String
        let minAgeMonths: Int
    }

    let ageMonths: Int
    let stage: BabyStage
    /// Bebeğin en az bir kez tattığı katalog besinleri (ad olarak).
    let triedFoodNames: [String]
    /// Son 7 günde verilen besinler — tekrarı azaltmak için.
    let recentFoodNames: [String]
    let toleratedAllergens: [Allergen]
    let introducedAllergens: [Allergen]
    let reactedAllergens: [Allergen]
    let notIntroducedAllergens: [Allergen]
    /// Bu yaşta verilmemesi gereken besinler (ad + neden).
    let barredFoods: [BarredFood]
    /// Yaşa uygun katalog besinleri — modelin öneri havuzu.
    let ageAppropriateFoodNames: [String]
    let ironRichFoodNames: [String]
    /// Ebeveynin sık kullandığı sunum biçimi (son kayıtlardan).
    let preferredMethod: SolidFoodMethod?


    /// Kayıtlardan bağlam üretir. SwiftData'ya bağımlı değildir; testlerde
    /// doğrudan dizi verilir.
    static func make(
        ageMonths: Int,
        solids: [SolidFoodRecord],
        introductions: [AllergenIntroduction],
        now: Date = .now
    ) -> AssistantContext {
        let catalogFoods = solids.flatMap(\.foods)
        let tried = uniqueNames(catalogFoods)

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let recent = uniqueNames(solids.filter { $0.servedAt >= weekAgo }.flatMap(\.foods))

        func allergens(_ status: AllergenStatus) -> [Allergen] {
            introductions
                .filter { $0.status == status }
                .map(\.allergen)
                .sorted { (Allergen.allCases.firstIndex(of: $0) ?? 0) < (Allergen.allCases.firstIndex(of: $1) ?? 0) }
        }

        let appropriate = FoodCatalog.items(forAgeMonths: ageMonths)
        let barred = FoodCatalog.all.compactMap { item -> BarredFood? in
            guard let barrier = item.ageBarrier, ageMonths < barrier.minAgeMonths else { return nil }
            return BarredFood(name: item.name, minAgeMonths: barrier.minAgeMonths)
        }

        let methodCounts = Dictionary(grouping: solids.prefix(20), by: \.method).mapValues(\.count)
        let preferred = methodCounts.max { $0.value < $1.value }?.key

        return AssistantContext(
            ageMonths: ageMonths,
            stage: BabyStage.forAgeMonths(ageMonths),
            triedFoodNames: tried,
            recentFoodNames: recent,
            toleratedAllergens: allergens(.tolerated),
            introducedAllergens: allergens(.introduced),
            reactedAllergens: allergens(.reacted),
            notIntroducedAllergens: allergens(.notIntroduced),
            barredFoods: barred,
            ageAppropriateFoodNames: appropriate.map(\.name),
            ironRichFoodNames: appropriate.filter(\.isIronRich).map(\.name),
            preferredMethod: preferred
        )
    }

    private static func uniqueNames(_ items: [FoodItem]) -> [String] {
        var seen = Set<String>()
        return items.compactMap { seen.insert($0.id).inserted ? $0.name : nil }
    }
}

/// Ek gıda asistanının istem üretimi ve güvenlik çerçevesi.
///
/// Tıbbi sınır uygulamanın geri kalanıyla aynıdır: tanı yok, doz yok,
/// alerji protokolü yok. Model yalnız uygulamadaki kataloğa dayanarak
/// öneri verir; katalog dışı besinleri "kayıt yok" diyerek reddeder.
enum SolidFoodAssistant {

    static let disclaimer = "Yapay zeka yanıtları bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz. Acil durumda 112'yi arayın."

    static func systemPrompt(for context: AssistantContext) -> String {
        var lines: [String] = []

        lines.append("""
        Sen Baby Care uygulamasının ek gıda (tamamlayıcı beslenme) asistanısın. \
        Türkçe, sıcak ama kısa ve net yanıt ver. Ebeveynle konuşuyorsun; bebeğin adını bilmiyorsun ve sorma.
        """)

        lines.append("""
        KURALLAR:
        1. Tanı koyma, ilaç veya doz önerme, alerji tanıtım protokolü yürütme. Bu sorularda kısaca pediatriste yönlendir.
        2. Boğulma, nefes darlığı, dudak/yüz şişmesi, yaygın kurdeşen, kusma ile birlikte solukluk gibi belirtiler anlatılırsa ilk cümlede 112'yi aramasını söyle; başka öneri verme.
        3. Yalnız aşağıdaki "yaşa uygun besinler" listesinden öneri yap. Listede olmayan bir besin sorulursa uygulamada kaydı olmadığını söyle ve genel ihtiyatlı bilgi ver.
        4. "Bu yaşta verilmez" listesindeki besinleri asla önerme; sorulursa nedenini ve hangi aydan itibaren verilebileceğini söyle.
        5. Tepki gözlenen alerjenleri içeren besinleri önerme; hekim değerlendirmesi olmadan evde tekrar denenmediğini hatırlat.
        6. Bal 12 aydan önce verilmez (infantil botulizm). Tuz ilk yıl eklenmez. İlave şeker 2 yaşa kadar verilmez. İnek sütü 1 yaşından önce ana içecek olmaz.
        7. Yuvarlak, sert, kaygan besinlerde (üzüm, çeri domates, çiğ havuç, fındık, sosis) güvenli hazırlama biçimini mutlaka yaz.
        8. Bütün fındık, yer fıstığı ve koyu ezmeler boğulma tehlikesidir; ezmeleri inceltilmiş öner.
        9. Anne sütü veya mama 2 yaşa kadar sürer; ek gıda süt beslenmesinin yerini almaz.
        10. Günlük demir kaynağını (kırmızı et, tavuk, balık, yumurta, baklagil) hatırlat; bitkisel demiri C vitaminli besinle eşleştir.
        11. Kesin olmadığın şeyde kısaca "emin değilim, pediatriste sorun" de. Uydurma kaynak verme.
        12. Yanıtı en fazla 6–8 cümle veya kısa bir madde listesi olarak tut. Markdown başlık kullanma.
        """)

        lines.append("BEBEK BİLGİSİ (kimlik yok):")
        lines.append("- Yaş: \(context.ageMonths) ay (\(context.stage.localizedTitle))")
        if let method = context.preferredMethod {
            lines.append("- Ebeveynin sık kullandığı sunum biçimi: \(method.localizedTitle)")
        }
        lines.append("- Daha önce denenen besinler: \(list(context.triedFoodNames, empty: "henüz yok"))")
        lines.append("- Son 7 günde verilenler: \(list(context.recentFoodNames, empty: "yok"))")
        lines.append("- Alerjenler — sorunsuz: \(list(context.toleratedAllergens.map(\.localizedTitle), empty: "yok"))")
        lines.append("- Alerjenler — tanıtıldı, tekrar bekliyor: \(list(context.introducedAllergens.map(\.localizedTitle), empty: "yok"))")
        lines.append("- Alerjenler — TEPKİ GÖZLENDİ (önerme): \(list(context.reactedAllergens.map(\.localizedTitle), empty: "yok"))")
        lines.append("- Alerjenler — henüz tanıtılmadı: \(list(context.notIntroducedAllergens.map(\.localizedTitle), empty: "yok"))")

        lines.append("BU YAŞTA VERİLMEZ: " + list(
            context.barredFoods.map { "\($0.name) (\($0.minAgeMonths) aydan itibaren)" },
            empty: "kısıt yok"
        ))
        lines.append("DEMİRDEN ZENGİN (yaşa uygun): " + list(context.ironRichFoodNames, empty: "—"))
        lines.append("YAŞA UYGUN BESİNLER: " + list(context.ageAppropriateFoodNames, empty: "—"))

        return lines.joined(separator: "\n\n")
    }

    /// Ebeveynin tek dokunuşla sorabileceği örnek sorular.
    static func suggestedQuestions(for context: AssistantContext) -> [String] {
        var questions: [String] = []

        if context.triedFoodNames.isEmpty {
            questions.append("Ek gıdaya hangi besinlerle başlayabilirim?")
        } else {
            questions.append("Denediklerimize göre bugün ne verebilirim?")
        }

        if !context.notIntroducedAllergens.isEmpty {
            let next = context.notIntroducedAllergens[0].localizedTitle
            questions.append("\(next) tanıtımına nasıl başlarım?")
        }

        if !context.introducedAllergens.isEmpty {
            questions.append("Tanıttığım alerjenleri ne sıklıkla tekrar vermeliyim?")
        }

        switch context.stage {
        case .newborn:
            questions.append("Ek gıdaya hazır olduğunu nasıl anlarım?")
        case .complementary:
            questions.append("Demir açısından zengin bir öğün önerir misin?")
            questions.append("Parmak besine ne zaman geçebiliriz?")
        case .toddler:
            questions.append("Aile yemeğinden neyi nasıl paylaşabiliriz?")
            questions.append("Yemek reddediyor, ne yapabilirim?")
        }

        return Array(questions.prefix(4))
    }

    /// Model isteği için mesaj dizisini kurar. Geçmiş, bağlam penceresini
    /// aşmamak için son `historyLimit` mesajla sınırlanır.
    static func messages(
        context: AssistantContext,
        history: [ChatMessage],
        question: String,
        historyLimit: Int = 10
    ) -> [ChatMessage] {
        var result: [ChatMessage] = [.system(systemPrompt(for: context))]
        result.append(contentsOf: history.suffix(historyLimit))
        result.append(.user(question.trimmingCharacters(in: .whitespacesAndNewlines)))
        return result
    }

    private static func list(_ items: [String], empty: String) -> String {
        items.isEmpty ? empty : items.joined(separator: ", ")
    }
}
