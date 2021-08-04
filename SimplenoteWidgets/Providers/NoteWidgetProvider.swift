import WidgetKit

struct NoteWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let content: String
    let simperiumKey: String?
}

struct NoteWidgetProvider: IntentTimelineProvider {
    typealias Intent = NoteWidgetIntent
    typealias Entry = NoteWidgetEntry

    let coreDataManager: CoreDataManager!
    let dataController: WidgetDataController!

    init() {
        NSLog("Created a provider")
        do {
            self.coreDataManager = try CoreDataManager(StorageSettings().sharedStorageURL, for: .widgets)
            self.dataController = try WidgetDataController(coreDataManager: coreDataManager)
        } catch {
            fatalError("Couldn't setup dataController")
        }
    }


    func placeholder(in context: Context) -> NoteWidgetEntry {
        return NoteWidgetEntry(date: Date(), title: DemoContent.singleNoteTitle, content: DemoContent.singleNoteContent, simperiumKey: nil)
    }

    func getSnapshot(for configuration: NoteWidgetIntent, in context: Context, completion: @escaping (NoteWidgetEntry) -> Void) {
        let entry = NoteWidgetEntry(date: Date(), title: DemoContent.singleNoteTitle, content: DemoContent.singleNoteContent, simperiumKey: nil)

        completion(entry)
    }

    func getTimeline(for configuration: NoteWidgetIntent, in context: Context, completion: @escaping (Timeline<NoteWidgetEntry>) -> Void) {
        // Confirm valid configuration
        guard let widgetNote = configuration.note,
              let simperiumKey = widgetNote.identifier,
              let dataController = dataController else {
            NSLog("Couldn't find configuration or identifier")
            return
        }

        // Fetch note
        guard let note = dataController.note(forSimperiumKey: simperiumKey) else {
            return
        }

        // Prepare timeline entry for every hour for the next 6 hours
        // Create a new set of entries at the end of the 6 entries
        var entries: [NoteWidgetEntry] = []
        for int in 0..<6 {
            if let date = Date().increased(byHours: int) {
                entries.append(NoteWidgetEntry(date: date, title: note.title, content: note.body, simperiumKey: note.simperiumKey))
            }
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)

        completion(timeline)
    }
}
