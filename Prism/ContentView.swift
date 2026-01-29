import SwiftUI
import AppKit

struct ContentView: View {
    @State private var currentFolder: URL = URL(fileURLWithPath: "/Applications")
    @State private var folderStack: [URL] = []
    @State private var contents: [URL] = []
    @State private var currentPage: Int = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var finalDragOffset: CGFloat = 0
    @State private var shouldAnimatePageChange: Bool = true

    @State private var isHoveringLeft = false
    @State private var isHoveringRight = false
    
    @State private var startupBounce = false
    
    
    // Scroll state
    @State private var scrollAccumulator: CGFloat = 0
    @State private var scrollBlocked = false
    let scrollThreshold: CGFloat = 100

    // Layout constants
    let horizontalPadding: CGFloat = 200
    let gridTopSpacing: CGFloat = 40
    
    //splash animations constants
    let bigToSmall: Bool = true
    let iconBig: CGFloat = 1.5
    let springCushion: CGFloat = 0.4

    private var screenPoints: CGSize { screenSizeFetcher() }

    private var interItemSpacing: CGFloat {
        screenPoints.height * InterItemSpacingConstant
    }

    private var iconSize: CGFloat {
        screenPoints.height * IconSizeConstant
    }

    // AppStorage
    @AppStorage("appsPerPage") private var appsPerPage: Int = 35
    @AppStorage("invertScroll") private var invertScroll: Bool = false
    @AppStorage("IconSizeConstant") private var IconSizeConstant: Double = 0.09936
    @AppStorage("InterItemSpacingConstant") private var InterItemSpacingConstant: Double = 0.0361
    @AppStorage("persistedAppOrder") private var persistedAppOrder: Data = Data()

    private var columns: Int { 7 }
    private var rows: Int { max(1, appsPerPage / columns) }

    private var pages: [[URL]] {
        stride(from: 0, to: contents.count, by: appsPerPage).map {
            Array(contents[$0..<min($0 + appsPerPage, contents.count)])
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let pageWidth = geometry.size.width

            VStack(spacing: 0) {
                ZStack {
                    HStack(spacing: 0) {
                        ForEach(pages.indices, id: \.self) { index in
                            GridPageView(
                                items: pages[index],
                                columns: columns,
                                iconSize: iconSize,
                                interItemSpacing: interItemSpacing,
                                horizontalPadding: horizontalPadding,
                                startupBounce: startupBounce,
                                iconBig: iconBig,
                                springCushion: springCushion
                            )
                            .frame(width: pageWidth)
                        }
                        .padding(.bottom, interItemSpacing)
                    }
                    .offset(x: -CGFloat(currentPage) * pageWidth + dragOffset + finalDragOffset)
                    .animation(shouldAnimatePageChange ? .easeInOut(duration: 0.4) : nil, value: currentPage)
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.width
                            }
                            .onEnded { value in
                                let offset = invertScroll ? -value.translation.width : value.translation.width
                                let predictedOffset = invertScroll ? -value.predictedEndTranslation.width : value.predictedEndTranslation.width
                                let threshold: CGFloat = 100

                                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.65, blendDuration: 0.3)) {
                                    if (offset < -threshold || predictedOffset < -threshold), currentPage < pages.count - 1 {
                                        currentPage += 1
                                    } else if (offset > threshold || predictedOffset > threshold), currentPage > 0 {
                                        currentPage -= 1
                                    }
                                    finalDragOffset = 0
                                }
                            }
                    )

                    ScrollDetector { deltaX in
                        handleScroll(deltaX: deltaX)
                    }
                    .frame(width: 0, height: 0)

                    Button(action: { goToPreviousPage() }) {
                        ZStack {
                            // Background fills the whole tappable space
                            Rectangle()
                                .fill(Color.white.opacity(0.001))

                            // Your icon
                            Image(systemName: "chevron.left")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 80, height: geometry.size.height)
                    .buttonStyle(PlainButtonStyle())
                    .position(x: 40, y: geometry.size.height / 2)

                    Button(action: { goToNextPage() }) {
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.001))

                            Image(systemName: "chevron.right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 80, height: geometry.size.height)
                    .buttonStyle(PlainButtonStyle())
                    .position(x: geometry.size.width - 40, y: geometry.size.height / 2)
                }
            }
        }
        // MARK: - .onAppear
        .onAppear {
            loadPersistedApps()
            shouldAnimatePageChange = false
            currentPage = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                shouldAnimatePageChange = true
            }

            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 123 { goToPreviousPage(); return nil }
                if event.keyCode == 124 { goToNextPage(); return nil }
                if event.keyCode == 53 {
                    folderStack.isEmpty ? NotificationCenter.default.post(name: .prismEscapePressed, object: nil) : goBack()
                    return nil
                }
                return event
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .prismBecameActive)) { _ in
            shouldAnimatePageChange = false
            currentPage = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                shouldAnimatePageChange = true
            }
        }
        
        .onReceive(NotificationCenter.default.publisher(for: .prismTriggerStartupAnimation)) { _ in
            withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.5, blendDuration: 0.2)) {
                startupBounce.toggle()
            }
            print("prismStartupAnimation notification called")
        }
        
        .onReceive(NotificationCenter.default.publisher(for: .prismMoveApp)) { note in
            if let from = (note.userInfo?["from"] as? URL),
               let to = (note.userInfo?["to"] as? URL) {
                var tilrep: Bool = true
                if tilrep {
                    moveApp(from: from, to: to)
                    print("\(from) \(to)")
                }
                tilrep.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetPrismSession)) { _ in
            resetPrismSession()
        }
        .frame(minWidth: 800, minHeight: 500)
    }

    // MARK: - Scroll & Page Navigation

    func handleScroll(deltaX: CGFloat) {
        guard !scrollBlocked else { return }
        let direction = invertScroll ? -deltaX : deltaX
        scrollAccumulator += direction

        if scrollAccumulator > scrollThreshold {
            goToPreviousPage()
            lockScrollTemporarily()
        } else if scrollAccumulator < -scrollThreshold {
            goToNextPage()
            lockScrollTemporarily()
        }
    }
    
    func resetPrismSession() {
        print("🔁 Resetting Prism session (UI only)")
        currentPage = 0
        folderStack.removeAll()
        loadPersistedApps()
    }

    func lockScrollTemporarily() {
        scrollBlocked = true
        scrollAccumulator = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            scrollBlocked = false
        }
    }

    func goToNextPage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        }
    }

    func goToPreviousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }

    // MARK: - Folder Navigation

    func goBack() {
        if let previous = folderStack.popLast() {
            currentFolder = previous
            contents = AppFetcher.getContents(in: currentFolder)
        }
    }

    func refreshAppList() {
        folderStack.removeAll()
        currentFolder = URL(fileURLWithPath: "/Applications")
        contents = AppFetcher.getContents(in: currentFolder)
        currentPage = 0
    }
    struct IconFramePreferenceKey: PreferenceKey {
        static var defaultValue: [URL: CGRect] = [:]

        static func reduce(value: inout [URL: CGRect], nextValue: () -> [URL: CGRect]) {
            value.merge(nextValue(), uniquingKeysWith: { $1 })
        }
    }
    
    func moveApp(from: URL, to: URL) {
        guard let fromIndex = contents.firstIndex(of: from),
              let toIndex = contents.firstIndex(of: to),
              from != to else { return }

        var updated = contents

        updated.remove(at: fromIndex)
        
        
        updated.insert(from, at: toIndex)

        contents = updated
        savePersistedApps()
    }
    
    func loadPersistedApps() {
        if let decoded = try? JSONDecoder().decode([URL].self, from: persistedAppOrder),
           !decoded.isEmpty {
            contents = decoded
        } else {
            contents = AppFetcher.getContents(in: currentFolder)
            savePersistedApps()
        }
    }

    func savePersistedApps() {
        if let encoded = try? JSONEncoder().encode(contents) {
            persistedAppOrder = encoded
        }
    }
    
    final class IconCache {
        static let shared = IconCache()
        private var cache: [String: NSImage] = [:]

        func icon(for url: URL) -> NSImage {
            if let cached = cache[url.path] {
                return cached
            }

            let icon = NSWorkspace.shared.icon(forFile: url.path)
            cache[url.path] = icon
            return icon
        }
    }
    
    
    

    // MARK: - Grid Page

    struct GridPageView: View {
        let items: [URL]
        let columns: Int
        let iconSize: Double
        let interItemSpacing: CGFloat
        let horizontalPadding: CGFloat
        let startupBounce: Bool
        let iconBig: CGFloat
        let springCushion: CGFloat

        @State private var draggingItem: URL? = nil
        @State private var dragPosition: CGPoint = .zero
        @State private var iconFrames: [URL: CGRect] = [:]

        var body: some View {
            ZStack {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: interItemSpacing), count: columns),
                    spacing: interItemSpacing
                ) {
                    ForEach(items, id: \.self) { item in
                        iconView(for: item)
                            .opacity(draggingItem == item ? 0.0 : 1.0)
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 5)
                                    .onChanged { value in
                                        if draggingItem == nil {
                                            draggingItem = item
                                        }
                                        if let screen = NSScreen.main {
                                            let mousePoint = NSEvent.mouseLocation
                                            let flippedY = screen.frame.height - mousePoint.y
                                            dragPosition = CGPoint(x: mousePoint.x, y: flippedY)
                                        }
                                    }
                                    .onEnded { _ in
                                        if let dragged = draggingItem {
                                            let drop = dragPosition

                                            if let closest = iconFrames.min(by: {
                                                distance($0.value.center, drop) < distance($1.value.center, drop)
                                            }), closest.key != dragged {
                                                NotificationCenter.default.post(
                                                    name: .prismMoveApp,
                                                    object: nil,
                                                    userInfo: ["from": dragged, "to": closest.key]
                                                )
                                            }
                                        }

                                        draggingItem = nil
                                    }
                            )
                            .onTapGesture {
                                if item.pathExtension == "app" {
                                    NotificationCenter.default.post(name: .prismEscapePressed, object: nil)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15){
                                        NSWorkspace.shared.open(item)
                                    }
                                }
                            }
                    }
                }
                .onPreferenceChange(IconFramePreferenceKey.self) { value in
                    iconFrames = value
                }
                .padding(.horizontal, horizontalPadding)

                if let dragged = draggingItem {
                    iconView(for: dragged)
                        .position(dragPosition)
                        .allowsHitTesting(false)
                        .animation(.none, value: dragPosition)
                }
            }
        }

        func iconView(for item: URL) -> some View {
            VStack(spacing: 6) {
                Image(nsImage: IconCache.shared.icon(for: item))
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                Text(item.deletingPathExtension().lastPathComponent)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
            }
            .scaleEffect(startupBounce ? 1 : iconBig)
            .animation(.interactiveSpring(response: 0.5, dampingFraction: springCushion, blendDuration: 0.2), value: startupBounce)
            .frame(width: 100)
            .padding(4)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: IconFramePreferenceKey.self,
                        value: [item: geo.frame(in: .global)]
                    )
                }
            )
        }
        
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let dx = a.x - b.x
    let dy = a.y - b.y
    return sqrt(dx * dx + dy * dy)
}
