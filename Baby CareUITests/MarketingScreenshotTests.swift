import XCTest

/// App Store pazarlama görselleri için ekran görüntüsü üretir.
///
/// Ön koşul: simülatörde 6 ayını doldurmuş, kayıt dolu bir bebek profili
/// bulunmalı ve test `-parallel-testing-enabled NO` ile çalıştırılmalı.
/// Görüntüler test raporuna eklenir; `xcresulttool export attachments`
/// ile çıkarılır.
final class MarketingScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        dismissSystemAlertIfPresent()
    }

    private func dismissSystemAlertIfPresent() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["İzin Verme", "Don't Allow"] {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 3) {
                button.tap()
                return
            }
        }
    }

    private func shoot(_ name: String) {
        // Kısa bir bekleme: animasyonlar otursun
        Thread.sleep(forTimeInterval: 0.8)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testCaptureMarketingScreens() throws {
        XCTAssertTrue(app.staticTexts["Ana Sayfa"].waitForExistence(timeout: 15))

        // 01 — Ana sayfa
        app.tabBars.buttons["Ana"].tap()
        XCTAssertTrue(app.staticTexts["Ana Sayfa"].waitForExistence(timeout: 5))
        shoot("01-ana-sayfa")

        // 02 — Takip: 2x2 özet ızgarası, ek gıda kartı dahil
        app.tabBars.buttons["Takip"].tap()
        XCTAssertTrue(app.staticTexts["Ek Gıda"].waitForExistence(timeout: 5))
        shoot("02-takip")

        // 03 — Ek gıda rehberi
        app.tabBars.buttons["Ana"].tap()
        app.staticTexts["Ek Gıda"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Rehber"].waitForExistence(timeout: 5))
        shoot("03-ek-gida-rehber")

        // 04 — Besin kütüphanesi
        app.buttons["Besinler"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        shoot("04-besinler")

        // 05 — Alerjen paneli
        app.buttons["Alerjenler"].tap()
        XCTAssertTrue(app.staticTexts["Yumurta"].waitForExistence(timeout: 5))
        shoot("05-alerjenler")

        // 06 — Büyüme grafiği
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Bebek"].tap()
        let growth = app.staticTexts["Büyüme & Ölçümler"]
        XCTAssertTrue(growth.waitForExistence(timeout: 5))
        growth.tap()
        Thread.sleep(forTimeInterval: 1.2)   // grafik animasyonu
        shoot("06-buyume")
    }
}
