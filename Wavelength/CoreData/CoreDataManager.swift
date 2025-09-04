import CoreData
import CryptoKit
import Foundation
import Security


@MainActor
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()

    
    private let modelName = "WavelengthModel"
    private let keychainService = "na.Wavelength.encryption"
    private let keychainAccount = "database_key"

    lazy var persistentContainer: NSPersistentContainer = {
        
        print("Creating persistent Core Data store.")

        
        let model = NSManagedObjectModel()

        
        let journalEntryEntity = NSEntityDescription()
        journalEntryEntity.name = "JournalEntry"
        journalEntryEntity.managedObjectClassName = "JournalEntry"

        
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let dateAttribute = NSAttributeDescription()
        dateAttribute.name = "date"
        dateAttribute.attributeType = .dateAttributeType
        dateAttribute.isOptional = false

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = true

        let transcriptAttribute = NSAttributeDescription()
        transcriptAttribute.name = "transcript"
        transcriptAttribute.attributeType = .stringAttributeType
        transcriptAttribute.isOptional = true

        let counselorReplyAttribute = NSAttributeDescription()
        counselorReplyAttribute.name = "counselorReply"
        counselorReplyAttribute.attributeType = .stringAttributeType
        counselorReplyAttribute.isOptional = true

        let feelingAttribute = NSAttributeDescription()
        feelingAttribute.name = "feeling"
        feelingAttribute.attributeType = .stringAttributeType
        feelingAttribute.isOptional = true

        let modeAttribute = NSAttributeDescription()
        modeAttribute.name = "mode"
        modeAttribute.attributeType = .stringAttributeType
        modeAttribute.isOptional = true

        let favoriteAttribute = NSAttributeDescription()
        favoriteAttribute.name = "favorite"
        favoriteAttribute.attributeType = .booleanAttributeType
        favoriteAttribute.isOptional = false
        favoriteAttribute.defaultValue = false

        let tagsAttribute = NSAttributeDescription()
        tagsAttribute.name = "tags"
        tagsAttribute.attributeType = .transformableAttributeType
        tagsAttribute.isOptional = true
        tagsAttribute.valueTransformerName = "NSSecureUnarchiveFromData"

        let valenceSeriesAttribute = NSAttributeDescription()
        valenceSeriesAttribute.name = "valenceSeries"
        valenceSeriesAttribute.attributeType = .transformableAttributeType
        valenceSeriesAttribute.isOptional = true
        valenceSeriesAttribute.valueTransformerName = "NSSecureUnarchiveFromData"

        let isAIGeneratedAttribute = NSAttributeDescription()
        isAIGeneratedAttribute.name = "isAIGenerated"
        isAIGeneratedAttribute.attributeType = .booleanAttributeType
        isAIGeneratedAttribute.isOptional = false
        isAIGeneratedAttribute.defaultValue = false

        let originalConversationTurnsDataAttribute = NSAttributeDescription()
        originalConversationTurnsDataAttribute.name = "originalConversationTurnsData"
        originalConversationTurnsDataAttribute.attributeType = .binaryDataAttributeType
        originalConversationTurnsDataAttribute.isOptional = true

        let emotionalStateAttribute = NSAttributeDescription()
        emotionalStateAttribute.name = "emotionalState"
        emotionalStateAttribute.attributeType = .stringAttributeType
        emotionalStateAttribute.isOptional = true

        journalEntryEntity.properties = [
            idAttribute, dateAttribute, titleAttribute, transcriptAttribute,
            counselorReplyAttribute, feelingAttribute, modeAttribute,
            favoriteAttribute, tagsAttribute, valenceSeriesAttribute,
            isAIGeneratedAttribute, originalConversationTurnsDataAttribute, emotionalStateAttribute,
        ]

        
        let appSettingsEntity = NSEntityDescription()
        appSettingsEntity.name = "AppSettings"
        appSettingsEntity.managedObjectClassName = "AppSettings"

        let settingsIdAttribute = NSAttributeDescription()
        settingsIdAttribute.name = "id"
        settingsIdAttribute.attributeType = .UUIDAttributeType
        settingsIdAttribute.isOptional = false

        let hasCompletedOnboardingAttribute = NSAttributeDescription()
        hasCompletedOnboardingAttribute.name = "hasCompletedOnboarding"
        hasCompletedOnboardingAttribute.attributeType = .booleanAttributeType
        hasCompletedOnboardingAttribute.isOptional = false
        hasCompletedOnboardingAttribute.defaultValue = false

        let settingsModeAttribute = NSAttributeDescription()
        settingsModeAttribute.name = "mode"
        settingsModeAttribute.attributeType = .stringAttributeType
        settingsModeAttribute.isOptional = true

        let currentPromptAttribute = NSAttributeDescription()
        currentPromptAttribute.name = "currentPrompt"
        currentPromptAttribute.attributeType = .stringAttributeType
        currentPromptAttribute.isOptional = true

        appSettingsEntity.properties = [
            settingsIdAttribute, hasCompletedOnboardingAttribute,
            settingsModeAttribute, currentPromptAttribute,
        ]

        
        model.entities = [journalEntryEntity, appSettingsEntity]

        
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true

        
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first!
        let storeURL = documentsDirectory.appendingPathComponent("\(modelName).sqlite")
        description.url = storeURL

        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data persistent store failed: \(error.localizedDescription)")
            } else {
                print("Core Data persistent store loaded successfully.")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    
    private init() {}

    
    private func getEncryptionKey() -> Data {
        
        if let existingKey = retrieveKeyFromKeychain() {
            return existingKey
        }

        
        let newKey = generateNewEncryptionKey()
        saveKeyToKeychain(newKey)
        return newKey
    }

    private func generateNewEncryptionKey() -> Data {
        
        var key = Data(count: 32)
        let result = key.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(
                kSecRandomDefault, 32, mutableBytes.bindMemory(to: UInt8.self).baseAddress!)
        }

        guard result == errSecSuccess else {
            fatalError("Failed to generate encryption key")
        }

        return key
    }

    private func saveKeyToKeychain(_ key: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        
        SecItemDelete(query as CFDictionary)

        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            fatalError("Failed to save encryption key to Keychain: \(status)")
        }
    }

    private func retrieveKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    
    func save() {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }

    func deleteAllData() {
        let context = persistentContainer.viewContext

        
        let entryRequest: NSFetchRequest<NSFetchRequestResult> = JournalEntry.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: entryRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }

    
    func performInitialSetup() {
        
        let context = viewContext
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()

        do {
            let count = try context.count(for: request)
            if count == 0 {
                
                migrateMockDataToCoreData()
            }
        } catch {
            print("Failed to check existing data: \(error)")
        }
    }

    private func migrateMockDataToCoreData() {
        let context = viewContext

        
        let appSettings = AppSettings(context: context)
        appSettings.id = UUID()
        appSettings.hasCompletedOnboarding = false
        appSettings.mode = Mode.privateMode.rawValue
        appSettings.currentPrompt = MockEntries.randomPrompt()

        
        for mockEntry in MockEntries.seed {
            let entry = JournalEntry(context: context)
            entry.id = mockEntry.id
            entry.date = mockEntry.date
            entry.title = mockEntry.title
            entry.transcript = mockEntry.transcript
            entry.counselorReply = mockEntry.counselorReply
            entry.tags = mockEntry.tags
            entry.feeling = mockEntry.feeling.rawValue
            entry.valenceSeries = mockEntry.valenceSeries
            entry.mode = mockEntry.mode.rawValue
            entry.favorite = mockEntry.favorite
        }

        save()
    }
}
