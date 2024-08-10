import SwiftUI

struct Profile: View {
    var username: String = "User..." // Default value; adjust as needed
    var capturedImage: UIImage? = UIImage(named: "sample_image") // Optional image

    var body: some View {
        VStack {
            // User name and month name at the top
            VStack(alignment: .center, spacing: 5) {
                Text("\(username)")
                    .font(.system(size: 25))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(getCurrentMonth())
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .offset(x: -60, y: 30)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 30) {
                        ForEach(1...daysInCurrentMonth(), id: \.self) { day in
                            Text("\(day)")
                                .font(.system(size: 20))
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 60, y: 40)
            }
            .offset(x: -60, y: 50)

            ZStack {
                GeometryReader { geometry in
                    Image(uiImage: capturedImage ?? UIImage(named: "water1")!)
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Maintain aspect ratio, fill frame
                        .frame(width: 280, height: 390) // Set frame size
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                }
                .frame(height: 250) // Adjust frame height to avoid overlap
                .offset(x: 67, y: 140)
            }

            Spacer()
            
            HStack {
                NavigationLink(destination: HomeView(username: username, capturedImage: capturedImage)) {
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
            .offset(y: 1)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }

    func daysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        return range.count
    }
}

#Preview {
    Profile()
}
