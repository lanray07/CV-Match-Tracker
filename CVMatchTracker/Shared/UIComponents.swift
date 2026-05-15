import SwiftUI

struct StatusBadge: View {
    let status: ApplicationStatus

    var body: some View {
        Label(status.rawValue, systemImage: status.symbolName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(status.tint.opacity(0.12))
            )
            .accessibilityLabel("Status \(status.rawValue)")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let symbolName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tint.opacity(0.13))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .premiumCard()
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let symbolName: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 76, height: 76)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.secondary.opacity(0.10))
                )

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal)
    }
}

struct ApplicationRow: View {
    let application: ApplicationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
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
                if !application.location.isEmpty {
                    Label(application.location, systemImage: "mappin.and.ellipse")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .padding(14)
        .premiumCard()
    }
}

struct DocumentReferenceRow: View {
    let title: String
    let fileName: String
    let detail: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(fileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

struct TimelineEventRow: View {
    let event: TimelineEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(.blue)
                .frame(width: 9, height: 9)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    Text(AppFormatters.shortDate.string(from: event.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if !event.detail.isEmpty {
                    Text(event.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

extension View {
    func premiumCard() -> some View {
        background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
