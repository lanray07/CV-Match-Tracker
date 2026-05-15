import SwiftData
import SwiftUI

private enum ReminderFilter: String, CaseIterable, Identifiable {
    case active = "Active"
    case completed = "Completed"
    case all = "All"

    var id: String { rawValue }
}

struct RemindersView: View {
    @Query(sort: \Reminder.dueDate, order: .forward) private var reminders: [Reminder]
    @Query(sort: \ApplicationRecord.dateApplied, order: .reverse) private var applications: [ApplicationRecord]

    @State private var filter: ReminderFilter = .active

    private var filteredReminders: [Reminder] {
        reminders.filter { reminder in
            switch filter {
            case .active:
                return !reminder.isCompleted
            case .completed:
                return reminder.isCompleted
            case .all:
                return true
            }
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Reminder filter", selection: $filter) {
                    ForEach(ReminderFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            if filteredReminders.isEmpty {
                EmptyStateView(
                    title: "No reminders",
                    message: "Create reminders from an application detail screen.",
                    symbolName: "bell"
                )
                .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(filteredReminders) { reminder in
                        ReminderListRow(
                            reminder: reminder,
                            application: applications.first { $0.id == reminder.applicationID }
                        )
                    }
                }
            }
        }
        .navigationTitle("Reminders")
    }
}

private struct ReminderListRow: View {
    @Bindable var reminder: Reminder
    let application: ApplicationRecord?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                reminder.isCompleted.toggle()
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(reminder.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(reminder.isCompleted ? "Mark incomplete" : "Mark complete")

            if let application {
                NavigationLink {
                    ApplicationDetailView(application: application)
                } label: {
                    reminderContent
                }
            } else {
                reminderContent
            }
        }
        .padding(.vertical, 4)
    }

    private var reminderContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(reminder.type.rawValue, systemImage: reminder.type.symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            Text(reminder.title)
                .font(.headline)
            if !reminder.applicationTitle.isEmpty {
                Text(reminder.applicationTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(AppFormatters.reminderDate.string(from: reminder.dueDate))
                .font(.caption)
                .foregroundStyle(.secondary)
            if !reminder.detail.isEmpty {
                Text(reminder.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
