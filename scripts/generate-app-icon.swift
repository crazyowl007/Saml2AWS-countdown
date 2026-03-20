#!/usr/bin/env swift
// Generates a 1024x1024 app icon for SAML2AWS Countdown
// Design: Dark navy rounded rect background, orange shield, white countdown arc

import AppKit
import CoreGraphics

let size: CGFloat = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size),
    pixelsHigh: Int(size),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
let g = ctx.cgContext

// Colors
let navy = CGColor(red: 35/255, green: 47/255, blue: 62/255, alpha: 1)       // #232F3E
let navyLight = CGColor(red: 55/255, green: 71/255, blue: 90/255, alpha: 1)  // lighter navy for gradient
let orange = CGColor(red: 1, green: 153/255, blue: 0, alpha: 1)              // #FF9900
let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
let orangeGlow = CGColor(red: 1, green: 153/255, blue: 0, alpha: 0.3)

// === Background: rounded superellipse ===
let inset: CGFloat = 12
let cornerRadius: CGFloat = 220
let bgRect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// Gradient background
g.saveGState()
g.addPath(bgPath)
g.clip()
let gradientColors = [navyLight, navy] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: [0.0, 1.0])!
g.drawLinearGradient(gradient, start: CGPoint(x: size/2, y: size - inset), end: CGPoint(x: size/2, y: inset), options: [])
g.restoreGState()

// === Shield shape ===
let cx: CGFloat = size / 2
let cy: CGFloat = size / 2 - 20  // shift up slightly
let shieldW: CGFloat = 340
let shieldH: CGFloat = 430

func shieldPath(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat) -> CGMutablePath {
    let path = CGMutablePath()
    let top = cy + h * 0.5
    let bottom = cy - h * 0.5
    let left = cx - w * 0.5
    let right = cx + w * 0.5
    let shoulderY = cy + h * 0.22
    let cornerR: CGFloat = w * 0.12

    // Start at top center
    path.move(to: CGPoint(x: cx, y: top))
    // Top-right curve to right shoulder
    path.addQuadCurve(to: CGPoint(x: right, y: shoulderY), control: CGPoint(x: right - cornerR * 0.2, y: top))
    // Right side down, curving to bottom point
    path.addQuadCurve(to: CGPoint(x: cx, y: bottom), control: CGPoint(x: right, y: cy - h * 0.15))
    // Bottom point up to left shoulder
    path.addQuadCurve(to: CGPoint(x: left, y: shoulderY), control: CGPoint(x: left, y: cy - h * 0.15))
    // Left shoulder up to top
    path.addQuadCurve(to: CGPoint(x: cx, y: top), control: CGPoint(x: left + cornerR * 0.2, y: top))
    path.closeSubpath()
    return path
}

// Shield glow
g.saveGState()
g.addPath(bgPath)
g.clip()
g.setShadow(offset: .zero, blur: 60, color: orangeGlow)
let outerShield = shieldPath(cx: cx, cy: cy, w: shieldW + 20, h: shieldH + 25)
g.addPath(outerShield)
g.setFillColor(orangeGlow)
g.fillPath()
g.restoreGState()

// Shield outline (orange)
let shield = shieldPath(cx: cx, cy: cy, w: shieldW, h: shieldH)
g.addPath(shield)
g.setStrokeColor(orange)
g.setLineWidth(28)
g.setLineJoin(.round)
g.strokePath()

// Shield fill (slightly transparent navy)
let shieldFill = CGColor(red: 30/255, green: 42/255, blue: 56/255, alpha: 0.9)
let innerShield = shieldPath(cx: cx, cy: cy, w: shieldW - 28, h: shieldH - 35)
g.addPath(innerShield)
g.setFillColor(shieldFill)
g.fillPath()

// === Countdown arc (white, 270 degrees = 75% remaining) ===
let arcCx = cx
let arcCy = cy - 20
let arcRadius: CGFloat = 120
let arcLineWidth: CGFloat = 22
let startAngle: CGFloat = .pi / 2  // 12 o'clock (in flipped coords, pi/2 is top)
let arcSweep: CGFloat = .pi * 2 * 0.75  // 270 degrees

// Background track (dim)
g.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
g.setLineWidth(arcLineWidth)
g.setLineCap(.round)
g.addArc(center: CGPoint(x: arcCx, y: arcCy), radius: arcRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
g.strokePath()

// Active arc (white)
g.setStrokeColor(white)
g.setLineWidth(arcLineWidth)
g.setLineCap(.round)
g.addArc(center: CGPoint(x: arcCx, y: arcCy), radius: arcRadius,
         startAngle: startAngle, endAngle: startAngle - arcSweep, clockwise: true)
g.strokePath()

// === Clock hand ===
let handLength: CGFloat = 85
let handAngle: CGFloat = startAngle - arcSweep  // points to where arc ends
let handEnd = CGPoint(
    x: arcCx + handLength * 0.4 * cos(handAngle),
    y: arcCy + handLength * 0.4 * sin(handAngle)
)
// Center dot
g.setFillColor(white)
g.fillEllipse(in: CGRect(x: arcCx - 10, y: arcCy - 10, width: 20, height: 20))

// Hand line
g.setStrokeColor(white)
g.setLineWidth(8)
g.setLineCap(.round)
g.move(to: CGPoint(x: arcCx, y: arcCy))
g.addLine(to: handEnd)
g.strokePath()

// === Small lock icon above arc ===
let lockCy = arcCy + arcRadius + 55
let lockCx = cx
let lockBodyW: CGFloat = 44
let lockBodyH: CGFloat = 36
let lockBodyRect = CGRect(x: lockCx - lockBodyW/2, y: lockCy - lockBodyH/2, width: lockBodyW, height: lockBodyH)

// Lock body
g.setFillColor(orange)
let lockBody = CGPath(roundedRect: lockBodyRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
g.addPath(lockBody)
g.fillPath()

// Lock shackle (arc above body)
let shackleRadius: CGFloat = 16
let shackleCy = lockCy + lockBodyH/2
g.setStrokeColor(orange)
g.setLineWidth(8)
g.setLineCap(.round)
g.addArc(center: CGPoint(x: lockCx, y: shackleCy), radius: shackleRadius,
         startAngle: 0, endAngle: .pi, clockwise: false)
g.strokePath()

// Keyhole
g.setFillColor(navy)
g.fillEllipse(in: CGRect(x: lockCx - 6, y: lockCy - 2, width: 12, height: 12))
g.fill(CGRect(x: lockCx - 3.5, y: lockCy - 12, width: 7, height: 12))

// === Time text at bottom ===
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 90, weight: .bold),
    .foregroundColor: NSColor(cgColor: orange)!
]
let timeStr = NSAttributedString(string: "45:00", attributes: attrs)
let strSize = timeStr.size()
let strOrigin = CGPoint(x: cx - strSize.width / 2, y: cy - shieldH / 2 + 40)
// Need to draw in flipped context for text
g.saveGState()
let textCtx = NSStringDrawingContext()
timeStr.draw(at: strOrigin)
g.restoreGState()

// Flush
NSGraphicsContext.current = nil

// Save PNG
let outputDir = "Resources"
try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
let outputPath = "\(outputDir)/AppIcon.png"
let pngData = rep.representation(using: .png, properties: [:])!
try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Generated \(outputPath) (\(rep.pixelsWide)x\(rep.pixelsHigh))")
