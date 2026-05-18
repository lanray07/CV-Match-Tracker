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
                        Label("Local-first app", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                        Spacer()
                        Text("Version 1.0")
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
                }
                .padding(.vertical, 6)
            }

            Section("Usage") {
                SettingsUsageRow(
                    title: "Applications",
                    value: "\(applications.count)",
                    systemImage: "folder.fill"
                )
                SettingsUsageRow(
                    title: "CV versions",
                    value: "\(cvDocuments.count)",
                    systemImage: "doc.richtext.fill"
                )
            }

            Section("Included") {
                IncludedFeatureRow(
                    title: "Application tracking",
                    detail: "Save every application, recruiter contact, document, reminder, and note.",
                    systemImage: "folder.fill"
                )
                IncludedFeatureRow(
                    title: "CV library",
                    detail: "Store multiple CV versions and see which jobs used each one.",
                    systemImage: "doc.richtext.fill"
                )
                IncludedFeatureRow(
                    title: "Interview prep",
                    detail: "Generate local prep notes from the saved CV, job description, and application notes.",
                    systemImage: "sparkles"
                )
            }

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

private struct IncludedFeatureRow: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
