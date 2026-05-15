import Foundation
import SwiftData
import SwiftUI

enum ApplicationStatus: String, Codable, CaseIterable, Identifiable {
    case applied = "Applied"
    case interviewing = "Interviewing"
    case offer = "Offer"
    case rejected = "Rejected"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .applied:
            return "paperplane.fill"
        case .interviewing:
            return "person.2.wave.2.fill"
        case .offer:
            return "checkmark.seal.fill"
        case .rejected:
            return "xmark.seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .applied:
            return .blue
        case .interviewing:
            return .orange
        case .offer:
            return .green
        case .rejected:
            return .red
        }
    }
}

enum ReminderType: String, Codable, CaseIterable, Identifiable {
    case followUp = "Follow-up"
    case interview = "Interview"
    case responseDeadline = "Response deadline"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .followUp:
            return "bell.badge.fill"
        case .interview:
            return "calendar.badge.clock"
        case .responseDeadline:
            return "hourglass"
        }
    }
}

enum TimelineEventKind: String, Codable, CaseIterable, Identifiable {
    case applied = "Applied"
    case statusChange = "Status change"
    case recruiterContact = "Recruiter contact"
    case interview = "Interview"
    case reminder = "Reminder"
    case note = "Note"

    var id: String { rawValue }
}

@Model
final class ApplicationRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var companyName: String
    var jobTitle: String
    var location: String
    var salary: String
    var jobAdvertURL: String
    var dateApplied: Date
    var statusRawValue: String
    var notes: String
    var jobDescription: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify) var cvDocument: CVDocument?
    @Relationship(deleteRule: .nullify) var coverLetter: CoverLetterDocument?
    @Relationship(deleteRule: .cascade) var recruiter: RecruiterContact?
    @Relationship(deleteRule: .cascade) var reminders: [Reminder]
    @Relationship(deleteRule: .cascade) var timelineEvents: [TimelineEvent]

    init(
        id: UUID = UUID(),
        companyName: String,
        jobTitle: String,
        location: String = "",
        salary: String = "",
        jobAdvertURL: String = "",
        dateApplied: Date = .now,
        status: ApplicationStatus = .applied,
        notes: String = "",
        jobDescription: String = "",
        cvDocument: CVDocument? = nil,
        coverLetter: CoverLetterDocument? = nil,
        recruiter: RecruiterContact? = nil,
        reminders: [Reminder] = [],
        timelineEvents: [TimelineEvent] = []
    ) {
        self.id = id
        self.companyName = companyName
        self.jobTitle = jobTitle
        self.location = location
        self.salary = salary
        self.jobAdvertURL = jobAdvertURL
        self.dateApplied = dateApplied
        self.statusRawValue = status.rawValue
        self.notes = notes
        self.jobDescription = jobDescription
        self.createdAt = .now
        self.updatedAt = .now
        self.cvDocument = cvDocument
        self.coverLetter = coverLetter
        self.recruiter = recruiter
        self.reminders = reminders
        self.timelineEvents = timelineEvents
    }

    var status: ApplicationStatus {
        get { ApplicationStatus(rawValue: statusRawValue) ?? .applied }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = .now
        }
    }

    var displayTitle: String {
        "\(jobTitle) at \(companyName)"
    }

    var sortedTimelineEvents: [TimelineEvent] {
        timelineEvents.sorted { $0.date > $1.date }
    }

    var sortedReminders: [Reminder] {
        reminders.sorted { $0.dueDate < $1.dueDate }
    }
}

@Model
final class CVDocument: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var fileName: String
    var contentTypeIdentifier: String
    @Attribute(.externalStorage) var fileData: Data?
    var summary: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        fileName: String,
        contentTypeIdentifier: String = "application/pdf",
        fileData: Data? = nil,
        summary: String = ""
    ) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.contentTypeIdentifier = contentTypeIdentifier
        self.fileData = fileData
        self.summary = summary
        self.createdAt = .now
        self.updatedAt = .now
    }

    var fileSizeDescription: String {
        guard let fileData else { return "No file attached" }
        return ByteCountFormatter.string(fromByteCount: Int64(fileData.count), countStyle: .file)
    }

    var isPDF: Bool {
        contentTypeIdentifier.localizedLowercase.contains("pdf") || fileName.localizedLowercase.hasSuffix(".pdf")
    }
}

@Model
final class CoverLetterDocument: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var fileName: String
    var contentTypeIdentifier: String
    @Attribute(.externalStorage) var fileData: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        fileName: String,
        contentTypeIdentifier: String = "application/pdf",
        fileData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.contentTypeIdentifier = contentTypeIdentifier
        self.fileData = fileData
        self.createdAt = .now
    }

    var fileSizeDescription: String {
        guard let fileData else { return "No file attached" }
        return ByteCountFormatter.string(fromByteCount: Int64(fileData.count), countStyle: .file)
    }

    var isPDF: Bool {
        contentTypeIdentifier.localizedLowercase.contains("pdf") || fileName.localizedLowercase.hasSuffix(".pdf")
    }
}

@Model
final class RecruiterContact: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var phoneNumber: String
    var email: String

    init(
        id: UUID = UUID(),
        name: String = "",
        phoneNumber: String = "",
        email: String = ""
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
    }

    var hasDetails: Bool {
        !name.isEmpty || !phoneNumber.isEmpty || !email.isEmpty
    }
}

@Model
final class Reminder: Identifiable {
    @Attribute(.unique) var id: UUID
    var applicationID: UUID?
    var applicationTitle: String
    var title: String
    var detail: String
    var dueDate: Date
    var typeRawValue: String
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        applicationID: UUID? = nil,
        applicationTitle: String = "",
        title: String,
        detail: String = "",
        dueDate: Date,
        type: ReminderType,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.applicationID = applicationID
        self.applicationTitle = applicationTitle
        self.title = title
        self.detail = detail
        self.dueDate = dueDate
        self.typeRawValue = type.rawValue
        self.isCompleted = isCompleted
        self.createdAt = .now
    }

    var type: ReminderType {
        get { ReminderType(rawValue: typeRawValue) ?? .followUp }
        set { typeRawValue = newValue.rawValue }
    }
}

@Model
final class TimelineEvent: Identifiable {
    @Attribute(.unique) var id: UUID
    var applicationID: UUID?
    var date: Date
    var title: String
    var detail: String
    var kindRawValue: String

    init(
        id: UUID = UUID(),
        applicationID: UUID? = nil,
        date: Date = .now,
        title: String,
        detail: String = "",
        kind: TimelineEventKind = .note
    ) {
        self.id = id
        self.applicationID = applicationID
        self.date = date
        self.title = title
        self.detail = detail
        self.kindRawValue = kind.rawValue
    }

    var kind: TimelineEventKind {
        get { TimelineEventKind(rawValue: kindRawValue) ?? .note }
        set { kindRawValue = newValue.rawValue }
    }
}
