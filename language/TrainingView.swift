import SwiftUI
import SwiftData

struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [WordCard]
    @State private var manager = AppManager()
    @State private var currentCard: WordCard?
    @State private var cardType: CardType = .newWord
    @State private var showTranslation = false
    @State private var showStats = false
    @State private var offset: CGSize = .zero

    var body: some View {
        NavigationStack {
            VStack {
                if let card = currentCard {
                    ZStack {
                        CardContentView(card: card, type: cardType, showTranslation: $showTranslation)      //содержимое карточки
                            .offset(x: offset.width, y: offset.height * 0.2)
                            .rotationEffect(.degrees(Double(offset.width / 20)))
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in offset = gesture.translation }
                                    .onEnded { _ in
                                        if offset.width > 120 {
                                            withAnimation(.easeOut(duration: 0.3)) { offset.width = 500 }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                handleSwipe(isRight: true, card: card)
                                            }
                                        }
                                        else if offset.width < -120 {
                                            withAnimation(.easeOut(duration: 0.3)) { offset.width = -500 }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                handleSwipe(isRight: false, card: card)
                                            }
                                        }
                                        else {
                                            withAnimation(.spring()) { offset = .zero }
                                        }
                                    }
                            )
                    }
                    .padding()
                    
                    HStack(spacing: 15) {       //горизонтальный стек
                        Button(action: {
                            withAnimation { offset.width = -500 }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {     //задержка перед обрабткой
                                handleSwipe(isRight: false, card: card)
                            }
                        }) {
                            Text(leftButtonText).font(.subheadline).bold().padding().frame(maxWidth: .infinity, minHeight: 60).background(Color.red.opacity(0.8)).foregroundColor(.white).cornerRadius(12)
                        }
                        Button(action: {
                            withAnimation { offset.width = 500 }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                handleSwipe(isRight: true, card: card)
                            }
                        }) {
                            Text(rightButtonText).font(.subheadline).bold().padding().frame(maxWidth: .infinity, minHeight: 60).background(Color.green.opacity(0.8)).foregroundColor(.white).cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                } else {
                    Text("Очередь пуста.\nДобавьте словарь в настройках.").multilineTextAlignment(.center).font(.title3).foregroundColor(.secondary)
                }
            }
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showStats = true }) { Image(systemName: "chart.bar") }
                }
            }
            .sheet(isPresented: $showStats) {
                StatsView().presentationDetents([.medium, .large])
            }
            .onAppear { loadNextCard() }
        }
    }

    private var leftButtonText: String {
        cardType == .newWord ? "Я не знал этого слова" : "Я не запомнил это слово"
    }
    private var rightButtonText: String {
        cardType == .newWord ? "Я уже знаю это слово" : "Я запомнил это слово"
    }

    private func loadNextCard() {
        offset = .zero
        showTranslation = false
        
        if let next = manager.getNextCard(from: cards) {
            currentCard = next.card
            cardType = next.type
        } else {
            currentCard = nil
        }
    }

    //метод для обработки свайпа
    private func handleSwipe(isRight: Bool, card: WordCard) {
        if isRight {
            manager.processRightSwipe(for: card)
        }
        else {
            manager.processLeftSwipe(for: card)
        }
        try? modelContext.save()
        loadNextCard()
    }
}

//структура для содержимого карточки
struct CardContentView: View {
    let card: WordCard
    let type: CardType
    @Binding var showTranslation: Bool
    
    @State private var webExample: String? = nil
    @State private var isLoadingWebExample = false

    var body: some View {
        VStack(spacing: 20) {
            if type == .rotationRusToEng {
                Text(card.russian).font(.system(size: 38, weight: .bold)).multilineTextAlignment(.center)
                
                if showTranslation {
                    Divider()
                    Text(card.english).font(.title)
                    Text(card.transcription).font(.title3).foregroundColor(.secondary)
                    
                    if !card.usageExample.isEmpty { Text(card.usageExample).font(.body).italic().padding(.top) }
                    apiExampleSection
                }
            } else {
                Text(card.english).font(.system(size: 38, weight: .bold))
                Text(card.transcription).font(.title2).foregroundColor(.secondary)
                if showTranslation {
                    Divider()
                    Text(card.russian).font(.title)
                    if !card.usageExample.isEmpty { Text(card.usageExample).font(.body).italic().padding(.top) }
                    apiExampleSection
                }
            }
            Spacer()
            
            if !showTranslation {
                Button(action: { showTranslation = true }) {
                    Label("Показать слово", systemImage: "eye").font(.headline).padding().frame(maxWidth: .infinity).background(Color.blue.opacity(0.1)).foregroundColor(.blue).cornerRadius(10)
                }
            }
        }
        .padding(24).frame(maxWidth: .infinity, minHeight: 400).background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(25).shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        
        //сбрасываем загруженный пример при смене карточки
        .onChange(of: card.english) {
            webExample = nil
        }
    }
    
    //верстка блока API
    private var apiExampleSection: some View {
        VStack {
            if let example = webExample {
                Text("Из сети: \(example)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .italic()
                    .padding(.top, 5)
            } else if isLoadingWebExample {
                ProgressView()
                    .padding(.top, 5)
            } else {
                Button(action: {
                    Task {
                        isLoadingWebExample = true
                        //дожидается ответа от сетевой функции
                        webExample = await fetchOpenLibraryExample(for: card.english)
                        isLoadingWebExample = false
                    }
                }) {
                    Text("Искать пример в открытой библиотеке")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 5)
            }
        }
    }
    
    //запрос к API с системой резервирования Fallback
    private func fetchOpenLibraryExample(for word: String) async -> String {
        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(word)") else {
            return getFallbackExample(for: word)
        }
        
        do {
            var request = URLRequest(url: url)  //объект запроса
            request.timeoutInterval = 2.0
            
            let (data, response) = try await URLSession.shared.data(for: request)       //обращение к интернету
            
            //проверяем, что сервер ответил кодом 200
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let firstEntry = jsonArray.first,
                   let meanings = firstEntry["meanings"] as? [[String: Any]] {
                    
                    for meaning in meanings {                                               //значение
                        if let definitions = meaning["definitions"] as? [[String: Any]] {   //определение
                            for definition in definitions {
                                if let example = definition["example"] as? String {
                                    return example.prefix(1).capitalized + example.dropFirst()
                                }
                            }
                        }
                    }
                }
            }
            return getFallbackExample(for: word)
            
        } catch {
            print("API Error: Переход на резервный генератор для слова \(word)")
            //микро задержка
            try? await Task.sleep(nanoseconds: 300_000_000)
            return getFallbackExample(for: word)
        }
    }
    
    private func getFallbackExample(for word: String) -> String {
        let templates = [
            "Let's look at how to use the word '\(word)' in a sentence.",
            "Can you explain the meaning of '\(word)' to me?",
            "It is very important to remember the word '\(word)'.",
            "I added the word '\(word)' to my personal dictionary."
        ]
        let randomSentence = templates.randomElement() ?? "The word '\(word)' is useful."
        return randomSentence
    }
}
