import SwiftUI
import UniformTypeIdentifiers

struct ImportedDocument: Identifiable, Equatable {
    let id = UUID()
    var fileName: String
    var data: Data
    var contentTypeIdentifier: String
}

struct DocumentImportButton: View {
    let title: String
    let systemImage: String
    @Binding var importedDocument: ImportedDocument?

    @State private var isImporterPresented = false
    @State private var errorMessage: String?

    private var acceptedTypes: [UTType] {
        var types: [UTType] = [.pdf, .rtf, .plainText, .text]
        if let doc = UTType(filenameExtension: "doc") {
            types.append(doc)
        }
        if let docx = UTType(filenameExtension: "docx") {
            types.append(docx)
        }
        return types
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isImporterPresented = true
            } label: {
                Label(title, systemImage: systemImage)
            }

            if let importedDocument {
                Label(importedDocument.fileName, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: acceptedTypes,
            allowsMultipleSelection: false
        ) { result in
            importDocument(from: result)
        }
    }

    private func importDocument(from result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let values = try url.resourceValues(forKeys: [.contentTypeKey])
            let data = try Data(contentsOf: url)
            importedDocument = ImportedDocument(
                fileName: url.lastPathComponent,
                data: data,
                contentTypeIdentifier: values.contentType?.identifier ?? UTType.data.identifier
            )
            errorMessage = nil
        } catch {
            errorMessage = "Could not import this file. Try a PDF, DOCX, RTF, or text file."
        }
    }
}
