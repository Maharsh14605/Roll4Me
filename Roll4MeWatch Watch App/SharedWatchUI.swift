//
//  SharedWatchUI.swift
//  Roll4Me
//
//  Created by advait modh on 16/11/25.
//

import SwiftUI

// Little grab-handle style button like iOS bottom bar
struct WatchHandleButton: View {
    var body: some View {
        VStack(spacing: 4) {
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 32, height: 4)
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 24, height: 4)
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(radius: 1, y: 1)
    }
}

// Arc text (smaller for watch)
struct WatchArcText: View {
    let text: String
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double
    var followTangent: Bool = true

    var body: some View {
        ZStack {
            ForEach(Array(text.enumerated()), id: \.offset) { (i, ch) in
                let t = Double(i) / Double(max(text.count - 1, 1))
                let angle = startAngle + (endAngle - startAngle) * t
                let rad = angle * .pi / 180
                let x = cos(rad) * radius
                let y = sin(rad) * radius

                Text(String(ch))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .rotationEffect(.degrees(followTangent ? angle + 90 : 0))
                    .offset(x: x, y: y)
            }
        }
        .frame(width: radius * 2, height: radius * 2)
    }
}

// Speech bubble used for panels
struct WatchSpeechBubble<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

            WatchTriangle()
                .fill(.ultraThinMaterial)
                .frame(width: 16, height: 8)
                .overlay(WatchTriangle().stroke(Color.black.opacity(0.18), lineWidth: 1))
                .offset(x: 40, y: -1)
        }
    }
}

struct WatchTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
