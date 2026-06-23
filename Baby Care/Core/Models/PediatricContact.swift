import Foundation
import SwiftData

/// Kullanıcının kaydettiği pediatrist/aile sağlığı merkezi iletişim bilgisi.
@Model
final class PediatricContact {
    @Attribute(.unique) var id: UUID
    var name: String
    var phone: String?
    var address: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        phone: String? = nil,
        address: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.address = address
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
