import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query private var applications: [ApplicationRecord]
    @Query private var cvDocuments: [CVDocument]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Free plan", systemImage: "person.crop.circle")
                            .font(.headline)
                        Spacer()
                        Text("Free")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.12))
                            )
                    }

                    Text("Your data is stored locally on this device in the first version.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        Label("View Premium roadmap", systemImage: "sparkles")
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Usage") {
                SettingsUsageRow(
                    title: "Applications",
                    value: "\(applications.count) / \(PremiumLimits.freeApplicationLimit)",
                    systemImage: "folder.fill"
                )
                SettingsUsageRow(
                    title: "CV versions",
                    value: "\(cvDocuments.count) / \(PremiumLimits.freeCVLimit)",
                    systemImage: "doc.richtext.fill"
                )
            }

            Section("Premium features") {
                ForEach(PremiumFeature.allCases) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: feature.symbolName)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.rawValue)
                            Text(feature.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 8)

                        Text("Planned")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Roadmap") {
                Label("iCloud sync is planned after local storage is stable.", systemImage: "icloud")
                Label("PDF export will use the saved application record and prep notes.", systemImage: "square.and.arrow.up")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .navigationTitle("Settings")
    }
}

private struct SettingsUsageRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Premium Roadmap")
                        .font(.largeTitle.weight(.bold))
                    Text("Premium features are planned for a future release. There is no purchase flow in this version.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Free")
                        .font(.headline)
                    PlanFeatureRow(text: "Track \(PremiumLimits.freeApplicationLimit) applications", isIncluded: true)
                    PlanFeatureRow(text: "Store \(PremiumLimits.freeCVLimit) CV versions", isIncluded: true)
                    PlanFeatureRow(text: "Call Match for saved applications", isIncluded: true)
                    PlanFeatureRow(text: "Unlimited applications", isIncluded: false)
                    PlanFeatureRow(text: "AI interview prep", isIncluded: false)
                }
                .padding(16)
                .premiumCard()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Premium")
                        .font(.headline)
                    ForEach(PremiumFeature.allCases) { feature in
                        PlanFeatureRow(text: feature.rawValue, isIncluded: true)
                    }
                }
                .padding(16)
                .premiumCard()

                VStack(alignment: .leading, spacing: 10) {
                    Label("No purchase required", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                    Text("This App Store build works offline with the free limits shown above. In-app purchases and subscriptions are not enabled in version 1.0.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .premiumCard()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Premium Roadmap")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

private struct PlanFeatureRow: View {
    let text: String
    let isIncluded: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isIncluded ? "checkmark.circle.fill" : "lock.fill")
                .foregroundStyle(isIncluded ? .green : .secondary)
            Text(text)
                .foregroundStyle(isIncluded ? .primary : .secondary)
            Spacer()
        }
        .font(.subheadline)
    }
}
