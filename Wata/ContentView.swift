import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Title and subtitle
            VStack(alignment: .leading, spacing: 5) {
                Text("Wata")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Helping you stay hydrated")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .offset(y: -70)

            // Image with corner radius and white border
            Image("water1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 300)
                .cornerRadius(15)
                .shadow(radius: 10)

            // Sign in with Apple Button
            Button(action: {
                // Action for sign in with Apple button
            }) {
                HStack {
                    Image(systemName: "applelogo")
                        .foregroundColor(.white)
                        .font(.system(size: 25)) // Adjust the size value as needed
                        .offset(x: 10)
 // Adjust position of the icon
                    Spacer()
                    Text("Sign in with Apple")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .offset(x: -50)
                }
                .padding()
                .frame(width: 300, height: 60)
                .background(Color.black)
                .cornerRadius(30)
                .offset(y: 100)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
