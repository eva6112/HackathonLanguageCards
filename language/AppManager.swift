import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable                     //работать в главном потоке и перерисовка
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
                advanceStage(for: card)             //либо новая дата либо лернд
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
            card.penaltyStep = 1                                //при неправильном - всегда 1
            card.nextReview = Date().addingTimeInterval(300)
        }
    }
    
    //метод продвижения по стадиям обучения
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

    //получение следующей карточки из списка
    func getNextCard(from cards: [WordCard]) -> (card: WordCard, type: CardType)? {
        let now = Date()
        
        //карточки ручного просмотра, у которых дата просмотра прошла
        let manualCards = cards
            .filter { $0.isManualReview && $0.nextReview <= now }
            .sorted { $0.nextReview < $1.nextReview }
        
        if let first = manualCards.first {
            return (first, Bool.random() ? .rotationEngToRus : .rotationRusToEng)
        }
        
        //просроченные карточки, которые в ротации и не выучены
        let dueCards = cards
            .filter { $0.inRotation && !$0.isLearned && $0.nextReview <= now }
            .sorted { $0.nextReview < $1.nextReview }
        
        if let first = dueCards.first {
            return (first, Bool.random() ? .rotationEngToRus : .rotationRusToEng)
        }
        
        let newCards = cards.filter {
            !$0.inRotation &&
            !$0.isLearned &&
            !$0.isSkipped
        }
        
        //возвращается с типом нового слова
        if let first = newCards.first {
            return (first, .newWord)
        }
        
        return nil
    }

    //синхронизация словаря
    func syncDictionary(context: ModelContext) async {
        guard let url = URL(string: "https://gist.githubusercontent.com/eva6112/fd369da8b96dcb351516f07e6ceeb8c9/raw/dictionary.json") else { return }
        do {
            //создание гет-запроса - настраивать и отправлять
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            let (data, _) = try await URLSession.shared.data(for: request)                      //загружаем данные (Data, URLResponse)
            let downloadedWords = try JSONDecoder().decode([DictionaryWord].self, from: data)   //получаем массив структур
            
            let descriptor = FetchDescriptor<WordCard>()                        //шаблон запроса к бд
            let existingCards = (try? context.fetch(descriptor)) ?? []          //получаем карточки
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
