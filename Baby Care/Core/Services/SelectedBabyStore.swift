import Foundation
import Observation

/// Birden fazla bebek olduğunda kullanıcının seçili bebeğini hatırlar.
/// UserDefaults'ta saklanır. Tek bebek varsa otomatik o seçilir.
@MainActor
@Observable
final class SelectedBabyStore {
    private static let storageKey = "selectedBabyID"

    private(set) var selectedID: UUID?

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let id = UUID(uuidString: raw) {
            selectedID = id
        }
    }

    func select(_ baby: Baby) {
        selectedID = baby.id
        UserDefaults.standard.set(baby.id.uuidString, forKey: Self.storageKey)
    }

    func selectByID(_ id: UUID) {
        selectedID = id
        UserDefaults.standard.set(id.uuidString, forKey: Self.storageKey)
    }

    func clearIfMissing(in babies: [Baby]) {
        guard let id = selectedID else { return }
        if !babies.contains(where: { $0.id == id }) {
            selectedID = nil
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        }
    }

    /// Seçili bebek bulunamazsa ilk bebeği döner; hiç bebek yoksa nil.
    func resolved(from babies: [Baby]) -> Baby? {
        if let id = selectedID, let match = babies.first(where: { $0.id == id }) {
            return match
        }
        return babies.first
    }
}
