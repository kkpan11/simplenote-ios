import Foundation
import SimplenoteFoundation
import SimplenoteSearch
import CoreData

class WidgetResultsController {

    /// Data Controller
    ///
    let managedObjectContext: NSManagedObjectContext

    /// Initialization
    ///
    init(context: NSManagedObjectContext, isPreview: Bool = false) throws {
        if !isPreview {
            guard WidgetDefaults.shared.loggedIn else {
                throw WidgetError.appConfigurationError
            }
        }

        self.managedObjectContext = context
    }

    // MARK: - Notes

    /// Fetch notes with given tag and limit
    /// If no tag is specified, will fetch notes that are not deleted. If there is no limit specified it will fetch all of the notes
    ///
    func notes(filteredBy filter: TagsFilter = .allNotes, limit: Int = .zero) -> [Note]? {
        let request: NSFetchRequest<Note> = fetchRequestForNotes(filteredBy: filter, limit: limit)
        return performFetch(from: request)
    }

    /// Returns note given a simperium key
    ///
    func note(forSimperiumKey key: String) -> Note? {
        return notes()?.first { note in
            note.simperiumKey == key
        }
    }

    func firstNote() -> Note? {
        let fetched = notes(limit: 1)
        return fetched?.first
    }

    /// Creates a predicate for notes given a tag name.  If not specified the predicate is for all notes that are not deleted
    ///
    private func predicateForNotes(filteredBy tagFilter: TagsFilter = .allNotes) -> NSPredicate {
        switch tagFilter {
        case .allNotes:
            return NSPredicate.predicateForNotes(deleted: false)
        case .tag(let tag):
            return NSPredicate.predicateForNotes(tag: tag)
        }
    }

    private func sortDescriptorForNotes() -> NSSortDescriptor {
        return NSSortDescriptor.descriptorForNotes(sortMode: WidgetDefaults.shared.sortMode)
    }

    private func fetchRequestForNotes(filteredBy filter: TagsFilter = .allNotes, limit: Int = .zero) -> NSFetchRequest<Note> {
        let fetchRequest = NSFetchRequest<Note>(entityName: Note.entityName)
        fetchRequest.fetchLimit = limit
        fetchRequest.sortDescriptors = [sortDescriptorForNotes()]
        fetchRequest.predicate = predicateForNotes(filteredBy: filter)

        return fetchRequest
    }

    // MARK: - Tags

    func tags() -> [Tag]? {
        performFetch(from: fetchRequestForTags())
    }

    private func fetchRequestForTags() -> NSFetchRequest<Tag> {
        let fetchRequest = NSFetchRequest<Tag>(entityName: Tag.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor.descriptorForTags()]

        return fetchRequest
    }

    // MARK: Fetching

    private func performFetch<T: NSManagedObject>(from request: NSFetchRequest<T>) -> [T]? {
        do {
            let objects = try managedObjectContext.fetch(request)
            return objects
        } catch {
            NSLog("Couldn't fetch objects: %@", error.localizedDescription)
            return nil
        }
    }
}

enum TagsFilter {
    case allNotes
    case tag(String)
}

extension TagsFilter {
    init(from tag: String?) {
        guard let tag = tag else {
            self = .allNotes
            return
        }
        self = .tag(tag)
    }
}
