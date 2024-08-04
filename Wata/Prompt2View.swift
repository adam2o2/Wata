import SwiftUI

struct Prompt2View: View {
    var body: some View {
        VStack(spacing: 20) {
            // Title and subtitle
            VStack(alignment: .center, spacing: 5) {
                Text("Track when you finish drinking your bottle")
                    .font(.system(size: 30)) // Use your desired font size
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center) // Center-align the text
            }
            .frame(width: 350, alignment: .center) // Set a fixed width for the VStack
            .padding(.horizontal)
            .offset(y: -120)

            ZStack {
                GeometryReader { geometry in
                    // Image with corner radius and white border
                    Image("water1")
                        .resizable()
                        .frame(width: 260, height: 370)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                }
                .frame(width: 170, height: 230) // Set the frame size to match the images
                .offset(x: -45, y: -50)

                // Faded black circle with 1 and water droplet emoji
                ZStack {
                    Circle()
                        .fill(Color.brown.opacity(10)) // Faded black color
                        .frame(width: 60, height: 60) // Size of the circle

                    HStack(spacing: 1) {
                        Text("1")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        Text("💧")
                            .font(.system(size: 28))
                    }
                }
                .offset(x: -90, y: 165) // Position the circle as needed
            }

            // Sign in with Apple Button
            Button(action: {
                // Action for sign in with Apple button
            }) {
                HStack {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
                .padding()
                .frame(width: 270, height: 60)
                .background(Color.black)
                .cornerRadius(30)
                .offset(y: 150)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    Prompt2View()
}
