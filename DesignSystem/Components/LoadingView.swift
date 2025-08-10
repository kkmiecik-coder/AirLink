//
//  LoadingView.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - LoadingView Component

/// Uniwersalny komponent dla stanów ładowania
/// Obsługuje różne style: spinner, skeleton, dots, progress bar
struct LoadingView: View {
    
    // MARK: - Properties
    
    let style: LoadingStyle
    let message: String?
    let progress: Double?  // 0.0 - 1.0 dla progress bar
    let tintColor: Color
    let animated: Bool
    
    // MARK: - State
    
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    
    // MARK: - Initializers
    
    init(
        style: LoadingStyle = .spinner,
        message: String? = nil,
        progress: Double? = nil,
        tintColor: Color = AirLinkColors.primary,
        animated: Bool = true
    ) {
        self.style = style
        self.message = message
        self.progress = progress
        self.tintColor = tintColor
        self.animated = animated
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: style.spacing) {
            
            // Loading indicator
            loadingIndicator
            
            // Message
            if let message = message {
                Text(message)
                    .modifier(style.messageStyle)
                    .multilineTextAlignment(.center)
            }
            
            // Progress percentage (for progress bar)
            if style == .progressBar, let progress = progress {
                Text("\(Int(progress * 100))%")
                    .caption1Style()
            }
        }
        .padding(style.padding)
        .onAppear {
            if animated {
                startAnimations()
            }
        }
    }
    
    // MARK: - Loading Indicator
    
    @ViewBuilder
    private var loadingIndicator: some View {
        switch style {
        case .spinner:
            spinnerView
        case .dots:
            dotsView
        case .pulse:
            pulseView
        case .skeleton:
            skeletonView
        case .progressBar:
            progressBarView
        case .custom(let content):
            content()
        }
    }
    
    // MARK: - Spinner View
    
    private var spinnerView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: tintColor))
            .scaleEffect(style.scale)
    }
    
    // MARK: - Dots View
    
    private var dotsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(tintColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale(for: index))
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
    }
    
    private func dotScale(for index: Int) -> CGFloat {
        if !animated || !isAnimating {
            return 1.0
        }
        
        let delay = Double(index) * 0.2
        let animationTime = (Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1.8)) - delay
        
        if animationTime < 0 {
            return 1.0
        }
        
        let normalizedTime = animationTime.truncatingRemainder(dividingBy: 1.8) / 1.8
        return 1.0 + 0.5 * sin(normalizedTime * 2 * .pi)
    }
    
    // MARK: - Pulse View
    
    private var pulseView: some View {
        Circle()
            .fill(tintColor.opacity(0.6))
            .frame(width: 40, height: 40)
            .scaleEffect(pulseAnimation ? 1.2 : 0.8)
            .opacity(pulseAnimation ? 0.3 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: pulseAnimation
            )
    }
    
    // MARK: - Skeleton View
    
    private var skeletonView: some View {
        VStack(spacing: 8) {
            // Skeleton lines
            ForEach(0..<3, id: \.self) { index in
                skeletonLine(width: skeletonLineWidth(for: index))
            }
        }
    }
    
    private func skeletonLine(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(AirLinkColors.backgroundSecondary)
            .frame(height: 12)
            .frame(maxWidth: width)
            .shimmer()
    }
    
    private func skeletonLineWidth(for index: Int) -> CGFloat {
        switch index {
        case 0: return 200
        case 1: return 150
        case 2: return 100
        default: return 200
        }
    }
    
    // MARK: - Progress Bar View
    
    private var progressBarView: some View {
        VStack(spacing: 8) {
            // Progress bar track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AirLinkColors.backgroundSecondary)
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [tintColor, tintColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress ?? 0.0), height: 8)
                        .animation(AppTheme.current.animations.medium, value: progress)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimations() {
        isAnimating = true
        pulseAnimation = true
        
        // Start rotation for custom animations
        withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

// MARK: - Loading Style

enum LoadingStyle {
    case spinner        // Standardowy iOS spinner
    case dots          // Animowane kropki
    case pulse         // Pulsujący circle
    case skeleton      // Skeleton loading lines
    case progressBar   // Progress bar z procentami
    case custom(() -> AnyView)  // Custom loading view
    
    var scale: CGFloat {
        switch self {
        case .spinner:
            return 1.5
        default:
            return 1.0
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .spinner, .dots, .pulse:
            return AppTheme.current.spacing.md
        case .skeleton:
            return AppTheme.current.spacing.sm
        case .progressBar:
            return AppTheme.current.spacing.sm
        case .custom:
            return AppTheme.current.spacing.md
        }
    }
    
    var padding: EdgeInsets {
        switch self {
        case .spinner, .dots, .pulse:
            return EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        case .skeleton:
            return EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        case .progressBar:
            return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        case .custom:
            return EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        }
    }
    
    var messageStyle: some ViewModifier {
        switch self {
        case .spinner, .dots, .pulse, .custom:
            return AirLinkTextStyles.body
        case .skeleton:
            return AirLinkTextStyles.callout
        case .progressBar:
            return AirLinkTextStyles.subheadline
        }
    }
}

// MARK: - Predefined Loading Views

extension LoadingView {
    
    // MARK: - Common Loading States
    
    /// Standardowe ładowanie z spinnerem
    static func standard(message: String? = "Ładowanie...") -> LoadingView {
        LoadingView(style: .spinner, message: message)
    }
    
    /// Ładowanie z animowanymi kropkami
    static func dots(message: String? = nil) -> LoadingView {
        LoadingView(style: .dots, message: message)
    }
    
    /// Pulsujące ładowanie
    static func pulse(message: String? = nil) -> LoadingView {
        LoadingView(style: .pulse, message: message)
    }
    
    /// Skeleton loading dla list
    static func skeleton() -> LoadingView {
        LoadingView(style: .skeleton, message: nil)
    }
    
    /// Progress bar z procentami
    static func progress(_ value: Double, message: String? = nil) -> LoadingView {
        LoadingView(style: .progressBar, message: message, progress: value)
    }
    
    // MARK: - Context Specific Loading
    
    /// Ładowanie podczas łączenia
    static func connecting() -> LoadingView {
        LoadingView(
            style: .dots,
            message: "Łączenie...",
            tintColor: AirLinkColors.statusConnecting
        )
    }
    
    /// Ładowanie podczas wysyłania wiadomości
    static func sendingMessage() -> LoadingView {
        LoadingView(
            style: .pulse,
            message: "Wysyłanie...",
            tintColor: AirLinkColors.primary
        )
    }
    
    /// Ładowanie podczas skanowania QR
    static func scanningQR() -> LoadingView {
        LoadingView(
            style: .spinner,
            message: "Skanowanie kodu QR...",
            tintColor: AirLinkColors.primary
        )
    }
    
    /// Ładowanie podczas kompresji zdjęcia
    static func compressingImage(_ progress: Double) -> LoadingView {
        LoadingView(
            style: .progressBar,
            message: "Kompresowanie zdjęcia...",
            progress: progress,
            tintColor: AirLinkColors.primary
        )
    }
    
    /// Ładowanie podczas szukania urządzeń
    static func searchingDevices() -> LoadingView {
        LoadingView(
            style: .dots,
            message: "Szukam urządzeń w pobliżu...",
            tintColor: AirLinkColors.statusMesh
        )
    }
    
    /// Minimalne ładowanie (bez tekstu)
    static func minimal() -> LoadingView {
        LoadingView(style: .spinner, message: nil)
    }
    
    /// Custom loading z własnym widokiem
    static func custom<Content: View>(
        message: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> LoadingView {
        LoadingView(
            style: .custom({ AnyView(content()) }),
            message: message
        )
    }
}

// MARK: - Loading Container

/// Container do wyświetlania loading state nad contentem
struct LoadingContainer<Content: View>: View {
    
    let isLoading: Bool
    let loadingView: LoadingView
    let content: Content
    let overlayStyle: LoadingOverlayStyle
    
    init(
        isLoading: Bool,
        loadingView: LoadingView = .standard(),
        overlayStyle: LoadingOverlayStyle = .blur,
        @ViewBuilder content: () -> Content
    ) {
        self.isLoading = isLoading
        self.loadingView = loadingView
        self.overlayStyle = overlayStyle
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading && overlayStyle == .blur ? 2 : 0)
                .opacity(isLoading && overlayStyle == .replace ? 0 : 1)
            
            if isLoading {
                overlayView
            }
        }
        .animation(AppTheme.current.animations.medium, value: isLoading)
    }
    
    @ViewBuilder
    private var overlayView: some View {
        switch overlayStyle {
        case .overlay:
            Rectangle()
                .fill(AirLinkColors.overlayLight)
                .overlay(loadingView)
        case .blur:
            loadingView
        case .replace:
            loadingView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AirLinkColors.background)
        }
    }
}

enum LoadingOverlayStyle {
    case overlay    // Ciemna nakładka z loading view
    case blur       // Blur content + loading view
    case replace    // Zastąp content loading view
}

// MARK: - View Extensions

extension View {
    
    /// Dodaje loading state do widoku
    func loading(
        _ isLoading: Bool,
        style: LoadingView = .standard(),
        overlayStyle: LoadingOverlayStyle = .blur
    ) -> some View {
        LoadingContainer(
            isLoading: isLoading,
            loadingView: style,
            overlayStyle: overlayStyle
        ) {
            self
        }
    }
    
    /// Pokazuje loading podczas wykonywania async operacji
    func loadingTask<T>(
        _ task: @escaping () async throws -> T,
        loadingView: LoadingView = .standard(),
        onComplete: @escaping (Result<T, Error>) -> Void = { _ in }
    ) -> some View {
        LoadingTaskView(
            content: self,
            task: task,
            loadingView: loadingView,
            onComplete: onComplete
        )
    }
}

// MARK: - Loading Task View

struct LoadingTaskView<Content: View, T>: View {
    
    let content: Content
    let task: () async throws -> T
    let loadingView: LoadingView
    let onComplete: (Result<T, Error>) -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        content
            .loading(isLoading, style: loadingView)
            .task {
                await executeTask()
            }
    }
    
    private func executeTask() async {
        isLoading = true
        
        do {
            let result = try await task()
            onComplete(.success(result))
        } catch {
            onComplete(.failure(error))
        }
        
        isLoading = false
    }
}

// MARK: - Demo & Examples

extension LoadingView {
    
    struct Demo: View {
        
        @State private var selectedStyle = 0
        @State private var progress: Double = 0.3
        @State private var showMessage = true
        @State private var isLoading = false
        
        private let styles = [
            ("Spinner", LoadingView.standard()),
            ("Dots", LoadingView.dots()),
            ("Pulse", LoadingView.pulse()),
            ("Skeleton", LoadingView.skeleton()),
            ("Progress", LoadingView.progress(0.3))
        ]
        
        var body: some View {
            VStack(spacing: 24) {
                
                Text("Loading View Demo")
                    .largeTitleStyle()
                
                // Controls
                VStack(spacing: 16) {
                    Picker("Style", selection: $selectedStyle) {
                        ForEach(0..<styles.count, id: \.self) { index in
                            Text(styles[index].0).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if selectedStyle == 4 { // Progress bar
                        VStack {
                            Text("Progress: \(Int(progress * 100))%")
                            Slider(value: $progress, in: 0...1)
                        }
                    }
                    
                    Toggle("Show Message", isOn: $showMessage)
                    Toggle("Loading State", isOn: $isLoading)
                }
                .defaultCard()
                
                Divider()
                
                // Loading examples
                VStack(spacing: 20) {
                    Text("Przykłady")
                        .headlineStyle()
                    
                    // Current style demo
                    currentStyleDemo
                    
                    // Context examples
                    VStack(spacing: 16) {
                        loadingExample("Connecting", LoadingView.connecting())
                        loadingExample("Sending", LoadingView.sendingMessage())
                        loadingExample("Scanning QR", LoadingView.scanningQR())
                        loadingExample("Searching", LoadingView.searchingDevices())
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        
        private var currentStyleDemo: some View {
            Group {
                if selectedStyle == 4 {
                    LoadingView.progress(
                        progress,
                        message: showMessage ? "Kompresowanie..." : nil
                    )
                } else {
                    LoadingView(
                        style: styleForIndex(selectedStyle),
                        message: showMessage ? "Ładowanie..." : nil
                    )
                }
            }
            .defaultCard()
        }
        
        private func loadingExample(_ title: String, _ loading: LoadingView) -> some View {
            HStack {
                Text(title)
                    .bodyStyle()
                Spacer()
                loading
                    .scaleEffect(0.8)
            }
            .padding(.horizontal)
        }
        
        private func styleForIndex(_ index: Int) -> LoadingStyle {
            switch index {
            case 0: return .spinner
            case 1: return .dots
            case 2: return .pulse
            case 3: return .skeleton
            default: return .spinner
            }
        }
    }
}

// MARK: - Preview

#Preview("Loading Styles") {
    VStack(spacing: 32) {
        
        // Basic styles
        VStack(spacing: 20) {
            Text("Loading Styles")
                .headlineStyle()
            
            HStack(spacing: 30) {
                VStack {
                    LoadingView.standard()
                    Text("Spinner")
                        .caption1Style()
                }
                
                VStack {
                    LoadingView.dots()
                    Text("Dots")
                        .caption1Style()
                }
                
                VStack {
                    LoadingView.pulse()
                    Text("Pulse")
                        .caption1Style()
                }
            }
        }
        
        Divider()
        
        // Skeleton and progress
        VStack(spacing: 20) {
            LoadingView.skeleton()
            LoadingView.progress(0.7, message: "Kompresowanie... 70%")
        }
        
        Divider()
        
        // Context specific
        VStack(spacing: 16) {
            LoadingView.connecting()
            LoadingView.sendingMessage()
            LoadingView.searchingDevices()
        }
    }
    .padding()
    .background(AirLinkColors.background)
}

#Preview("Loading Demo") {
    LoadingView.Demo()
}

#Preview("Loading Container") {
    VStack {
        Text("Content with Loading")
            .largeTitleStyle()
        
        Rectangle()
            .fill(AirLinkColors.primaryOpacity20)
            .frame(height: 200)
            .overlay(
                Text("Some content here")
                    .bodyStyle()
            )
    }
    .loading(true, style: .standard(message: "Ładowanie danych..."))
}
