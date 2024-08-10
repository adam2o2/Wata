import SwiftUI

struct Profile: View {
    var username: String = "SampleUser" // Provide default value or pass it in as needed

    // Function to get the current month name
    func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }

    // Function to get the number of days in the current month
    func daysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        return range.count
    }

    var body: some View {
        VStack {
            // User name and month name at the top
            VStack(alignment: .center, spacing: 5) {
                Text("\(username)")
                    .font(.system(size: 25))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Displaying the current month name
                Text(getCurrentMonth())
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .offset(x: -60, y: 30)
                
                // Adding the days of the current month below the month name, aligned to the right
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
            .offset(x: -60, y: 50) // Negative x value to move it to the left

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
                .offset(x: 67, y: 140)
            }
            .frame(height: 250) // Adjust frame height to avoid overlap

            Spacer() // Add spacer to push HStack to the bottom
            
            HStack {
                NavigationLink(destination: HomeView(username: username, capturedImage: UIImage(named: "sample_image"))) {
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
        .navigationBarBackButtonHidden(true) // Hide back button
    }
}

#Preview {
    NavigationView {
        Profile()
    }
}
