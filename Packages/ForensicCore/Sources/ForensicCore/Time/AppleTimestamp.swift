import Foundation

/// Reference epoch shared by every "Mac absolute time" convention: 2001-01-01T00:00:00Z.
public enum AppleEpoch {
    public static let referenceDate = Date(timeIntervalSince1970: 978307200)
}

/// Seconds since 2001-01-01, stored as a Double.
///
/// Used by: Calendar.sqlitedb (`CalendarItem.start_date`), Reminders
/// (`ZREMCDREMINDER` Core Data `Z*DATE` columns), TCC.db (`last_modified`).
public struct AppleAbsoluteTimeSeconds: RawRepresentable, Hashable, Sendable {
    public let rawValue: Double

    public init(rawValue: Double) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Double) {
        self.rawValue = rawValue
    }

    public var date: Date {
        AppleEpoch.referenceDate.addingTimeInterval(rawValue)
    }
}

/// Nanoseconds since 2001-01-01, stored as an Int64.
///
/// Used by modern chat.db (`message.date`, `message.date_read`). Older chat.db
/// schema versions store these same columns as seconds-since-2001 instead —
/// callers must detect the schema version and choose the right type rather
/// than assuming nanoseconds universally.
public struct AppleAbsoluteTimeNanoseconds: RawRepresentable, Hashable, Sendable {
    public let rawValue: Int64

    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int64) {
        self.rawValue = rawValue
    }

    public var date: Date {
        AppleEpoch.referenceDate.addingTimeInterval(Double(rawValue) / 1_000_000_000)
    }
}

/// How a raw numeric column value should be interpreted as a date.
///
/// Surfaced in the generic SQL/plist browser as an "Interpret as..." picker,
/// since the semantic convention of an arbitrary column isn't known statically
/// there (unlike in a dedicated parser, which always knows its own schema).
public enum TimestampConvention: String, CaseIterable, Sendable {
    case appleAbsoluteSeconds = "Seconds since 2001 (Apple absolute time)"
    case appleAbsoluteNanoseconds = "Nanoseconds since 2001 (chat.db style)"
    case unixSeconds = "Unix epoch (seconds)"
    case unixMilliseconds = "Unix epoch (milliseconds)"

    public func date(fromRawValue raw: Double) -> Date {
        switch self {
        case .appleAbsoluteSeconds:
            return AppleAbsoluteTimeSeconds(raw).date
        case .appleAbsoluteNanoseconds:
            return AppleAbsoluteTimeNanoseconds(Int64(raw)).date
        case .unixSeconds:
            return Date(timeIntervalSince1970: raw)
        case .unixMilliseconds:
            return Date(timeIntervalSince1970: raw / 1000)
        }
    }
}

public enum AppleTimestamp {
    /// Calendar.sqlitedb / Reminders style: seconds since 2001, no division.
    public static func fromCalendarOrReminders(_ raw: Double) -> Date {
        AppleAbsoluteTimeSeconds(raw).date
    }

    /// chat.db style: nanoseconds since 2001, divide by 1e9 first.
    public static func fromChatDB(_ raw: Int64) -> Date {
        AppleAbsoluteTimeNanoseconds(raw).date
    }

    /// Best-effort guess for an arbitrary numeric column of unknown convention.
    ///
    /// Nanosecond-since-2001 values for plausible real-world dates are on the
    /// order of 1e17-1e18; second-since-2001 values are on the order of
    /// 1e8-1e9. This heuristic exists only to seed the UI's "Interpret as..."
    /// picker with a reasonable default — it is never used by a dedicated
    /// parser, which always knows its column's real convention.
    public static func guessConvention(forRawValue raw: Double) -> TimestampConvention {
        abs(raw) > 1_000_000_000_000 ? .appleAbsoluteNanoseconds : .appleAbsoluteSeconds
    }
}
