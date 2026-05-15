import SwiftData
import SwiftUI

struct CVLibraryView: View {
    @Query(sort: \CVDocument.createdAt, order: .reverse) private var cvDocuments: [CVDocument]
    @Query(sort: \ApplicationRecord.dateApplied, order: .reverse) private var applications: [ApplicationRecord]

    @State private var isAddCVPresented = false
    @State private var isSubscriptionPresented = false

    private var canAddCV: Bool {
        PremiumAccess.isUnlocked || cvDocuments.count < PremiumLimits.freeCVLimit
    }

    var body: some View {
        Group {
            if cvDocuments.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if !canAddCV {
                            limitReachedCard
                        }

                        ForEach(cvDocuments) { cv in
                            NavigationLink {
                                CVDocumentDetailView(cv: cv)
                            } label: {
                                cvCard(cv)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("CV Library")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if canAddCV {
                        isAddCVPresented = true
                    } else {
                        isSubscriptionPresented = true
                    }
                } label: {
                    Label("Add CV", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddCVPresented) {
            NavigationStack {
                AddCVView()
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
                title: "No CV versions yet",
                message: "Upload your core CVs here, then attach the right version when saving each application.",
                symbolName: "doc.richtext"
            )

            Button {
                isAddCVPresented = true
            } label: {
                Label("Upload CV", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
    }

    private var limitReachedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Free CV limit reached", systemImage: "lock.fill")
                .font(.headline)
            Text("Free users can store \(PremiumLimits.freeCVLimit) CV versions. A future Premium release is planned for unlimited uploads.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("View Roadmap") {
                isSubscriptionPresented = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .premiumCard()
    }

    private func cvCard(_ cv: CVDocument) -> some View {
        let jobsUsed = applications.filter { $0.cvDocument?.id == cv.id }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "doc.richtext.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(cv.name)
                        .font(.headline)
                    Text(cv.fileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 12) {
                Label("\(jobsUsed.count) jobs", systemImage: "briefcase.fill")
                Label(cv.fileSizeDescription, systemImage: "internaldrive.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let firstJob = jobsUsed.first {
                Text("Recently used for \(firstJob.jobTitle) at \(firstJob.companyName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .premiumCard()
    }
}

struct AddCVView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CVDocument.createdAt, order: .reverse) private var cvDocuments: [CVDocument]

    @State private var name = ""
    @State private var summary = ""
    @State private var importedCV: ImportedDocument?
    @State private var errorMessage: String?

    private var canAddCV: Bool {
        PremiumAccess.isUnlocked || cvDocuments.count < PremiumLimits.freeCVLimit
    }

    private var canSave: Bool {
        canAddCV && !name.trimmedForSaving.isEmpty && importedCV != nil
    }

    var body: some View {
        Form {
            if !canAddCV {
                Section {
                    PremiumLockView(
                        title: "Free CV limit reached",
                        message: "A future Premium release is planned for unlimited CV versions."
                    )
                }
            }

            Section("CV") {
                TextField("CV version name", text: $name)
                DocumentImportButton(
                    title: "Choose CV file",
                    systemImage: "doc.badge.plus",
                    importedDocument: $importedCV
                )
                .disabled(!canAddCV)
            }

            Section("Summary") {
                TextEditor(text: $summary)
                    .frame(minHeight: 120)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Add CV")
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
                .disabled(!canSave)
            }
        }
        .onChange(of: importedCV) { _, newValue in
            guard name.trimmedForSaving.isEmpty, let newValue else { return }
            name = newValue.fileName.replacingOccurrences(of: ".pdf", with: "")
        }
    }

    private func save() {
        guard let importedCV else {
            errorMessage = "Choose a CV file first."
            return
        }

        let cv = CVDocument(
            name: name.trimmedForSaving,
            fileName: importedCV.fileName,
            contentTypeIdentifier: importedCV.contentTypeIdentifier,
            fileData: importedCV.data,
            summary: summary.trimmedForSaving
        )
        modelContext.insert(cv)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Could not save this CV. Please try again."
        }
    }
}

struct CVDocumentDetailView: View {
    @Bindable var cv: CVDocument
    @Query(sort: \ApplicationRecord.dateApplied, order: .reverse) private var applications: [ApplicationRecord]

    private var jobsUsed: [ApplicationRecord] {
        applications.filter { $0.cvDocument?.id == cv.id }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("CV version name", text: $cv.name)
                        .font(.title3.weight(.semibold))
                    Text(cv.fileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(cv.fileSizeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .premiumCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary")
                        .font(.headline)
                    TextEditor(text: $cv.summary)
                        .frame(minHeight: 120)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Jobs using this CV")
                        .font(.headline)

                    if jobsUsed.isEmpty {
                        Text("This CV has not been attached to an application yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .premiumCard()
                    } else {
                        ForEach(jobsUsed) { application in
                            NavigationLink {
                                ApplicationDetailView(application: application)
                            } label: {
                                ApplicationRow(application: application)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("PDF preview")
                        .font(.headline)

                    if let data = cv.fileData, cv.isPDF {
                        PDFPreview(data: data)
                            .frame(minHeight: 520)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text("Preview is available for PDF files. Other document types are stored and can be attached to applications.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .premiumCard()
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("CV Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CoverLetterPreviewView: View {
    let coverLetter: CoverLetterDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DocumentReferenceRow(
                    title: coverLetter.name,
                    fileName: coverLetter.fileName,
                    detail: coverLetter.fileSizeDescription,
                    symbolName: "doc.text.fill"
                )
                .padding(14)
                .premiumCard()

                if let data = coverLetter.fileData, coverLetter.isPDF {
                    PDFPreview(data: data)
                        .frame(minHeight: 560)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text("Preview is available for PDF files. This cover letter is stored locally and attached to the application record.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .premiumCard()
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Cover Letter")
        .navigationBarTitleDisplayMode(.inline)
    }
}
