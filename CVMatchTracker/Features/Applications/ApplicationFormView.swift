import SwiftData
import SwiftUI

struct ApplicationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ApplicationRecord.dateApplied, order: .reverse) private var applications: [ApplicationRecord]
    @Query(sort: \CVDocument.createdAt, order: .reverse) private var cvDocuments: [CVDocument]
    @Query(sort: \CoverLetterDocument.createdAt, order: .reverse) private var coverLetters: [CoverLetterDocument]

    @State private var companyName = ""
    @State private var jobTitle = ""
    @State private var location = ""
    @State private var salary = ""
    @State private var jobAdvertURL = ""
    @State private var dateApplied = Date()
    @State private var status: ApplicationStatus = .applied
    @State private var recruiterName = ""
    @State private var recruiterPhoneNumber = ""
    @State private var recruiterEmail = ""
    @State private var notes = ""
    @State private var jobDescription = ""
    @State private var selectedCVID: UUID?
    @State private var selectedCoverLetterID: UUID?
    @State private var importedCV: ImportedDocument?
    @State private var importedCoverLetter: ImportedDocument?
    @State private var errorMessage: String?

    private var canSave: Bool {
        !companyName.trimmedForSaving.isEmpty && !jobTitle.trimmedForSaving.isEmpty
    }

    private var canCreateApplication: Bool {
        PremiumAccess.isUnlocked || applications.count < PremiumLimits.freeApplicationLimit
    }

    private var canImportNewCV: Bool {
        PremiumAccess.isUnlocked || cvDocuments.count < PremiumLimits.freeCVLimit
    }

    var body: some View {
        Form {
            if !canCreateApplication {
                Section {
                    PremiumLockView(
                        title: "Free application limit reached",
                        message: "Free users can track \(PremiumLimits.freeApplicationLimit) applications in version 1.0."
                    )
                }
            }

            Section("Role") {
                TextField("Company name", text: $companyName)
                    .textContentType(.organizationName)
                TextField("Job title", text: $jobTitle)
                TextField("Location", text: $location)
                TextField("Salary", text: $salary)
                TextField("Job advert URL", text: $jobAdvertURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                DatePicker("Date applied", selection: $dateApplied, displayedComponents: .date)
                Picker("Status", selection: $status) {
                    ForEach(ApplicationStatus.allCases) { status in
                        Label(status.rawValue, systemImage: status.symbolName)
                            .tag(status)
                    }
                }
            }

            Section("Recruiter") {
                TextField("Recruiter name", text: $recruiterName)
                    .textContentType(.name)
                TextField("Phone number", text: $recruiterPhoneNumber)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                TextField("Email", text: $recruiterEmail)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }

            Section("Documents") {
                Picker("CV version", selection: $selectedCVID) {
                    Text("No existing CV").tag(Optional<UUID>.none)
                    ForEach(cvDocuments) { cv in
                        Text(cv.name).tag(Optional(cv.id))
                    }
                }

                DocumentImportButton(
                    title: "Upload CV file",
                    systemImage: "doc.badge.plus",
                    importedDocument: $importedCV
                )
                .disabled(!canImportNewCV)

                if !canImportNewCV {
                    Text("Free users can store \(PremiumLimits.freeCVLimit) CV versions. Select an existing CV or use the future Premium roadmap for unlimited uploads.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Picker("Cover letter", selection: $selectedCoverLetterID) {
                    Text("No existing cover letter").tag(Optional<UUID>.none)
                    ForEach(coverLetters) { coverLetter in
                        Text(coverLetter.name).tag(Optional(coverLetter.id))
                    }
                }

                DocumentImportButton(
                    title: "Upload cover letter file",
                    systemImage: "doc.text.badge.plus",
                    importedDocument: $importedCoverLetter
                )
            }

            Section("Job description") {
                TextEditor(text: $jobDescription)
                    .frame(minHeight: 180)
                    .overlay(alignment: .topLeading) {
                        if jobDescription.isEmpty {
                            Text("Paste the job description here")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Add Application")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave || !canCreateApplication)
            }
        }
    }

    private func save() {
        errorMessage = nil

        guard canCreateApplication else {
            errorMessage = "The free version can track up to \(PremiumLimits.freeApplicationLimit) applications."
            return
        }

        guard canImportNewCV || importedCV == nil else {
            errorMessage = "Select an existing CV or wait for a future Premium release to upload more CV versions."
            return
        }

        let selectedCV = selectedCVID.flatMap { id in cvDocuments.first { $0.id == id } }
        let selectedCoverLetter = selectedCoverLetterID.flatMap { id in coverLetters.first { $0.id == id } }

        let cvDocument: CVDocument? = {
            if let importedCV {
                let name = importedCV.fileName.replacingOccurrences(of: ".pdf", with: "")
                let cv = CVDocument(
                    name: name,
                    fileName: importedCV.fileName,
                    contentTypeIdentifier: importedCV.contentTypeIdentifier,
                    fileData: importedCV.data
                )
                modelContext.insert(cv)
                return cv
            }
            return selectedCV
        }()

        let coverLetter: CoverLetterDocument? = {
            if let importedCoverLetter {
                let name = importedCoverLetter.fileName.replacingOccurrences(of: ".pdf", with: "")
                let cover = CoverLetterDocument(
                    name: name,
                    fileName: importedCoverLetter.fileName,
                    contentTypeIdentifier: importedCoverLetter.contentTypeIdentifier,
                    fileData: importedCoverLetter.data
                )
                modelContext.insert(cover)
                return cover
            }
            return selectedCoverLetter
        }()

        let recruiter = RecruiterContact(
            name: recruiterName.trimmedForSaving,
            phoneNumber: recruiterPhoneNumber.trimmedForSaving,
            email: recruiterEmail.trimmedForSaving
        )

        let application = ApplicationRecord(
            companyName: companyName.trimmedForSaving,
            jobTitle: jobTitle.trimmedForSaving,
            location: location.trimmedForSaving,
            salary: salary.trimmedForSaving,
            jobAdvertURL: jobAdvertURL.trimmedForSaving,
            dateApplied: dateApplied,
            status: status,
            notes: notes.trimmedForSaving,
            jobDescription: jobDescription.trimmedForSaving,
            cvDocument: cvDocument,
            coverLetter: coverLetter,
            recruiter: recruiter
        )

        application.timelineEvents.append(
            TimelineEvent(
                applicationID: application.id,
                date: dateApplied,
                title: "Application submitted",
                detail: cvDocument.map { "Used \($0.name)." } ?? "Application saved.",
                kind: .applied
            )
        )

        modelContext.insert(application)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Could not save this application. Please try again."
        }
    }
}
