import Foundation
import Testing
@testable import ForensicCore

@Suite("PlistDocument")
struct PlistDocumentTests {
    private func fixtureURL(_ name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: "plist", subdirectory: "Fixtures")!
    }

    @Test("Parses a dictionary with string, bool, integer, date, array, and nested dict values")
    func parsesSamplePlist() throws {
        let node = try PlistDocument.parse(contentsOf: fixtureURL("sample"))

        guard case .dictionary(let entries) = node else {
            Issue.record("Expected top-level dictionary")
            return
        }
        let dict = Dictionary(uniqueKeysWithValues: entries)

        guard case .string(let name) = dict["Name"] else {
            Issue.record("Expected Name to be a string")
            return
        }
        #expect(name == "Report-final-updated.pdf")

        guard case .bool(let isRecent) = dict["IsRecent"] else {
            Issue.record("Expected IsRecent to be a bool")
            return
        }
        #expect(isRecent == true)

        guard case .number(let byteSize) = dict["ByteSize"] else {
            Issue.record("Expected ByteSize to be a number")
            return
        }
        #expect(byteSize == 48213)

        guard case .date(let lastUsed) = dict["LastUsedDate"] else {
            Issue.record("Expected LastUsedDate to be a date")
            return
        }
        #expect(lastUsed.timeIntervalSince1970 == 1745651991) // 2025-04-26T07:19:51Z

        guard case .array(let tags) = dict["Tags"] else {
            Issue.record("Expected Tags to be an array")
            return
        }
        #expect(tags.count == 2)
        if case .string(let first) = tags[0] {
            #expect(first == "reports")
        } else {
            Issue.record("Expected first tag to be a string")
        }

        guard case .dictionary(let nestedEntries) = dict["Nested"] else {
            Issue.record("Expected Nested to be a dictionary")
            return
        }
        let nested = Dictionary(uniqueKeysWithValues: nestedEntries)
        if case .string(let owner) = nested["Owner"] {
            #expect(owner == "umair-thm")
        } else {
            Issue.record("Expected Nested.Owner to be a string")
        }
    }

    @Test("Throws notAPlist for non-plist data")
    func rejectsGarbageData() {
        let garbage = Data("not a plist".utf8)
        #expect(throws: PlistDocumentError.self) {
            try PlistDocument.parse(data: garbage)
        }
    }
}
