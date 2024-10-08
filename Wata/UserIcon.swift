import SwiftUI

struct UserIcon: View {
    @Binding var username: String
    var iconName: String
    var iconAction: () -> Void
    
    @State private var isPressed = false // State to control the bounce effect
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Detect the device size class

    var body: some View {
        ZStack {
            HStack(spacing: horizontalSizeClass == .compact ? 120 : 120) { // Adjust spacing for iPad
                Text(username)
                    .font(.system(size: horizontalSizeClass == .compact ? 35 : 50, weight: .bold, design: .rounded)) // Adjust font size for iPad
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                    .frame(minWidth: horizontalSizeClass == .compact ? 200 : 300, alignment: .leading) // Adjust width for iPad
                    .offset(x: horizontalSizeClass == .compact ? -30 : -50) // Adjust horizontal offset for iPad

                Button(action: {
                    iconAction()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = true
                    }
                    // Reset the scale and opacity after the animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0)) {
                            isPressed = false
                        }
                    }
                }) {
                    Image(iconName)
                        .resizable()
                        .foregroundColor(.white)
                        .offset(x: horizontalSizeClass == .compact ? 0 : 30) // Adjust horizontal offset for iPad
                        .frame(width: horizontalSizeClass == .compact ? 38 : 65, height: horizontalSizeClass == .compact ? 37 : 65) // Adjust size for iPad
                        .scaleEffect(isPressed ? 0 : 1.0) // Scale to zero on press
                        .opacity(isPressed ? 0 : 1) // Hide the icon on press
                }
            }
        }
        .offset(y: horizontalSizeClass == .compact ? 20 : 340) // Apply offset to the entire ZStack
    }
}

#Preview {
    UserIcon(username: .constant("Adam"), iconName: "calendar") {
        print("Icon tapped")
    }
    .preferredColorScheme(.dark) // Enable dark mode for the preview
}
