import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query private var applications: [ApplicationRecord]
    @Query private var cvDocuments: [CVDocument]
    @AppStorage("isPremiumUnlocked") private var isPremiumUnlocked = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(isPremiumUnlocked ? "Premium preview active" : "Free plan", systemImage: isPremiumUnlocked ? "sparkles" : "person.crop.circle")
                            .font(.headline)
                        Spacer()
                        Text(isPremiumUnlocked ? "Premium" : "Free")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isPremiumUnlocked ? .green : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill((isPremiumUnlocked ? Color.green : Color.secondary).opacity(0.12))
                            )
                    }

                    Text("Your data is stored locally on this device in the first version.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        Label("Manage subscription", systemImage: "creditcard.fill")
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Usage") {
                SettingsUsageRow(
                    title: "Applications",
                    value: isPremiumUnlocked ? "\(applications.count) / Unlimited" : "\(applications.count) / \(PremiumLimits.freeApplicationLimit)",
                    systemImage: "folder.fill"
                )
                SettingsUsageRow(
                    title: "CV versions",
                    value: isPremiumUnlocked ? "\(cvDocuments.count) / Unlimited" : "\(cvDocuments.count) / \(PremiumLimits.freeCVLimit)",
                    systemImage: "doc.richtext.fill"
                )
            }

            Section("Premium features") {
                ForEach(PremiumFeature.allCases) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: feature.symbolName)
                            .foregroundStyle(isPremiumUnlocked ? .green : .secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.rawValue)
                            Text(feature.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: isPremiumUnlocked ? "checkmark.circle.fill" : "lock.fill")
                            .foregroundStyle(isPremiumUnlocked ? .green : .secondary)
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
    @AppStorage("isPremiumUnlocked") private var isPremiumUnlocked = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CV Match Tracker Premium")
                        .font(.largeTitle.weight(.bold))
                    Text("Unlock the full offline workflow now, with iCloud sync and export planned for a later release.")
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
                    Label("Payment integration placeholder", systemImage: "creditcard")
                        .font(.headline)
                    Text("No App Store purchase flow is connected in this version. The toggle below lets you preview locked Premium UI while testing locally.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Toggle("Preview Premium access", isOn: $isPremiumUnlocked)
                }
                .padding(16)
                .premiumCard()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Subscription")
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
