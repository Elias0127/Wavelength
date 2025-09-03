import Foundation
import CoreData

extension JournalEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JournalEntry> {
        return NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
    }

    @NSManaged public var counselorReply: String?
    @NSManaged public var date: Date?
    @NSManaged public var favorite: Bool
    @NSManaged public var feeling: String?
    @NSManaged public var id: UUID?
    @NSManaged public var mode: String?
    @NSManaged public var tags: [String]?
    @NSManaged public var title: String?
    @NSManaged public var transcript: String?
    @NSManaged public var valenceSeries: [Double]?

}
