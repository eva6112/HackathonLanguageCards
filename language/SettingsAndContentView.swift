import SwiftUI
import SwiftData

struct DailyContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("“Oh, how I wish I could shut up like a telescope! I think I could, if only I knew how to begin.” For, you see, so many out-of-the-way things had happened lately, that Alice had begun to think that very few things indeed were really impossible.").font(.body).italic()
                        Text("— \"Alice in Wonderland\", Chapter 1, Down the Rabbit-Hole").font(.caption).foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("“Ах, как бы я хотела складываться, как подзорная труба! Я думаю, смогла бы, если бы только знала, с чего начать.” Видишь ли, так много невероятных событий произошло в тот день, что Алиса начала думать, что лишь очень малая часть вещей была действительно невозможна.").font(.body)
                        Text("— \"Алиса в Стране чудес\", Глава 1").font(.caption).foregroundColor(.secondary)
                    }
                    Link(destination: URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!) {
                        HStack { Image(systemName: "play.rectangle.fill"); Text("Видео с контентом на английском") }.font(.headline).padding().frame(maxWidth: .infinity).background(Color.red).foregroundColor(.white).cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Контент дня")
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [WordCard]
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var manager = AppManager()
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Внешний вид")) { Toggle("Ночная тема", isOn: $isDarkMode) }
                Section(header: Text("Управление словарем"), footer: Text("Синхронизация сохраняет ваш текущий прогресс.")) {
                    Button(action: {
                        isLoading = true
                        Task { await manager.syncDictionary(context: modelContext); isLoading = false }
                    }) {
                        HStack { Text("Выбор и скачивание словаря"); Spacer(); if isLoading { ProgressView() } }
                    }.disabled(isLoading)
                    Button("Мануальное повторение") {
                        for card in cards where card.isLearned && !card.isSkipped { card.isManualReview = true; card.nextReview = Date() }
                        try? modelContext.save()
                    }
                    Button("Сброс данных", role: .destructive) {
                        for card in cards { modelContext.delete(card) }
                        try? modelContext.save()
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
}
