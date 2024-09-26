import SwiftUI
import Pow

struct SplashScreen: View {
    @State private var isPressed = false
    @State private var isAnimating = false // To trigger the water droplet spray
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            // Blurred edges overlay
            blurredEdges()

            Image("wattaicon")  // Make sure your app icon is named correctly in your assets
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .scaleEffect(isPressed ? 0.8 : 1.0)  // Automatically scale down
                .onAppear {
                    // Start the scale down animation automatically
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isPressed = true  // Scale down the image
                    }
                    
                    // Trigger the water droplet animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isAnimating = true
                    }

                    // Automatically return to original scale after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.spring()) {
                            isPressed = false  // Scale back to normal
                        }
                        
                        // Stop water droplet animation after the press ends
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isAnimating = false
                        }
                    }
                }
                .changeEffect(
                    .spray(origin: UnitPoint(x: 0.5, y: 0.5)) {
                        Image(systemName: "drop.fill")  // Water droplet icon
                            .foregroundStyle(.blue)
                    }, value: isAnimating)  // Water droplet animation when isAnimating is true
        }
    }
    
    // Blur effect as blue edges around the screen
    func blurredEdges() -> some View {
        ZStack {
            // Top blur
            Color.blue.opacity(0.3)
                .frame(height: 40)
                .blur(radius: 30)
                .offset(y: -UIScreen.main.bounds.height / 2 + 1)
            
            // Bottom blur
            Color.blue.opacity(0.3)
                .frame(height: 40)
                .blur(radius: 30)
                .offset(y: UIScreen.main.bounds.height / 2 - 1)
            
            // Left blur
            Color.blue.opacity(0.3)
                .frame(width: 40)
                .blur(radius: 30)
                .offset(x: -UIScreen.main.bounds.width / 2 + 1)
            
            // Right blur
            Color.blue.opacity(0.3)
                .frame(width: 40)
                .blur(radius: 30)
                .offset(x: UIScreen.main.bounds.width / 2 - 1)
        }
        .ignoresSafeArea() // Ensure it covers the whole screen
    }
}

#Preview {
    SplashScreen()
}
