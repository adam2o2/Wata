//
//  ContentView.swift
//  Wata
//
//  Created by Adam May on 8/2/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top Black Section
            VStack {
                Text("Wata")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 100)
                
                Text("One bottle a day.")
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .clipShape(WaveShape())
            
            // Bottom White Section
            VStack {
                Spacer()
                    
                
                // Sign in with Apple Button
                Button(action: {
                    // Action for sign in
                }) {
                    HStack {
                        Text("Sign in with Apple")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Image(systemName: "applelogo")
                            .foregroundColor(.white)
                            .offset(x: 30)
                    }
                    .padding()
                    .frame(width: 300)
                    .background(Color.black)
                    .cornerRadius(30)
                    .offset(y: 100)
                }
                .padding()
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 10)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY * 0.7))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY * 0.7),
            control1: CGPoint(x: rect.maxX * 0.25, y: rect.maxY * 0.5),
            control2: CGPoint(x: rect.maxX * 0.75, y: rect.maxY * 0.9)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        return path
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

