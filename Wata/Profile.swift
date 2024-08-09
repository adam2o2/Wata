import SwiftUI

struct Profile: View {
    var body: some View {
        VStack {
            ZStack {
                GeometryReader { geometry in
                    // Image with corner radius and white border
                    Image("water1")
                        .resizable()
                        .frame(width: 280, height: 390)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                }
                .offset(x: 60, y: 210)
            }
            .frame(height: 250) // Adjust frame height to avoid overlap

            Spacer() // Add spacer to push HStack to the bottom
            
            HStack {
                NavigationLink(destination: HomeView(username: "SampleUser", capturedImage: UIImage(named: "sample_image"))) {
                    Image("house2")
                        .resizable()
                        .frame(width: 38, height: 38)
                        .padding()
                        .offset(x: 20)
                }
                Spacer()
                Image("net")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding()
                Spacer()
                Image("profile1")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding()
                    .offset(x: -20)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, -18) // Adjust padding to place HStack correctly
        }
        .navigationBarBackButtonHidden(true) // Hide back button
    }
}

#Preview {
    NavigationView {
        Profile()
    }
}
