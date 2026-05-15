import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \ApplicationRecord.dateApplied, order: .reverse) private var applications: [ApplicationRecord]
    @Query(sort: \Reminder.dueDate, order: .forward) private var reminders: [Reminder]

    @State private var searchText = ""
    @State private var isAddApplicationPresented = false
    @State private var isSubscriptionPresented = false

    private var canAddApplication: Bool {
        PremiumAccess.isUnlocked || applications.count < PremiumLimits.freeApplicationLimit
    }

    private var upcomingReminders: [Reminder] {
        reminders
            .filter { !$0.isCompleted && $0.dueDate >= Calendar.current.startOfDay(for: .now) }
            .prefix(5)
            .map { $0 }
    }

    private var searchResults: [ApplicationRecord] {
        guard !searchText.trimmedForSaving.isEmpty else { return [] }
        let query = searchText.localizedLowercase
        return applications.filter { application in
            application.companyName.localizedLowercase.contains(query)
            || application.jobTitle.localizedLowercase.contains(query)
            || application.recruiter?.name.localizedLowercase.contains(query) == true
            || application.recruiter?.phoneNumber.localizedLowercase.contains(query) == true
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CV Match Tracker")
                        .font(.largeTitle.weight(.bold))
                    Text("Find the exact CV, cover letter, and job description behind every application.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                HStack(spacing: 12) {
                    StatCard(
                        title: "Total applications",
                        value: "\(applications.count)",
                        symbolName: "folder.fill",
                        tint: .blue
                    )

                    StatCard(
                        title: "Upcoming",
                        value: "\(upcomingReminders.count)",
                        symbolName: "bell.badge.fill",
                        tint: .orange
                    )
                }

                statusGrid

                quickSearch

                upcomingSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if canAddApplication {
                        isAddApplicationPresented = true
                    } else {
                        isSubscriptionPresented = true
                    }
                } label: {
                    Label("Add application", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddApplicationPresented) {
            NavigationStack {
                ApplicationFormView()
            }
        }
        .sheet(isPresented: $isSubscriptionPresented) {
            NavigationStack {
                SubscriptionView()
            }
        }
    }

    private var statusGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(ApplicationStatus.allCases) { status in
                StatCard(
                    title: status.rawValue,
                    value: "\(applications.filter { $0.status == status }.count)",
                    symbolName: status.symbolName,
                    tint: status.tint
                )
            }
        }
    }

    private var quickSearch: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick search", systemImage: "magnifyingglass")
                .font(.headline)

            TextField("Company, role, recruiter, or phone", text: $searchText)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

            if !searchText.trimmedForSaving.isEmpty {
                if searchResults.isEmpty {
                    Text("No matching applications yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(searchResults.prefix(4)) { application in
                        NavigationLink {
                            ApplicationDetailView(application: application)
                        } label: {
                            ApplicationRow(application: application)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Upcoming follow-ups and interviews", systemImage: "calendar.badge.clock")
                    .font(.headline)
                Spacer()
                NavigationLink("All") {
                    RemindersView()
                }
                .font(.subheadline.weight(.semibold))
            }

            if upcomingReminders.isEmpty {
                EmptyStateView(
                    title: "Nothing due soon",
                    message: "Add follow-up, interview, and response deadline reminders from an application detail screen.",
                    symbolName: "checkmark.circle"
                )
                .premiumCard()
            } else {
                ForEach(upcomingReminders) { reminder in
                    if let application = applications.first(where: { $0.id == reminder.applicationID }) {
                        NavigationLink {
                            ApplicationDetailView(application: application)
                        } label: {
                            ReminderCard(reminder: reminder)
                        }
                        .buttonStyle(.plain)
                    } else {
                        ReminderCard(reminder: reminder)
                    }
                }
            }
        }
    }
}

private struct ReminderCard: View {
    let reminder: Reminder

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: reminder.type.symbolName)
                .font(.headline)
                .foregroundStyle(.orange)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline.weight(.semibold))
                if !reminder.applicationTitle.isEmpty {
                    Text(reminder.applicationTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(AppFormatters.reminderDate.string(from: reminder.dueDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .premiumCard()
    }
}
