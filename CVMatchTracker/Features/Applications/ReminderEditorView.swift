import SwiftData
import SwiftUI

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var application: ApplicationRecord

    @State private var type: ReminderType = .followUp
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    @State private var title = "Follow up"
    @State private var detail = ""

    var body: some View {
        Form {
            Section("Reminder") {
                Picker("Type", selection: $type) {
                    ForEach(ReminderType.allCases) { type in
                        Label(type.rawValue, systemImage: type.symbolName).tag(type)
                    }
                }
                TextField("Title", text: $title)
                DatePicker("Due date", selection: $dueDate)
            }

            Section("Notes") {
                TextEditor(text: $detail)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle("Add Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(title.trimmedForSaving.isEmpty)
            }
        }
    }

    private func save() {
        let reminder = Reminder(
            applicationID: application.id,
            applicationTitle: application.displayTitle,
            title: title.trimmedForSaving,
            detail: detail.trimmedForSaving,
            dueDate: dueDate,
            type: type
        )

        application.reminders.append(reminder)
        application.timelineEvents.append(
            TimelineEvent(
                applicationID: application.id,
                title: "\(type.rawValue) reminder added",
                detail: AppFormatters.reminderDate.string(from: dueDate),
                kind: .reminder
            )
        )
        modelContext.insert(reminder)
        LocalNotificationScheduler.schedule(reminder: reminder)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            dismiss()
        }
    }
}
