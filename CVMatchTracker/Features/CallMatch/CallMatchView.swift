import SwiftData
import SwiftUI

private enum CallMatchMode: String, CaseIterable, Identifiable {
    case all = "All"
    case company = "Company"
    case jobTitle = "Job"
    case recruiter = "Recruiter"
    case phone = "Phone"

    var id: String { rawValue }
}

struct CallMatchView: View {
    @Query(sort: \ApplicationRecord.dateApplied, order: .reverse) private var applications: [ApplicationRecord]

    @State private var searchText = ""
    @State private var mode: CallMatchMode = .all

    private var matches: [ApplicationRecord] {
        let query = searchText.trimmedForSaving.localizedLowercase
        guard !query.isEmpty else { return [] }

        let phoneQuery = normalizedPhone(query)

        return applications.filter { application in
            switch mode {
            case .all:
                let matchesAnyField = matchesCompany(application, query: query) ||
                    matchesJob(application, query: query) ||
                    matchesRecruiter(application, query: query) ||
                    matchesPhone(application, query: phoneQuery)
                return matchesAnyField
            case .company:
                return matchesCompany(application, query: query)
            case .jobTitle:
                return matchesJob(application, query: query)
            case .recruiter:
                return matchesRecruiter(application, query: query)
            case .phone:
                return matchesPhone(application, query: phoneQuery)
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Match an incoming call to the exact application record.")
                        .font(.headline)
                    Text("Search by company, role, recruiter, or phone number to pull up the CV, cover letter, and job description before you answer.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    TextField("Search incoming caller", text: $searchText)
                        .textInputAutocapitalization(.words)
                        .keyboardType(mode == .phone ? .phonePad : .default)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )

                    Picker("Match field", selection: $mode) {
                        ForEach(CallMatchMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if searchText.trimmedForSaving.isEmpty {
                    EmptyStateView(
                        title: "Ready for the next call",
                        message: "Type any caller detail and matching applications will appear instantly.",
                        symbolName: "phone.badge.waveform"
                    )
                    .premiumCard()
                } else if matches.isEmpty {
                    EmptyStateView(
                        title: "No match found",
                        message: "Try searching a partial company name, recruiter surname, or the last few phone digits.",
                        symbolName: "magnifyingglass"
                    )
                    .premiumCard()
                } else {
                    ForEach(matches) { application in
                        NavigationLink {
                            ApplicationDetailView(application: application)
                        } label: {
                            CallMatchResultCard(application: application)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Call Match")
    }

    private func matchesCompany(_ application: ApplicationRecord, query: String) -> Bool {
        application.companyName.localizedLowercase.contains(query)
    }

    private func matchesJob(_ application: ApplicationRecord, query: String) -> Bool {
        application.jobTitle.localizedLowercase.contains(query)
    }

    private func matchesRecruiter(_ application: ApplicationRecord, query: String) -> Bool {
        application.recruiter?.name.localizedLowercase.contains(query) == true
        || application.recruiter?.email.localizedLowercase.contains(query) == true
    }

    private func matchesPhone(_ application: ApplicationRecord, query: String) -> Bool {
        guard !query.isEmpty else { return false }
        return normalizedPhone(application.recruiter?.phoneNumber ?? "").contains(query)
    }

    private func normalizedPhone(_ value: String) -> String {
        value.filter(\.isNumber)
    }
}

private struct CallMatchResultCard: View {
    let application: ApplicationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(application.companyName)
                        .font(.title3.weight(.semibold))
                    Text(application.jobTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                StatusBadge(status: application.status)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                MatchLine(
                    title: "CV sent",
                    value: application.cvDocument?.name ?? "No CV attached",
                    systemImage: "doc.richtext.fill"
                )
                MatchLine(
                    title: "Cover letter",
                    value: application.coverLetter?.name ?? "No cover letter attached",
                    systemImage: "doc.text.fill"
                )
                if let recruiter = application.recruiter, recruiter.hasDetails {
                    MatchLine(
                        title: "Recruiter",
                        value: [recruiter.name, recruiter.phoneNumber].filter { !$0.isEmpty }.joined(separator: " • "),
                        systemImage: "person.crop.circle.badge.checkmark"
                    )
                }
            }

            if !application.jobDescription.isEmpty {
                Text(application.jobDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .premiumCard()
    }
}

private struct MatchLine: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "Not saved" : value)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}
