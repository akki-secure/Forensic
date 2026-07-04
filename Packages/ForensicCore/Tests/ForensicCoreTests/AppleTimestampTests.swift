import Foundation
import Testing
@testable import ForensicCore

@Suite("AppleTimestamp")
struct AppleTimestampTests {

    @Test("Reference epoch is exactly 2001-01-01T00:00:00Z")
    func referenceEpoch() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: AppleEpoch.referenceDate
        )
        #expect(components.year == 2001)
        #expect(components.month == 1)
        #expect(components.day == 1)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("Seconds convention: zero maps to the reference date")
    func secondsZero() {
        #expect(AppleAbsoluteTimeSeconds(0).date == AppleEpoch.referenceDate)
    }

    @Test("Seconds convention: known Calendar.sqlitedb-style value")
    func secondsKnownValue() {
        // 2024-01-01T00:00:00Z is 725760000 seconds after 2001-01-01T00:00:00Z
        // (1704067200 unix time - 978307200 unix time for the 2001 epoch).
        let raw = 725760000.0
        let date = AppleAbsoluteTimeSeconds(raw).date
        #expect(date.timeIntervalSince1970 == 1704067200)
    }

    @Test("Seconds convention: negative (pre-2001) values are supported")
    func secondsNegative() {
        let date = AppleAbsoluteTimeSeconds(-31536000).date // exactly one 365-day year earlier
        #expect(date.timeIntervalSince1970 == AppleEpoch.referenceDate.timeIntervalSince1970 - 31536000)
    }

    @Test("Nanoseconds convention: zero maps to the reference date")
    func nanosecondsZero() {
        #expect(AppleAbsoluteTimeNanoseconds(0).date == AppleEpoch.referenceDate)
    }

    @Test("Nanoseconds convention: divides by 1e9 before adding to the epoch")
    func nanosecondsKnownValue() {
        // A chat.db-style raw value the user actually worked with in their manual workflow.
        let raw: Int64 = 767338700136249088
        let expectedSecondsSinceEpoch = Double(raw) / 1_000_000_000
        let date = AppleAbsoluteTimeNanoseconds(raw).date
        #expect(date.timeIntervalSince1970 == AppleEpoch.referenceDate.timeIntervalSince1970 + expectedSecondsSinceEpoch)
    }

    @Test("Nanoseconds convention: large values near real-world magnitude stay finite and ordered")
    func nanosecondsOrdering() {
        let earlier = AppleAbsoluteTimeNanoseconds(767338283856999936).date
        let later = AppleAbsoluteTimeNanoseconds(767338700136249088).date
        #expect(earlier < later)
    }

    @Test("Using the seconds formula on a nanosecond-scale raw value produces a wildly wrong (far-future) date")
    func crossConventionMismatchIsDetectable() {
        // This encodes the exact bug class the user hit repeatedly: applying the
        // Calendar/Reminders (seconds) formula to a chat.db (nanoseconds) raw value.
        let chatDBRaw: Int64 = 767338700136249088
        let wrongDate = AppleAbsoluteTimeSeconds(Double(chatDBRaw)).date
        let correctDate = AppleAbsoluteTimeNanoseconds(chatDBRaw).date

        // The mismatched interpretation lands billions of years away from the
        // correct one -- i.e. obviously wrong, which is the point of having
        // distinct types rather than one ambiguous conversion function.
        let driftYears = abs(wrongDate.timeIntervalSince(correctDate)) / (365.25 * 24 * 3600)
        #expect(driftYears > 1_000_000_000)
    }

    @Test("guessConvention picks nanoseconds for chat.db-scale magnitudes")
    func guessConventionNanoseconds() {
        #expect(AppleTimestamp.guessConvention(forRawValue: 767338700136249088) == .appleAbsoluteNanoseconds)
    }

    @Test("guessConvention picks seconds for Calendar/Reminders-scale magnitudes")
    func guessConventionSeconds() {
        #expect(AppleTimestamp.guessConvention(forRawValue: 726192000) == .appleAbsoluteSeconds)
    }

    @Test("TimestampConvention.date(fromRawValue:) matches the typed wrappers for both conventions")
    func conventionEnumMatchesTypedWrappers() {
        let secondsRaw = 726192000.0
        #expect(
            TimestampConvention.appleAbsoluteSeconds.date(fromRawValue: secondsRaw)
                == AppleAbsoluteTimeSeconds(secondsRaw).date
        )

        let nanosecondsRaw = 767338700136249088.0
        #expect(
            TimestampConvention.appleAbsoluteNanoseconds.date(fromRawValue: nanosecondsRaw)
                == AppleAbsoluteTimeNanoseconds(Int64(nanosecondsRaw)).date
        )
    }

    @Test("TimestampConvention.unixSeconds and unixMilliseconds convert correctly")
    func unixConventions() {
        #expect(TimestampConvention.unixSeconds.date(fromRawValue: 1704067200) == Date(timeIntervalSince1970: 1704067200))
        #expect(TimestampConvention.unixMilliseconds.date(fromRawValue: 1704067200000) == Date(timeIntervalSince1970: 1704067200))
    }

    @Test("fromCalendarOrReminders and fromChatDB convenience functions match the typed wrappers")
    func convenienceFunctionsMatchTypedWrappers() {
        #expect(AppleTimestamp.fromCalendarOrReminders(726192000) == AppleAbsoluteTimeSeconds(726192000).date)
        #expect(AppleTimestamp.fromChatDB(767338700136249088) == AppleAbsoluteTimeNanoseconds(767338700136249088).date)
    }
}
