import SwiftUI

struct UsernameView: View {
    @State private var isPressed = false // State variable for the button press animation
    @State private var username: String = "" // State variable to store the entered username

    var body: some View {
        ZStack {
            // Background color box
            Rectangle()
                .fill(Color(hex: "#EDEDED"))
                .frame(width: 270, height: 80) // Keep the original size for the box
                .cornerRadius(20) // Rounded corners for the box

            VStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Create a username")
                        .font(.system(size: 35)) // Font size for the title text
                        .fontWeight(.bold)
                        .offset(x: 10) // Horizontal offset for alignment
                    
                    Text("Please make it under 10 characters")
                        .font(.system(size: 20)) // Font size for the subtitle text
                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                        .fontWeight(.bold)
                        .offset(y: -4) // Minor vertical offset for alignment
                }
                .padding(.horizontal, 10) // Horizontal padding
                .padding(.top, 70) // Adjust top padding if needed

                Spacer()

                // TextField inside the box for username input
                TextField("Enter Username", text: $username)
                    .padding()
                    .frame(width: 270, height: 60) // Same width and height as the box
                    .cornerRadius(20) // Rounded corners for the text field
                    .padding(.bottom, 261) // Padding from the bottom of the box
                    .offset(x: 55)
                    .fontWeight(.bold)

                // Button
                Button(action: {
                    // Add your button action here
                    print("Button pressed with username: \(username)")
                }) {
                    HStack {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    .padding()
                    .frame(width: 270, height: 60)
                    .background(Color.black) // Button color is black
                    .cornerRadius(30)
                    .scaleEffect(isPressed ? 1.1 : 1.0) // Bounce effect
                    .shadow(radius: 10)
                }
                .buttonStyle(PlainButtonStyle())
                .onTapGesture {
                    withAnimation {
                        isPressed.toggle()
                    }
                    triggerHapticFeedback()
                }
                .padding(.horizontal)
                .padding(.bottom, 20) // Padding from the bottom of the view
            }
        }
        .onAppear {
            prepareHaptics()
        }
    }

    // Function to prepare haptics
    private func prepareHaptics() {
        // Prepare haptic feedback
    }

    // Function to trigger haptic feedback
    private func triggerHapticFeedback() {
        // Trigger haptic feedback
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1 // Bypass the '#' character
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    UsernameView()
}
