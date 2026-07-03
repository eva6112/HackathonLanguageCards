import Foundation
import SwiftData

@Model
class WordCard {
    var id: UUID
    var english: String
    var russian: String
    var transcription: String
    var usageExample: String
    var stage: Int
    var penaltyStep: Int
    var nextReview: Date
    var isLearned: Bool
    var inRotation: Bool
    var isSkipped: Bool
    var isManualReview: Bool
    var learnedDate: Date?

    init(english: String, russian: String, transcription: String, usageExample: String = "") {
        self.id = UUID()
        self.english = english
        self.russian = russian
        self.transcription = transcription
        self.usageExample = usageExample
        self.stage = 0
        self.penaltyStep = 0
        self.nextReview = Date()
        self.isLearned = false
        self.inRotation = false
        self.isSkipped = false
        self.isManualReview = false
    }
}

enum CardType {
    case newWord
    case rotationEngToRus
    case rotationRusToEng
}

struct DictionaryWord: Codable {
    let en: String
    let ru: String
    let tr: String
    let ex: String?
}
