import PDFKit
import SwiftUI

struct InterviewPrepView: View {
    let application: ApplicationRecord

    private var prep: InterviewPrep {
        InterviewPrepGenerator.generate(for: application)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(application.jobTitle)
                        .font(.title2.weight(.bold))
                    Text(application.companyName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                prepSection("Summary of CV sent", systemImage: "doc.richtext.fill", text: prep.cvSummary)
                prepBullets("Key points to mention", systemImage: "quote.bubble.fill", items: prep.keyPoints)
                prepBullets("Likely interview questions", systemImage: "questionmark.bubble.fill", items: prep.likelyQuestions)
                prepBullets("Gaps between CV and job description", systemImage: "exclamationmark.triangle.fill", items: prep.gaps)
                prepSection("Quick notes before the call", systemImage: "phone.fill", text: prep.quickNotes)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Interview Prep")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func prepSection(_ title: String, systemImage: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .appCard()
    }

    private func prepBullets(_ title: String, systemImage: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .appCard()
    }
}

struct InterviewPrep {
    var cvSummary: String
    var keyPoints: [String]
    var likelyQuestions: [String]
    var gaps: [String]
    var quickNotes: String
}

enum InterviewPrepGenerator {
    static func generate(for application: ApplicationRecord) -> InterviewPrep {
        let cvText = extractedPDFText(from: application.cvDocument?.fileData)
        let cvName = application.cvDocument?.name ?? "the saved CV"
        let jobKeywords = keywords(from: application.jobDescription)
        let cvKeywords = Set(keywords(from: cvText + " " + application.notes).map { $0.lowercased() })
        let missingKeywords = jobKeywords
            .filter { !cvKeywords.contains($0.lowercased()) }
            .prefix(5)
            .map { "Prepare an example that covers \($0)." }

        let cvSummary: String
        if !cvText.isEmpty {
            cvSummary = summarize(cvText, fallback: "You sent \(cvName).")
        } else if let summary = application.cvDocument?.summary, !summary.isEmpty {
            cvSummary = summary
        } else {
            cvSummary = "You sent \(cvName). Add a PDF CV or summary to generate a richer preparation pack."
        }

        let keyPoints = [
            "Open with why \(application.companyName) and this \(application.jobTitle) role fit your current search.",
            "Reference the CV version sent: \(cvName).",
            "Prepare a concise example for \(jobKeywords.first ?? "the strongest requirement in the advert").",
            application.notes.isEmpty ? "Add notes from recruiter calls so this prep becomes more specific." : "Use your saved notes: \(application.notes)"
        ]

        let likelyQuestions = [
            "What interested you in \(application.companyName) and this role?",
            "Which project best demonstrates your fit for \(application.jobTitle)?",
            "How would you approach the first 90 days?",
            "What salary range, location, and working pattern are you looking for?",
            "Can you talk through a challenge similar to the one described in the job advert?"
        ]

        let gaps = missingKeywords.isEmpty ? [
            "No obvious gaps found from the saved text. Re-read the job description for any must-have tools or sector experience."
        ] : Array(missingKeywords)

        let recruiter = application.recruiter
        let recruiterLine = [recruiter?.name, recruiter?.phoneNumber, recruiter?.email]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")

        let quickNotes = [
            recruiterLine.isEmpty ? "Recruiter details are not saved." : "Recruiter: \(recruiterLine).",
            "Status: \(application.status.rawValue). Applied on \(AppFormatters.shortDate.string(from: application.dateApplied)).",
            application.salary.isEmpty ? "Salary not saved." : "Salary: \(application.salary).",
            application.location.isEmpty ? "Location not saved." : "Location: \(application.location)."
        ].joined(separator: "\n")

        return InterviewPrep(
            cvSummary: cvSummary,
            keyPoints: keyPoints,
            likelyQuestions: likelyQuestions,
            gaps: gaps,
            quickNotes: quickNotes
        )
    }

    private static func extractedPDFText(from data: Data?) -> String {
        guard let data, let document = PDFDocument(data: data) else { return "" }
        return (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: " ")
    }

    private static func summarize(_ text: String, fallback: String) -> String {
        let cleanText = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmedForSaving
        guard !cleanText.isEmpty else { return fallback }
        return String(cleanText.prefix(420))
    }

    private static func keywords(from text: String) -> [String] {
        let stopwords: Set<String> = [
            "about", "after", "again", "and", "are", "because", "been", "being", "between",
            "can", "for", "from", "have", "into", "more", "needed", "needs", "role",
            "strong", "that", "the", "this", "with", "will", "work", "your"
        ]

        let words = text
            .localizedLowercase
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 4 && !stopwords.contains($0) }

        let counts = Dictionary(words.map { ($0, 1) }, uniquingKeysWith: +)
        return counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(8)
            .map(\.key)
    }
}
