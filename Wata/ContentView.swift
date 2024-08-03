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
                    .offset(x: -25)
                
                Text("One bottle a day.")
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                Spacer()
            }
            .offset(x: 30)
            .frame(maxWidth: .infinity, alignment: .leading)
            
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
                    .frame(width: 300, height: 60)
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
        
        // Adjusting the starting Y point to move the wave down
        let waveHeight = rect.maxY * 0.9
        path.move(to: CGPoint(x: 0, y: waveHeight))

        // First wave
        path.addCurve(
            to: CGPoint(x: rect.maxX * 0.5, y: waveHeight),
            control1: CGPoint(x: rect.maxX * 0.25, y: waveHeight - rect.maxY * 0.2),
            control2: CGPoint(x: rect.maxX * 0.25, y: waveHeight + rect.maxY * 0.2)
        )

        // Second wave
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: waveHeight),
            control1: CGPoint(x: rect.maxX * 0.75, y: waveHeight - rect.maxY * 0.2),
            control2: CGPoint(x: rect.maxX * 0.75, y: waveHeight + rect.maxY * 0.2)
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

