import SwiftUI

struct ConfirmView: View {
    var image: UIImage?
    var onRetake: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        ZStack {
            // Background image
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
                    // Retake button with circular arrow repeat icon
                    Button(action: onRetake) {
                        Image(systemName: "arrow.clockwise")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.leading, 40)
                    
                    Spacer()
                    
                    // "Looks Good" button
                    Button(action: onConfirm) {
                        Text("Looks good")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .font(.system(size: 22))
                            .frame(width: 230, height: 70)
                            .background(Color.white)
                            .cornerRadius(35)
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 40)
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// Preview for ConfirmView
struct ConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmView(
            image: UIImage(named: "sample_image"),
            onRetake: { print("Retake action") },
            onConfirm: { print("Confirm action") }
        )
    }
}
