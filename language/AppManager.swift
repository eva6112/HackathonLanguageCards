import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class AppManager {
    let intervals: [TimeInterval] = [300, 3600, 86400, 604800, 2592000, 7776000]

    func processRightSwipe(for card: WordCard) {
        if card.isManualReview {
            card.isManualReview = false
            return
        }
        if card.stage == 0 {
            card.isSkipped = true
            markAsLearned(card: card)
        } else {
            if card.penaltyStep == 1 {
                card.penaltyStep = 2
                card.nextReview = Date().addingTimeInterval(3600)
            } else if card.penaltyStep == 2 {
                card.penaltyStep = 0
                card.stage += 1
                advanceStage(for: card)
            } else {
                card.stage += 1
                advanceStage(for: card)
            }
        }
    }

    func processLeftSwipe(for card: WordCard) {
        if card.isManualReview {
            card.nextReview = Date().addingTimeInterval(300)
            return
        }
        if card.stage == 0 {
            card.inRotation = true
            card.stage = 1
            card.nextReview = Date().addingTimeInterval(intervals[0])
        } else {
            card.penaltyStep = 1
            card.nextReview = Date().addingTimeInterval(300)
        }
    }
    
    private func advanceStage(for card: WordCard) {
        if card.stage > 6 {
            markAsLearned(card: card)
        } else {
            card.nextReview = Date().addingTimeInterval(intervals[card.stage - 1])
        }
    }

    private func markAsLearned(card: WordCard) {
        card.isLearned = true
        card.inRotation = false
        card.learnedDate = Date()
    }

    func getNextCard(from cards: [WordCard]) -> (card: WordCard, type: CardType)? {
        let now = Date()
        let manualCards = cards.filter { $0.isManualReview && $0.nextReview <= now }.sorted { $0.nextReview < $1.nextReview }
        if let first = manualCards.first { return (first, Bool.random() ? .rotationEngToRus : .rotationRusToEng) }
        
        let dueCards = cards.filter { $0.inRotation && !$0.isLearned && $0.nextReview <= now }.sorted { $0.nextReview < $1.nextReview }
        if let first = dueCards.first { return (first, Bool.random() ? .rotationEngToRus : .rotationRusToEng) }
        
        let newCards = cards.filter { !$0.inRotation && !$0.isLearned && !$0.isSkipped }
        if let first = newCards.first { return (first, .newWord) }
        
        return nil
    }

    func syncDictionary(context: ModelContext) async {
        guard let url = URL(string: "https://gist.githubusercontent.com/eva6112/fd369da8b96dcb351516f07e6ceeb8c9/raw/dictionary.json") else { return }
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let downloadedWords = try JSONDecoder().decode([DictionaryWord].self, from: data)
            
            let descriptor = FetchDescriptor<WordCard>()
            let existingCards = (try? context.fetch(descriptor)) ?? []
            let existingWords = Set(existingCards.map { $0.english })
            
            for item in downloadedWords {
                if !existingWords.contains(item.en) {
                    let example = item.ex ?? "Пример не добавлен"
                    let card = WordCard(english: item.en, russian: item.ru, transcription: item.tr, usageExample: example)
                    context.insert(card)
                }
            }
            try? context.save()
            print("Словарь успешно загружен!")
        } catch {
            print("Ошибка загрузки словаря: \(error)")
        }
    }
}
