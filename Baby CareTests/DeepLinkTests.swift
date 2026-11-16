import Testing
import Foundation
@testable import Baby_Care

struct DeepLinkTests {
    private func link(_ s: String) -> DeepLink? { DeepLink(url: URL(string: s)!) }

    @Test func knownTabs() {
        #expect(link("babycare://takip") == .tab(.tracking))
        #expect(link("babycare://bebek") == .tab(.baby))
        #expect(link("babycare://asi") == .tab(.vaccination))
        #expect(link("babycare://ayarlar") == .tab(.settings))
    }

    @Test func teethOpensBabyTab() {
        #expect(link("babycare://dis") == .teeth)
        #expect(link("babycare://dis")?.tab == .baby)
        #expect(link("babycare:///dis") == .teeth)
    }

    @Test func unknownPathFallsBackToHome() {
        #expect(link("babycare://") == .tab(.home))
        #expect(link("babycare://bilinmeyen/yol") == .tab(.home))
        #expect(link("babycare://ana") == .tab(.home))
    }

    @Test func otherSchemesAreIgnored() {
        #expect(link("https://okkrcn.github.io/Baby-Care/") == nil)
    }
}
