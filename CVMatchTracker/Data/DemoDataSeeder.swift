import SwiftData
import SwiftUI
import UIKit

@MainActor
enum DemoDataSeeder {
    static func seedIfNeeded(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<ApplicationRecord>()
        let existingApplications = (try? modelContext.fetch(descriptor)) ?? []
        guard existingApplications.isEmpty else { return }

        let productCV = CVDocument(
            name: "Product Manager CV - SaaS",
            fileName: "Product_Manager_SaaS_CV.pdf",
            fileData: samplePDF(
                title: "Product Manager CV - SaaS",
                lines: [
                    "Senior product manager with 7 years building B2B SaaS workflow products.",
                    "Led discovery, roadmap planning, analytics, and launches for regulated customers.",
                    "Highlights: stakeholder management, experimentation, onboarding, retention, pricing."
                ]
            ),
            summary: "SaaS-focused CV emphasizing discovery, roadmap ownership, analytics, and stakeholder leadership."
        )

        let operationsCV = CVDocument(
            name: "Operations CV - Process Improvement",
            fileName: "Operations_Process_CV.pdf",
            fileData: samplePDF(
                title: "Operations CV - Process Improvement",
                lines: [
                    "Operations lead with strong process improvement, vendor management, and reporting experience.",
                    "Built repeatable intake, tracking, and escalation processes across distributed teams.",
                    "Highlights: Excel, dashboards, SLA reporting, documentation, stakeholder communication."
                ]
            ),
            summary: "Operations CV centered on process, reporting, vendor coordination, and documentation."
        )

        let coverLetter = CoverLetterDocument(
            name: "Acme Senior PM Cover Letter",
            fileName: "Acme_Senior_PM_Cover_Letter.pdf",
            fileData: samplePDF(
                title: "Cover Letter - Acme Analytics",
                lines: [
                    "I am excited by Acme Analytics' focus on helping teams understand customer behaviour.",
                    "My recent work combines product discovery, SaaS onboarding, and cross-functional delivery.",
                    "I would welcome the chance to discuss how I can support your roadmap."
                ]
            )
        )

        let appliedDate = Calendar.current.date(byAdding: .day, value: -9, to: .now) ?? .now
        let interviewDate = Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now
        let followUpDate = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
        let responseDeadline = Calendar.current.date(byAdding: .day, value: 6, to: .now) ?? .now

        let acmeRecruiter = RecruiterContact(
            name: "Maya Patel",
            phoneNumber: "+44 7700 900123",
            email: "maya.patel@acme.example"
        )

        let acmeReminder = Reminder(
            applicationID: nil,
            applicationTitle: "Senior Product Manager at Acme Analytics",
            title: "Prepare for Acme phone screen",
            detail: "Review CV version and product analytics examples before the call.",
            dueDate: interviewDate,
            type: .interview
        )

        let acme = ApplicationRecord(
            companyName: "Acme Analytics",
            jobTitle: "Senior Product Manager",
            location: "London / Hybrid",
            salary: "£75,000 - £90,000",
            jobAdvertURL: "https://example.com/jobs/acme-senior-product-manager",
            dateApplied: appliedDate,
            status: .interviewing,
            notes: "Recruiter called about product discovery and enterprise onboarding experience.",
            jobDescription: """
            Acme Analytics is hiring a Senior Product Manager to own the onboarding and customer insights roadmap for its B2B SaaS platform. The role needs strong discovery, analytics, stakeholder management, experimentation, and go-to-market collaboration.
            """,
            cvDocument: productCV,
            coverLetter: coverLetter,
            recruiter: acmeRecruiter,
            reminders: [acmeReminder],
            timelineEvents: [
                TimelineEvent(date: appliedDate, title: "Application submitted", detail: "Used Product Manager CV - SaaS.", kind: .applied),
                TimelineEvent(date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now, title: "Recruiter phone screen booked", detail: "Maya confirmed a 30 minute call.", kind: .interview)
            ]
        )
        acmeReminder.applicationID = acme.id
        acme.timelineEvents.forEach { $0.applicationID = acme.id }

        let northstarRecruiter = RecruiterContact(
            name: "Daniel Hughes",
            phoneNumber: "+44 7700 900456",
            email: "daniel.hughes@northstar.example"
        )
        let northstarReminder = Reminder(
            applicationID: nil,
            applicationTitle: "Operations Manager at Northstar Health",
            title: "Follow up with Northstar",
            detail: "Ask whether the first round shortlist has been completed.",
            dueDate: followUpDate,
            type: .followUp
        )
        let northstar = ApplicationRecord(
            companyName: "Northstar Health",
            jobTitle: "Operations Manager",
            location: "Manchester",
            salary: "£52,000",
            jobAdvertURL: "https://example.com/jobs/northstar-operations-manager",
            dateApplied: Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now,
            status: .applied,
            notes: "Applied through recruiter portal. Role emphasizes reporting and team coordination.",
            jobDescription: """
            Operations Manager needed for a fast-growing healthcare services team. The role covers process improvement, reporting, vendor coordination, SLA management, people leadership, and escalation handling.
            """,
            cvDocument: operationsCV,
            recruiter: northstarRecruiter,
            reminders: [northstarReminder],
            timelineEvents: [
                TimelineEvent(date: Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now, title: "Application submitted", detail: "Used Operations CV - Process Improvement.", kind: .applied)
            ]
        )
        northstarReminder.applicationID = northstar.id
        northstar.timelineEvents.forEach { $0.applicationID = northstar.id }

        let emberReminder = Reminder(
            applicationID: nil,
            applicationTitle: "Product Lead at Ember Studio",
            title: "Response deadline",
            detail: "Hiring team said feedback is expected by this date.",
            dueDate: responseDeadline,
            type: .responseDeadline
        )
        let ember = ApplicationRecord(
            companyName: "Ember Studio",
            jobTitle: "Product Lead",
            location: "Remote",
            salary: "£80,000",
            dateApplied: Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now,
            status: .rejected,
            notes: "Good fit, but role moved forward with candidates from gaming background.",
            jobDescription: "Lead product role for a consumer mobile app studio. Strong experimentation, monetisation, retention, and team leadership required.",
            cvDocument: productCV,
            reminders: [emberReminder],
            timelineEvents: [
                TimelineEvent(date: Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now, title: "Application submitted", detail: "Used Product Manager CV - SaaS.", kind: .applied),
                TimelineEvent(date: Calendar.current.date(byAdding: .day, value: -4, to: .now) ?? .now, title: "Rejected", detail: "Saved notes for future consumer-app applications.", kind: .statusChange)
            ]
        )
        emberReminder.applicationID = ember.id
        ember.timelineEvents.forEach { $0.applicationID = ember.id }

        modelContext.insert(productCV)
        modelContext.insert(operationsCV)
        modelContext.insert(coverLetter)
        modelContext.insert(acme)
        modelContext.insert(northstar)
        modelContext.insert(ember)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not seed demo data: \(error)")
        }
    }

    private static func samplePDF(title: String, lines: [String]) -> Data {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)

        return renderer.pdfData { context in
            context.beginPage()

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.label
            ]

            NSString(string: title).draw(at: CGPoint(x: 48, y: 52), withAttributes: titleAttributes)

            var y = 104.0
            for line in lines {
                let rect = CGRect(x: 48, y: y, width: 516, height: 72)
                NSString(string: line).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: bodyAttributes, context: nil)
                y += 70
            }
        }
    }
}
