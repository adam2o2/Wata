import SwiftUI

struct UserIcon: View {
    @Binding var username: String
    var iconName: String
    var iconAction: () -> Void
    
    @State private var isPressed = false // State to control the bounce effect

    var body: some View {
        HStack(spacing: 80) {
            Text(username)
                .font(.system(size: 35))
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                    isPressed = false
                }
            }) {
                Image(iconName)
                    .resizable()
                    .foregroundColor(.white)
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                    .offset(x: 20)
                    .frame(width: 53, height: 50)
                    .scaleEffect(isPressed ? 0.8 : 1.0)
            }
        }
    }
}

#Preview {
    UserIcon(username: .constant("Adam"), iconName: "calendar") {
        print("Icon tapped")
    }
}
