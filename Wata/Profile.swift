import SwiftUI

struct Profile: View {
    var body: some View {
        VStack {
            Text("Hello, World!")

            HStack {
                NavigationLink(destination: HomeView(username: "SampleUser", capturedImage: UIImage(named: "sample_image"))) {
                    Image("house2") // Replace with your "house2" icon
                        .resizable()
                        .frame(width: 38, height: 38)
                        .padding()
                        .offset(x: 20)
                }
                Spacer()
                Image("net") // Replace with your "net" icon
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding()
                Spacer()
                Image("profile1") // Replace with your "profile1" icon
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding()
                    .offset(x: -20)
            }
            .frame(maxWidth: .infinity)
            .offset(y: 350)
        }
        .navigationBarBackButtonHidden(true) // Hide back button
    }
}

#Preview {
    NavigationView {
        Profile()
    }
}
