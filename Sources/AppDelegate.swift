import AppKit
import SwiftUI

class InfoDataFetcher: ObservableObject {
    @Published var infoData: InfoData = InfoData(
        maxQuota: 0,
        remaining: 0,
        user: "Loading...",
        ipv4: "Loading...",
        ipv6: "Loading...",
        status: "Loading..."
    )
    
    // Timer or Network Fetch
    var timer: Timer?

    init() {
        fetchData() // Initial fetch
        startTimer() // Fetch every 1 minute
    }
    
    func fetchData() {
        // Simulated data fetch, replace with real HTTP request
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            DispatchQueue.main.async {
                Task {
                    self.infoData = try await fetchInfoData()
                }
            }
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            // print("Fetching data...")
            self.fetchData()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var eventMonitor: EventMonitor?


    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: "Status Bar Icon")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Setup the popover with SwiftUI view
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 200)
        popover?.behavior = .transient // Disappears when clicking outside
        popover?.contentViewController = NSHostingController(rootView: ContentView())

        // Monitor events to close popover when clicking outside
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(event)
            }
        }
    }

    @objc func togglePopover() {
        if let button = statusItem?.button {
            if let popover = popover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    eventMonitor?.start() // Start monitoring clicks outside popover
                }
            }
        }
    }
}

// Event monitor to close the popover when clicking outside
class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

struct ContentView: View {
    @ObservedObject var fetcher = InfoDataFetcher()
    var data: InfoData { fetcher.infoData }
    @State private var isAuthenticated = false
    
    var body: some View {
        if data.status != "Non Authenticated"{
            // InfoDataView(fetcher: fetcher) // Show the info data view
            LoginView(fetcher: fetcher)
        } else {
            LoginView(fetcher: fetcher) // Show the login form
        }
    }
}