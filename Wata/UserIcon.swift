import SwiftUI

struct UserIcon: View {
    @Binding var username: String
    var iconName: String
    var iconAction: () -> Void
    
    @State private var isPressed = false // State to control the bounce effect

    var body: some View {
        HStack(spacing: 80) {
            Text(username)
                .font(.system(size: 35, weight: .bold, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.leading, 20)
                .padding(.top, 20)
                .frame(minWidth: 200, alignment: .leading)
                .offset(x: -30)

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
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                    .offset(x: 20)
                    .frame(width: 53, height: 50)
                    .scaleEffect(isPressed ? 0 : 1.0) // Scale to zero on press
                    .opacity(isPressed ? 0 : 1) // Hide the icon on press
            }
        }
    }
}

#Preview {
    UserIcon(username: .constant("Adam"), iconName: "calendar") {
        print("Icon tapped")
    }
}
