import Foundation
import CoreData

extension AppSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppSettings> {
        return NSFetchRequest<AppSettings>(entityName: "AppSettings")
    }

    @NSManaged public var hasCompletedOnboarding: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var mode: String?
    @NSManaged public var currentPrompt: String?

}
