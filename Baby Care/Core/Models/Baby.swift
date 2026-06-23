import Foundation
import SwiftData

enum BabySex: String, Codable, CaseIterable, Sendable {
    case female
    case male
    case unspecified

    var localizedTitle: String {
        switch self {
        case .female:      return "Kız"
        case .male:        return "Erkek"
        case .unspecified: return "Belirtilmedi"
        }
    }
}

@Model
final class Baby {
    @Attribute(.unique) var id: UUID
    var name: String
    var birthDate: Date
    var birthTime: Date?
    var birthWeightGrams: Int?
    var birthLengthCm: Double?
    var sexRaw: String
    var photoURL: String?
    var createdAt: Date
    var updatedAt: Date

    var sex: BabySex {
        get { BabySex(rawValue: sexRaw) ?? .unspecified }
        set { sexRaw = newValue.rawValue }
    }

    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: birthDate, to: .now).day ?? 0
    }

    var ageInWeeks: Int { ageInDays / 7 }

    var ageInMonths: Int {
        Calendar.current.dateComponents([.month], from: birthDate, to: .now).month ?? 0
    }

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        birthTime: Date? = nil,
        birthWeightGrams: Int? = nil,
        birthLengthCm: Double? = nil,
        sex: BabySex = .unspecified,
        photoURL: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthWeightGrams = birthWeightGrams
        self.birthLengthCm = birthLengthCm
        self.sexRaw = sex.rawValue
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
