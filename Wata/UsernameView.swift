import SwiftUI
import Combine

// KeyboardObserver class to handle keyboard events
class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false })
            .assign(to: \.isKeyboardVisible, on: self)
            .store(in: &cancellables)
    }
}

struct UsernameView: View {
    @State private var isPressed = false // State variable for the button press animation
    @State private var username: String = "" // State variable to store the entered username
    @State private var isActive = false // State variable to control the navigation
    @ObservedObject private var keyboardObserver = KeyboardObserver() // Add this line

    var body: some View {
        NavigationView {
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

                ZStack {
                    Rectangle()
                        .fill(Color(hex: "#EDEDED"))
                        .frame(width: 270, height: 80) // Keep the original size for the box
                        .cornerRadius(20) // Rounded corners for the box

                    TextField("Enter Username", text: $username)
                        .padding()
                        .frame(width: 270, height: 60) // Same width and height as the box
                        .cornerRadius(20) // Rounded corners for the text field
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // NavigationLink to HomeView
                NavigationLink(destination: HomeView(username: username), isActive: $isActive) {
                    EmptyView()
                }

                if !keyboardObserver.isKeyboardVisible {
                    // Button
                    Button(action: {
                        // Activate the navigation link
                        withAnimation {
                            isActive = true
                        }
                        triggerHapticFeedback()
                    }) {
                        HStack {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .padding()
                        .frame(width: 291, height: 62)
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
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20) // Padding from the bottom of the view
                }
            }
            .onAppear {
                prepareHaptics()
            }
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
