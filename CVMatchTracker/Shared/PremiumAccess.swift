import SwiftUI

enum PremiumLimits {
    static let freeApplicationLimit = 15
    static let freeCVLimit = 3
}

enum PremiumFeature: String, CaseIterable, Identifiable {
    case unlimitedApplications = "Unlimited applications"
    case unlimitedCVs = "Unlimited CV uploads"
    case interviewPrep = "AI interview prep"
    case iCloudSync = "iCloud sync"
    case pdfExport = "PDF export"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .unlimitedApplications:
            return "Track every role without archive juggling."
        case .unlimitedCVs:
            return "Keep specialist, senior, graduate, contract, and sector-specific versions."
        case .interviewPrep:
            return "Generate talking points, likely questions, and CV-to-role gaps."
        case .iCloudSync:
            return "Future sync across iPhone, iPad, and Mac."
        case .pdfExport:
            return "Future export for application records and interview prep packs."
        }
    }

    var symbolName: String {
        switch self {
        case .unlimitedApplications:
            return "tray.full.fill"
        case .unlimitedCVs:
            return "doc.richtext.fill"
        case .interviewPrep:
            return "sparkles"
        case .iCloudSync:
            return "icloud.fill"
        case .pdfExport:
            return "square.and.arrow.up.fill"
        }
    }
}

struct PremiumLockView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.linearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                )

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .premiumCard()
    }
}
