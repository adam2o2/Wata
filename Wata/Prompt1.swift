//
//  Prompt1.swift
//  Wata
//
//  Created by Adam May on 9/12/24.
//

import SwiftUI

struct Prompt1: View {
    @State private var flashWhite = false // State variable to control the flash effect
    @State private var isPressed = false // State variable for the shutter button press effect
    private let flashInterval: TimeInterval = 2.0 // Interval for flashing (slower)
    @State private var showPrompt2 = false // State for showing Prompt2
    @State private var scaleEffect: CGFloat = 1.0 // State variable for scaling the entire view
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Environment variable to detect device size class

    var body: some View {
        ZStack {
            if showPrompt2 {
                Prompt2() // No transition, Prompt2 will simply appear
            } else {
                ZStack {
                    // Blurred Background Image
                    Image("water1")
                        .resizable()
                        .frame(width: horizontalSizeClass == .compact ? 500 : 1100, height: horizontalSizeClass == .compact ? 950 : 1500) // Adjusting frame size based on device
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .blur(radius: 20) // Applying blur to background

                    VStack {
                        // Title at the top
                        Text("Take a photo of your main water bottle")
                            .font(.system(size: horizontalSizeClass == .compact ? 28 : 46, weight: .bold, design: .rounded)) // Adjusted font size for iPad
                            .frame(width: horizontalSizeClass == .compact ? 320 : 500) // Adjusted frame for iPad
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .offset(y: horizontalSizeClass == .compact ? 120 : 180) // Adjust offset based on device

                        Spacer()

                        // Centered image with shutter button
                        ZStack {
                            Image("water1")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: horizontalSizeClass == .compact ? 200 : 350, height: horizontalSizeClass == .compact ? 310 : 570) // Adjusted size for iPad
                                .cornerRadius(20) // Added corner radius
                                .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5) // Added shadow
                                .overlay(
                                    // Flash effect overlay
                                    Color.white.opacity(flashWhite ? 0.9 : 0) // Change opacity based on state
                                        .animation(.easeInOut(duration: 0.4), value: flashWhite) // Animate the change
                                        .cornerRadius(20) // Added corner radius
                                )

                            // Shutter Button
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)

                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 50, height: 50)
                            }
                            .scaleEffect(isPressed ? 0.8 : 1.0) // Scale down when pressed
                            .opacity(isPressed ? 0 : 1) // Fade out when pressed
                            .animation(.easeInOut(duration: 0.5), value: isPressed) // Animate the scale and opacity
                            .offset(y: horizontalSizeClass == .compact ? 125 : 250) // Adjust positioning based on device
                            .onAppear {
                                // Auto-press effect
                                autoPressButton()
                            }
                        }
                        .offset(y: horizontalSizeClass == .compact ? 5 : -110)

                        Spacer()

                        // Updated Continue button with the new style
                        Button(action: {
                            // Haptic feedback on button press
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()

                            withAnimation {
                                scaleEffect = 0.8 // Scale down the entire view
                            }
                            showPrompt2 = true // Show Prompt2 without any animation or transition
                        }) {
                            ZStack {
                                // Background for the button
                                RoundedRectangle(cornerRadius: 50)
                                    .fill(Color.black)
                                    .frame(width: horizontalSizeClass == .compact ? 291 : 500, height: horizontalSizeClass == .compact ? 62 : 100) // Adjusted size for iPad
                                    .shadow(radius: 10)

                                // Button Label
                                Text("Continue")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .font(.system(size: horizontalSizeClass == .compact ? 20 : 28)) // Adjust font size for iPad
                            }
                        }
                        .offset(y: horizontalSizeClass == .compact ? -100 : -200) // Adjust offset based on device
                    }
                }
                .scaleEffect(scaleEffect) // Apply scaling to the entire VStack
                .onAppear {
                    // Start the flash effect automatically
                    startFlashing()
                }
            }
        }
    }
    
    // Function to start the flashing effect
    private func startFlashing() {
        Timer.scheduledTimer(withTimeInterval: flashInterval, repeats: true) { timer in
            flashWhite.toggle() // Toggle the flash state

            // Reset flash state after a short duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                flashWhite.toggle() // Reset to original state
            }
        }
    }

    // Function to create the auto-press effect for the shutter button only
    private func autoPressButton() {
        Timer.scheduledTimer(withTimeInterval: flashInterval, repeats: true) { timer in
            isPressed.toggle() // Toggle the pressed state

            // Reset the pressed state after a short duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPressed.toggle() // Return to original state
            }
        }
    }
}

#Preview{
    Prompt1()
}





struct RipplesModifier: ViewModifier {
    var origin: CGPoint
    var elapsedTime: TimeInterval
    var duration: TimeInterval
    var amplitude: Double
    var frequency: Double
    var decay: Double
    var speed: Double

    func body(content: Content) -> some View {
        let shader = ShaderLibrary.Ripple(
            .float2(origin),
            .float(elapsedTime),
            .float(amplitude),
            .float(frequency),
            .float(decay),
            .float(speed)
        )

        content.visualEffect { view, _ in
            view.layerEffect(
                shader,
                maxSampleOffset: maxSampleOffset,
                isEnabled: 0 < elapsedTime && elapsedTime < duration
            )
        }
    }

    var maxSampleOffset: CGSize {
        CGSize(width: amplitude, height: amplitude)
    }
}

struct RipplesEffect: ViewModifier {
    var origin: CGPoint
    var trigger: Int
    var amplitude: Double
    var frequency: Double
    var decay: Double
    var speed: Double

    init(at origin: CGPoint, trigger: Int, amplitude: Double = 20, frequency: Double = 20, decay: Double = 8, speed: Double = 1200) {
        self.origin = origin
        self.trigger = trigger
        self.amplitude = amplitude
        self.frequency = frequency
        self.decay = decay
        self.speed = speed
    }

    func body(content: Content) -> some View {
        content.keyframeAnimator(
            initialValue: 0,
            trigger: trigger
        ) { view, elapsedTime in
            view.modifier(RipplesModifier(
                origin: origin,
                elapsedTime: elapsedTime,
                duration: duration,
                amplitude: amplitude,
                frequency: frequency,
                decay: decay,
                speed: speed
            ))
        } keyframes: { _ in
            MoveKeyframe(0)
            LinearKeyframe(duration, duration: duration)
        }
    }

    var duration: TimeInterval { 3 }
}

import SwiftUI

struct Prompt2: View {
    @State private var count = 0 // Initialize count
    @State private var isLongPressActiveMinus = false
    @State private var scaleEffect: CGFloat = 1.0 // Initialize scale effect
    @State private var rippleTrigger: Int = 0 // Ripple trigger for animation
    @State private var rippleOrigin: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2) // Center of the screen
    @State private var timer: Timer? // Timer to handle the 6-second interval
    @State private var isLongPressActivePlus = false // State to simulate the button scaling
    @State private var navigateToNextView = false // State for navigation to next view
    @State private var isAnimatingPlus = false // State for managing animation of the plus button
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Detect device size class

    var body: some View {
        NavigationStack { // Wrap in NavigationStack for navigation
            ZStack {
                // Blurred Background Image
                Image("water1")
                    .resizable()
                    .frame(width: horizontalSizeClass == .compact ? 500 : 1100, height: horizontalSizeClass == .compact ? 950 : 1500) // Adjust frame size based on device
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .shadow(radius: 10)
                    .blur(radius: 20) // Applying blur to background
                
                VStack {
                    // Title at the top
                    Text("Track how many bottles you've drank")
                        .font(.system(size: horizontalSizeClass == .compact ? 28 : 46, weight: .bold, design: .rounded)) // Adjust font size for iPad
                        .frame(width: horizontalSizeClass == .compact ? 300 : 500) // Adjust frame size based on device
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .offset(y: horizontalSizeClass == .compact ? 120 : 180) // Adjust offset based on device
                    
                    Spacer()
                    
                    // Centered image
                    Image("water1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: horizontalSizeClass == .compact ? 200 : 350, height: horizontalSizeClass == .compact ? 310 : 570) // Adjust size for iPad
                        .cornerRadius(20) // Added corner radius
                        .offset(y: horizontalSizeClass == .compact ? 74 : 0)
                        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5) // Added shadow
                    
                    Spacer()
                    
                    // Added bottles counter section
                    VStack(spacing: 10) {
                        Text("Finished bottles")
                            .font(.system(size: horizontalSizeClass == .compact ? 15 : 25, weight: .bold, design: .rounded)) // Adjust font size for iPad
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(0.6)
                            .offset(y: 10)
                            .scaleEffect(scaleEffect)
                        
                        HStack(spacing: horizontalSizeClass == .compact ? 30 : 50) { // Adjust spacing for iPad
                            // Minus Button
                            ZStack {
                                Circle()
                                    .fill(isLongPressActiveMinus ? Color.red : Color.white.opacity(0.2))
                                    .frame(width: horizontalSizeClass == .compact ? 30 : 50, height: horizontalSizeClass == .compact ? 30 : 50) // Adjust size for iPad
                                    .shadow(color: isLongPressActiveMinus ? Color.red.opacity(0.8) : Color.clear, radius: isLongPressActiveMinus ? 10 : 0)
                                
                                Image(systemName: "minus")
                                    .font(.system(size: horizontalSizeClass == .compact ? 15 : 25)) // Adjust font size for iPad
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(isLongPressActiveMinus ? 1.5 : scaleEffect)
                            .highPriorityGesture(
                                LongPressGesture(minimumDuration: 0.5)
                                    .onChanged { _ in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isLongPressActiveMinus = true
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isLongPressActiveMinus = false
                                        }
                                    }
                            )
                            .disabled(true) // Disable interaction completely
                            
                            Text("\(count)")
                                .font(.system(size: horizontalSizeClass == .compact ? 60 : 100, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .scaleEffect(scaleEffect)
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Text("\(count)")
                                            .font(.system(size: horizontalSizeClass == .compact ? 60 : 100, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                            .opacity(0.18)
                                            .scaleEffect(x: scaleEffect, y: -scaleEffect)
                                            .mask(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.white.opacity(0.5), Color.clear]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .offset(y: horizontalSizeClass == .compact ? 47 : 80) // Adjust offset for iPad
                                    }
                                )
                            
                            // Plus Button
                            ZStack {
                                Circle()
                                    .fill(isLongPressActivePlus ? Color.blue : Color.white.opacity(0.2)) // Change color based on state
                                    .frame(width: horizontalSizeClass == .compact ? 30 : 50, height: horizontalSizeClass == .compact ? 30 : 50) // Adjust size for iPad
                                    .shadow(color: isLongPressActivePlus ? Color.blue.opacity(0.8) : Color.clear, radius: isLongPressActivePlus ? 10 : 0)
                                    .scaleEffect(isAnimatingPlus ? 1.5 : 1.0) // Scale animation
                                
                                Image(systemName: "plus")
                                    .font(.system(size: horizontalSizeClass == .compact ? 15 : 25)) // Adjust font size for iPad
                                    .foregroundColor(.white) // Ensure the plus symbol remains visible
                                    .fontWeight(.bold)
                                    .opacity(1.0) // Keep the opacity at 1.0
                            }
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.5)
                                    .onChanged { _ in
                                        isAnimatingPlus = true // Start animation when long-press is detected
                                        withAnimation(.easeInOut) {
                                            isLongPressActivePlus = true // Change color when pressed
                                        }
                                    }
                                    .onEnded { _ in
                                        isAnimatingPlus = false // Stop animation when the press ends
                                        withAnimation(.easeInOut) {
                                            isLongPressActivePlus = false // Revert color
                                        }
                                    }
                            )
                            .disabled(true) // Disable interaction completely
                        }
                    }
                    .offset(y: horizontalSizeClass == .compact ? -100 : -200)
                    
                    // Updated Continue button with the new style
                    Button(action: {
                        navigateToNextView = true // Navigate on button press
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 50)
                                .fill(Color.black)
                                .frame(width: horizontalSizeClass == .compact ? 291 : 500, height: horizontalSizeClass == .compact ? 62 : 100) // Adjust size for iPad
                                .shadow(radius: 10)
                            
                            Text("Continue")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .font(.system(size: horizontalSizeClass == .compact ? 20 : 28)) // Adjust font size for iPad
                        }
                    }
                    .offset(y: horizontalSizeClass == .compact ? -100 : -200)
                    
                    // NavigationLink for CameraView
                    NavigationLink(
                        destination: CameraView()
                            .navigationBarBackButtonHidden(true) // Hide the back button
                            .edgesIgnoringSafeArea(.all),
                        isActive: $navigateToNextView
                    ) {
                        EmptyView() // Use EmptyView to hide the NavigationLink
                    }
                    .hidden() // Hide the NavigationLink
                }
            }
            .onAppear {
                // Reset states for the plus button when the view appears
                isLongPressActivePlus = false
                isAnimatingPlus = false
                
                // Delay for 3 seconds before starting the automatic long press simulation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Trigger both ripple effect and button animation in sync
                    startAutomaticLongPress()
                }

                // Start timer to increment count
                startCountIncrement()
            }
            .onDisappear {
                timer?.invalidate() // Stop the timer when the view disappears
            }
            .modifier(RipplesEffect(at: rippleOrigin, trigger: rippleTrigger)) // Apply ripple effect here
        }
    }
    
    // Function to simulate long press and ripple effect
    private func startAutomaticLongPress() {
        // Simulate the first long press and trigger ripple effect after the 3-second delay
        rippleOrigin = CGPoint(x: UIScreen.main.bounds.width / 2 + 40, y: UIScreen.main.bounds.height / 2) // Set ripple position

        // Start both button animation and ripple effect together
        withAnimation(.easeInOut(duration: 0.5)) {
            isLongPressActivePlus = true // Change color
            isAnimatingPlus = true // Scale the plus button
            rippleTrigger += 1 // Trigger the first ripple effect in sync with button animation
        }

        // Start a timer to activate ripple effect every 5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            // Change color and scale when the ripple effect starts
            withAnimation(.easeInOut(duration: 0.5)) {
                isLongPressActivePlus = true // Change color
                isAnimatingPlus = true // Scale the plus button
            }
            rippleTrigger += 1 // Trigger ripple effect
            
            // Revert changes back after a brief duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLongPressActivePlus = false // Revert color
                    isAnimatingPlus = false // Stop scaling
                }
            }
        }
    }
    
    private func startCountIncrement() {
        // Start a timer to increment the count every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation {
                count = 1 // Increment the count
            }
        }
    }
}

#Preview {
    Prompt2()
}
