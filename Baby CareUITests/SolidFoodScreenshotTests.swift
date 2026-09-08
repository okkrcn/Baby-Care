import XCTest

/// Ek gıda ekranlarının görsel doğrulaması.
///
/// Birim testleri UI'ı kapsamıyor; bu test ekranların gerçekten açıldığını
/// ve beklenen öğeleri gösterdiğini doğrular, ayrıca ekran görüntülerini
/// test raporuna ekler.
///
/// Ön koşul: simülatörde 6 ayını doldurmuş bir bebek kayıtlı olmalı.
final class SolidFoodScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        dismissSystemAlertIfPresent()
    }

    /// Bildirim izni gibi sistem uyarılarını kapatır.
    private func dismissSystemAlertIfPresent() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["İzin Verme", "Don't Allow", "İzin Ver", "Allow"] {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 2) {
                button.tap()
                return
            }
        }
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testSolidFoodSurfacesAreReachable() throws {
        // 1) Ana sayfa — ek gıda kartı 6 ay ve üzeri bebekte görünür
        XCTAssertTrue(app.staticTexts["Ana Sayfa"].waitForExistence(timeout: 10),
                      "Ana sayfa açılmadı")
        attach("01-ana-sayfa")

        let solidCard = app.staticTexts["Ek Gıda"]
        XCTAssertTrue(solidCard.waitForExistence(timeout: 5),
                      "Ana sayfada Ek Gıda kartı yok")

        // 2) Takip sekmesi — dördüncü özet kartı ve hızlı ekleme
        app.tabBars.buttons["Takip"].tap()
        XCTAssertTrue(app.staticTexts["Takip"].waitForExistence(timeout: 5))
        attach("02-takip-ek-gida-karti")

        // 3) Ek Gıda ekranı — Ana sayfadaki karttan
        app.tabBars.buttons["Ana"].tap()
        app.staticTexts["Ek Gıda"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Rehber"].waitForExistence(timeout: 5),
                      "Ek Gıda ekranı açılmadı")
        attach("03-ek-gida-rehber")

        // 4) Besin kütüphanesi — liste lazy olduğu için aramayla daraltıyoruz
        app.buttons["Besinler"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Arama alanı yok")
        search.tap()
        search.typeText("Kırmızı")

        let beef = app.staticTexts["Kırmızı et (dana)"]
        XCTAssertTrue(beef.waitForExistence(timeout: 5),
                      "Besin kütüphanesinde arama sonucu çıkmadı")
        attach("04-besin-kutuphanesi")

        // 5) Besin kartı — üç sunum biçimi
        beef.tap()
        XCTAssertTrue(app.staticTexts["Nasıl verilir"].waitForExistence(timeout: 5),
                      "Besin kartı açılmadı")
        attach("05-besin-karti")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // 6) Alerjen paneli
        app.buttons["Alerjenler"].tap()
        XCTAssertTrue(app.staticTexts["Yumurta"].waitForExistence(timeout: 5),
                      "Alerjen paneli yüklenmedi")
        attach("06-alerjen-paneli")
    }
}
