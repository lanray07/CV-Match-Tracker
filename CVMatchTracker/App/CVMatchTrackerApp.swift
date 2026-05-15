import SwiftData
import SwiftUI

@main
struct CVMatchTrackerApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                ApplicationRecord.self,
                CVDocument.self,
                CoverLetterDocument.self,
                RecruiterContact.self,
                Reminder.self,
                TimelineEvent.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create the local CV Match Tracker store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(modelContainer)
        }
    }
}
