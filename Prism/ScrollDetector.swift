import SwiftUI

struct ScrollDetector: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.attach(to: view, onScroll: onScroll)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        private var monitor: Any?

        func attach(to view: NSView, onScroll: @escaping (CGFloat) -> Void) {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
                    onScroll(event.scrollingDeltaX)
                }
                return event
            }
        }

        deinit {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
}
