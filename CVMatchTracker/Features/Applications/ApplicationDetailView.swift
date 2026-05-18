import SwiftData
import SwiftUI

struct ApplicationDetailView: View {
    @Bindable var application: ApplicationRecord
    @Environment(\.modelContext) private var modelContext

    @State private var isReminderPresented = false
    @State private var oldStatusRawValue: String

    init(application: ApplicationRecord) {
        self.application = application
        _oldStatusRawValue = State(initialValue: application.statusRawValue)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header
                documents
                recruiterDetails
                jobDescription
                notes
                timeline
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(application.companyName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isReminderPresented = true
                } label: {
                    Label("Follow-up reminder", systemImage: "bell.badge")
                }
            }
        }
        .sheet(isPresented: $isReminderPresented) {
            NavigationStack {
                ReminderEditorView(application: application)
            }
        }
        .onChange(of: application.statusRawValue) { _, newValue in
            guard oldStatusRawValue != newValue else { return }
            let oldStatus = ApplicationStatus(rawValue: oldStatusRawValue)?.rawValue ?? oldStatusRawValue
            application.updatedAt = .now
            application.timelineEvents.append(
                TimelineEvent(
                    applicationID: application.id,
                    title: "Status updated",
                    detail: "Moved from \(oldStatus) to \(newValue).",
                    kind: .statusChange
                )
            )
            oldStatusRawValue = newValue
            try? modelContext.save()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(application.jobTitle)
                        .font(.title2.weight(.bold))
                    Text(application.companyName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                StatusBadge(status: application.status)
            }

            Picker("Status", selection: $application.statusRawValue) {
                ForEach(ApplicationStatus.allCases) { status in
                    Text(status.rawValue).tag(status.rawValue)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 14) {
                Label(AppFormatters.shortDate.string(from: application.dateApplied), systemImage: "calendar")
                if !application.location.isEmpty {
                    Label(application.location, systemImage: "mappin.and.ellipse")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !application.salary.isEmpty {
                Label(application.salary, systemImage: "banknote.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            NavigationLink {
                InterviewPrepView(application: application)
            } label: {
                Label("Interview Prep", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .appCard()
    }

    private var documents: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documents")
                .font(.headline)

            if application.cvDocument == nil && application.coverLetter == nil {
                Text("No documents were attached to this application.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
            } else {
                if let cv = application.cvDocument {
                    NavigationLink {
                        CVDocumentDetailView(cv: cv)
                    } label: {
                        DocumentReferenceRow(
                            title: "CV version sent",
                            fileName: cv.name,
                            detail: cv.fileSizeDescription,
                            symbolName: "doc.richtext.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(14)
                    .appCard()
                }

                if let coverLetter = application.coverLetter {
                    NavigationLink {
                        CoverLetterPreviewView(coverLetter: coverLetter)
                    } label: {
                        DocumentReferenceRow(
                            title: "Cover letter sent",
                            fileName: coverLetter.name,
                            detail: coverLetter.fileSizeDescription,
                            symbolName: "doc.text.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(14)
                    .appCard()
                }
            }
        }
    }

    private var recruiterDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recruiter")
                .font(.headline)

            if let recruiter = application.recruiter, recruiter.hasDetails {
                VStack(alignment: .leading, spacing: 10) {
                    if !recruiter.name.isEmpty {
                        Label(recruiter.name, systemImage: "person.fill")
                    }
                    if !recruiter.phoneNumber.isEmpty {
                        Label(recruiter.phoneNumber, systemImage: "phone.fill")
                    }
                    if !recruiter.email.isEmpty {
                        Label(recruiter.email, systemImage: "envelope.fill")
                    }
                }
                .font(.subheadline)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()
            } else {
                Text("No recruiter details saved.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
            }
        }
    }

    private var jobDescription: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Job description")
                .font(.headline)

            Text(application.jobDescription.isEmpty ? "No job description saved." : application.jobDescription)
                .font(.subheadline)
                .foregroundStyle(application.jobDescription.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .appCard()
        }
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
            TextEditor(text: $application.notes)
                .frame(minHeight: 120)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)

            if application.sortedTimelineEvents.isEmpty {
                Text("Timeline updates will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(application.sortedTimelineEvents) { event in
                        TimelineEventRow(event: event)
                    }
                }
                .padding(14)
                .appCard()
            }
        }
    }
}
