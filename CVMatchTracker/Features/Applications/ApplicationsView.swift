import SwiftData
import SwiftUI

struct ApplicationsView: View {
    @Query(sort: \ApplicationRecord.dateApplied, order: .reverse) private var applications: [ApplicationRecord]
    @AppStorage("isPremiumUnlocked") private var isPremiumUnlocked = false

    @State private var searchText = ""
    @State private var statusFilter = "All"
    @State private var isAddApplicationPresented = false
    @State private var isSubscriptionPresented = false

    private var canAddApplication: Bool {
        isPremiumUnlocked || applications.count < PremiumLimits.freeApplicationLimit
    }

    private var filteredApplications: [ApplicationRecord] {
        applications.filter { application in
            let matchesStatus = statusFilter == "All" || application.status.rawValue == statusFilter
            let query = searchText.trimmedForSaving.localizedLowercase
            let matchesSearch = query.isEmpty
            || application.companyName.localizedLowercase.contains(query)
            || application.jobTitle.localizedLowercase.contains(query)
            || application.location.localizedLowercase.contains(query)
            || application.recruiter?.name.localizedLowercase.contains(query) == true
            return matchesStatus && matchesSearch
        }
    }

    var body: some View {
        Group {
            if applications.isEmpty {
                emptyState
            } else {
                List {
                    if !canAddApplication {
                        Section {
                            limitReachedCard
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        ForEach(filteredApplications) { application in
                            NavigationLink {
                                ApplicationDetailView(application: application)
                            } label: {
                                ApplicationListRow(application: application)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search applications")
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("All") { statusFilter = "All" }
                    ForEach(ApplicationStatus.allCases) { status in
                        Button(status.rawValue) { statusFilter = status.rawValue }
                    }
                } label: {
                    Label(statusFilter, systemImage: "line.3.horizontal.decrease.circle")
                }
            }

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

    private var emptyState: some View {
        VStack(spacing: 18) {
            EmptyStateView(
                title: "Track your first application",
                message: "Save the company, role, recruiter, CV, cover letter, job description, and reminders in one place.",
                symbolName: "folder.badge.plus"
            )

            Button {
                isAddApplicationPresented = true
            } label: {
                Label("Add Application", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
    }

    private var limitReachedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Free limit reached", systemImage: "lock.fill")
                .font(.headline)
            Text("Free users can track \(PremiumLimits.freeApplicationLimit) applications. Premium unlocks unlimited tracking.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("View Premium") {
                isSubscriptionPresented = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .premiumCard()
    }
}

private struct ApplicationListRow: View {
    let application: ApplicationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(application.companyName)
                        .font(.headline)
                    Text(application.jobTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)
                StatusBadge(status: application.status)
            }

            HStack(spacing: 12) {
                Label(AppFormatters.shortDate.string(from: application.dateApplied), systemImage: "calendar")
                if let cv = application.cvDocument {
                    Label(cv.name, systemImage: "doc.text.fill")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .padding(.vertical, 6)
    }
}
