import SwiftUI
import UIKit

struct ConfirmView: View {
    var image: UIImage?
    var onRetake: () -> Void
    
    @State private var navigateToUsernameView = false
    @State private var isButtonPressed = false

    var body: some View {
        NavigationView {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Color.black.edgesIgnoringSafeArea(.all)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Button(action: onRetake) {
                            Image(systemName: "arrow.clockwise")
                                .resizable()
                                .frame(width: 32, height: 38)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.leading, 40)
                        
                        Spacer()
                        
                        NavigationLink(destination: UsernameView(), isActive: $navigateToUsernameView) {
                            Text("Looks good")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .font(.system(size: 22))
                                .frame(width: 230, height: 62)
                                .background(Color.white)
                                .cornerRadius(35)
                                .shadow(radius: 5)
                                .scaleEffect(isButtonPressed ? 0.95 : 1.0) // Scale animation
                                .animation(.spring(response: 0.2, dampingFraction: 0.5, blendDuration: 0), value: isButtonPressed)
                                .padding() // Increase touch area
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.1)
                                .onChanged { _ in
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    isButtonPressed = true
                                }
                                .onEnded { _ in
                                    isButtonPressed = false
                                    navigateToUsernameView = true
                                }
                        )
                        .padding(.trailing, 40)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

// Preview for ConfirmView
struct ConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmView(
            image: UIImage(named: "sample_image"),
            onRetake: { print("Retake action") }
        )
    }
}
