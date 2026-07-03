import SwiftUI
import Charts
import SwiftData

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss         //окружение для закрытия модального окна
    @Query private var cards: [WordCard]
    
    var learnedCount: Int { cards.filter { $0.isLearned && !$0.isSkipped }.count }
    var rotationCount: Int { cards.filter { $0.inRotation }.count }
    var skippedCount: Int { cards.filter { $0.isSkipped }.count }
    var leftCount: Int { cards.filter { !$0.inRotation && !$0.isLearned && !$0.isSkipped }.count }
    
    var chartData: [(day: String, count: Int)] {
        let learnedCards = cards.filter { $0.isLearned && $0.learnedDate != nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        var grouped: [String: Int] = [:]    //словарь для группировки по дням
        for card in learnedCards {
            if let date = card.learnedDate { grouped[formatter.string(from: date), default: 0] += 1 }
        }
        return grouped
            .map { (day: $0.key, count: $0.value) }     //преобразуем в массив кортежей и сортируем по дате
            .sorted { $0.day < $1.day }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: [GridItem(.flexible()),
                                        GridItem(.flexible())], spacing: 15)    //сетка из двух колонок
                    {
                        StatBox(title: "Выучено", value: learnedCount)
                        StatBox(title: "В ротации", value: rotationCount)
                        StatBox(title: "Не в ротации", value: skippedCount)
                        StatBox(title: "Осталось", value: leftCount)
                    }
                    .padding()
                    
                    if !chartData.isEmpty {
                        Text("Выучено слов по дням").font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                        
                        Chart {
                            ForEach(chartData, id: \.day) { item in
                                BarMark(
                                    x: .value("День", item.day),
                                    y: .value("Слова", item.count)
                                ).foregroundStyle(Color.blue.gradient)
                            }
                        }
                        .frame(height: 250).padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(15).padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Прогресс").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Закрыть") { dismiss() }
            }.background(Color(UIColor.systemGroupedBackground))
        }
    }
}

//структура для отдельного блока статистики
struct StatBox: View {
    let title: String
    let value: Int
    var body: some View {
        VStack(spacing: 8) {
            Text("\(value)").font(.system(size: 32, weight: .heavy))
            Text(title).font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)     //заголовок с выравниванием по центру
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
