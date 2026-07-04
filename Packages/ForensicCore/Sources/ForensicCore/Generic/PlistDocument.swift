import Foundation

/// A type-erased, UI-renderable representation of an arbitrary plist value.
///
/// Foundation's `PropertyListSerialization` already decodes plists into
/// `Any` (NSDictionary/NSArray/NSString/NSNumber/NSDate/Data/Bool trees).
/// `PlistNode` re-expresses that as a Swift enum so a generic outline view
/// can render any plist without needing a fixed schema.
public indirect enum PlistNode: Sendable {
    case dictionary([(key: String, value: PlistNode)])
    case array([PlistNode])
    case string(String)
    case number(Double)
    case bool(Bool)
    case date(Date)
    case data(Data)
    /// `data` that is actually an NSKeyedArchiver-encoded object graph
    /// (common in some LaunchAgents/recent-items plists). Decoded eagerly
    /// so the outline view doesn't need to special-case raw bytes.
    case keyedArchive(PlistNode)
    case null
}

public enum PlistDocumentError: Error, Sendable {
    case fileNotReadable(path: String, underlying: String)
    case notAPlist(path: String)
}

public enum PlistDocument {
    /// Parses the plist at `url` into a `PlistNode` tree.
    public static func parse(contentsOf url: URL) throws -> PlistNode {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw PlistDocumentError.fileNotReadable(path: url.path, underlying: "\(error)")
        }
        return try parse(data: data, sourcePath: url.path)
    }

    public static func parse(data: Data, sourcePath: String = "<data>") throws -> PlistNode {
        var format = PropertyListSerialization.PropertyListFormat.xml
        guard let root = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: &format
        ) else {
            throw PlistDocumentError.notAPlist(path: sourcePath)
        }
        return node(from: root)
    }

    private static func node(from value: Any) -> PlistNode {
        switch value {
        case let dict as [String: Any]:
            // NSDictionary loses key order; sort for stable, readable output.
            let entries = dict.keys.sorted().map { key in
                (key: key, value: node(from: dict[key]!))
            }
            return .dictionary(entries)
        case let array as [Any]:
            return .array(array.map { node(from: $0) })
        case let string as String:
            return .string(string)
        case let date as Date:
            return .date(date)
        case let bool as Bool:
            // NSNumber-backed Bool must be checked before the generic NSNumber
            // case below, since Bool bridges to NSNumber in Objective-C.
            return .bool(bool)
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool(number.boolValue)
            }
            return .number(number.doubleValue)
        case let data as Data:
            if let unarchived = decodeKeyedArchive(data) {
                return .keyedArchive(unarchived)
            }
            return .data(data)
        default:
            return .null
        }
    }

    /// Best-effort decode of `Data` that is actually an NSKeyedArchiver payload.
    /// Returns `nil` if the bytes are not a keyed archive, in which case the
    /// caller should fall back to treating it as opaque `.data`.
    private static func decodeKeyedArchive(_ data: Data) -> PlistNode? {
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else {
            return nil
        }
        unarchiver.requiresSecureCoding = false
        guard let object = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) else {
            return nil
        }
        unarchiver.finishDecoding()
        return node(from: object)
    }
}
