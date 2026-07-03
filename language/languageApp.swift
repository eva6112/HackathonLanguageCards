import SwiftUI
import SwiftData

@main
struct languageApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false        //тема в UserDefaults
        
        var body: some Scene {  //точка входа
            WindowGroup {
                TabView {
                    TrainingView().tabItem { Label("Обучение", systemImage: "graduationcap.fill") }
                    DailyContentView().tabItem { Label("Контент", systemImage: "book.pages.fill") }
                    SettingsView().tabItem { Label("Настройки", systemImage: "gearshape.fill") }
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
            }
            .modelContainer(for: WordCard.self)            //SwiftData - WordCard
        }
}
