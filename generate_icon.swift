#!/usr/bin/swift
import Foundation
import CoreGraphics
import ImageIO

let size = 1024
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: cs,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// Flip coordinate system so y=0 is at top (matches PNG/UIKit convention)
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

let S = CGFloat(size)

// ── Background: soft gradient-like warm pink ──────────────────────────────────
ctx.setFillColor(color(1.0, 0.82, 0.87))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Slightly darker corner vignette
let vignette = CGGradient(
    colorsSpace: cs,
    colors: [color(0.93, 0.65, 0.76, 0), color(0.93, 0.65, 0.76, 0.55)] as CFArray,
    locations: [0.55, 1.0]
)!
ctx.drawRadialGradient(
    vignette,
    startCenter: CGPoint(x: S * 0.5, y: S * 0.52),
    startRadius: S * 0.38,
    endCenter: CGPoint(x: S * 0.5, y: S * 0.52),
    endRadius: S * 0.78,
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)

// ── Helper: filled circle ─────────────────────────────────────────────────────
func fillCircle(cx: CGFloat, cy: CGFloat, r: CGFloat, fill: CGColor) {
    ctx.setFillColor(fill)
    ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
}

func strokeCircle(cx: CGFloat, cy: CGFloat, r: CGFloat, stroke: CGColor, width: CGFloat) {
    ctx.setStrokeColor(stroke)
    ctx.setLineWidth(width)
    ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
}

// ── Swaddle / body ────────────────────────────────────────────────────────────
let bodyCx = S * 0.5, bodyCy = S * 0.72
let bodyW = S * 0.56, bodyH = S * 0.34

// Swaddle shadow
ctx.setFillColor(color(0.85, 0.73, 0.90, 0.55))
let shadowBodyRect = CGRect(x: bodyCx - bodyW * 0.52 + S * 0.012,
                             y: bodyCy - bodyH * 0.52 - S * 0.012,
                             width: bodyW * 1.04, height: bodyH * 1.04)
ctx.addEllipse(in: shadowBodyRect)
ctx.fillPath()

// Main swaddle – lavender
ctx.setFillColor(color(0.88, 0.78, 0.96))
let bodyRect = CGRect(x: bodyCx - bodyW * 0.5, y: bodyCy - bodyH * 0.5,
                      width: bodyW, height: bodyH)
let br: CGFloat = bodyH * 0.5
let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: br, cornerHeight: br, transform: nil)
ctx.addPath(bodyPath)
ctx.fillPath()

// Swaddle fold highlight
ctx.setFillColor(color(1.0, 0.96, 1.0, 0.55))
ctx.move(to: CGPoint(x: bodyCx - bodyW * 0.18, y: bodyCy - bodyH * 0.38))
ctx.addQuadCurve(
    to: CGPoint(x: bodyCx + bodyW * 0.18, y: bodyCy - bodyH * 0.38),
    control: CGPoint(x: bodyCx, y: bodyCy - bodyH * 0.7)
)
ctx.addQuadCurve(
    to: CGPoint(x: bodyCx - bodyW * 0.18, y: bodyCy - bodyH * 0.38),
    control: CGPoint(x: bodyCx, y: bodyCy - bodyH * 0.05)
)
ctx.fillPath()

// Swaddle outline
ctx.setStrokeColor(color(0.70, 0.58, 0.82))
ctx.setLineWidth(S * 0.012)
ctx.addPath(bodyPath)
ctx.strokePath()

// ── Head ──────────────────────────────────────────────────────────────────────
let headCx = S * 0.5, headCy = S * 0.44
let headR = S * 0.265

// Head shadow
fillCircle(cx: headCx + S * 0.012, cy: headCy - S * 0.012,
           r: headR * 1.03, fill: color(0.78, 0.60, 0.68, 0.35))

// Head base skin
fillCircle(cx: headCx, cy: headCy, r: headR, fill: color(1.0, 0.88, 0.78))

// Rosy left cheek
fillCircle(cx: headCx - headR * 0.52, cy: headCy + headR * 0.18,
           r: headR * 0.3, fill: color(1.0, 0.72, 0.78, 0.45))

// Rosy right cheek
fillCircle(cx: headCx + headR * 0.52, cy: headCy + headR * 0.18,
           r: headR * 0.3, fill: color(1.0, 0.72, 0.78, 0.45))

// Head outline
strokeCircle(cx: headCx, cy: headCy, r: headR, stroke: color(0.87, 0.68, 0.58), width: S * 0.014)

// ── Hair tufts ────────────────────────────────────────────────────────────────
let hairColor = color(0.58, 0.35, 0.18)
ctx.setStrokeColor(hairColor)
ctx.setLineWidth(S * 0.022)
ctx.setLineCap(.round)

// Centre tuft
ctx.move(to: CGPoint(x: headCx, y: headCy - headR * 0.95))
ctx.addQuadCurve(
    to: CGPoint(x: headCx, y: headCy - headR * 1.28),
    control: CGPoint(x: headCx - S * 0.025, y: headCy - headR * 1.12)
)
ctx.strokePath()

// Left tuft
ctx.move(to: CGPoint(x: headCx - headR * 0.3, y: headCy - headR * 0.92))
ctx.addQuadCurve(
    to: CGPoint(x: headCx - headR * 0.42, y: headCy - headR * 1.22),
    control: CGPoint(x: headCx - headR * 0.52, y: headCy - headR * 1.08)
)
ctx.strokePath()

// Right tuft
ctx.move(to: CGPoint(x: headCx + headR * 0.3, y: headCy - headR * 0.92))
ctx.addQuadCurve(
    to: CGPoint(x: headCx + headR * 0.42, y: headCy - headR * 1.22),
    control: CGPoint(x: headCx + headR * 0.52, y: headCy - headR * 1.08)
)
ctx.strokePath()

// ── Eyes ──────────────────────────────────────────────────────────────────────
let eyeOffsetX = headR * 0.38
let eyeCy = headCy - headR * 0.08
let eyeR = headR * 0.115

// White sclera
fillCircle(cx: headCx - eyeOffsetX, cy: eyeCy, r: eyeR, fill: color(1, 1, 1))
fillCircle(cx: headCx + eyeOffsetX, cy: eyeCy, r: eyeR, fill: color(1, 1, 1))

// Iris – warm brown
fillCircle(cx: headCx - eyeOffsetX, cy: eyeCy,
           r: eyeR * 0.72, fill: color(0.42, 0.24, 0.10))
fillCircle(cx: headCx + eyeOffsetX, cy: eyeCy,
           r: eyeR * 0.72, fill: color(0.42, 0.24, 0.10))

// Pupil – black
fillCircle(cx: headCx - eyeOffsetX, cy: eyeCy,
           r: eyeR * 0.38, fill: color(0.07, 0.05, 0.05))
fillCircle(cx: headCx + eyeOffsetX, cy: eyeCy,
           r: eyeR * 0.38, fill: color(0.07, 0.05, 0.05))

// Eye sparkle
fillCircle(cx: headCx - eyeOffsetX + eyeR * 0.22, cy: eyeCy + eyeR * 0.22,
           r: eyeR * 0.18, fill: color(1, 1, 1))
fillCircle(cx: headCx + eyeOffsetX + eyeR * 0.22, cy: eyeCy + eyeR * 0.22,
           r: eyeR * 0.18, fill: color(1, 1, 1))

// Eye outline
strokeCircle(cx: headCx - eyeOffsetX, cy: eyeCy, r: eyeR,
             stroke: color(0.25, 0.14, 0.07), width: S * 0.008)
strokeCircle(cx: headCx + eyeOffsetX, cy: eyeCy, r: eyeR,
             stroke: color(0.25, 0.14, 0.07), width: S * 0.008)

// ── Eyebrows (cute arched) ────────────────────────────────────────────────────
ctx.setStrokeColor(color(0.48, 0.28, 0.12))
ctx.setLineWidth(S * 0.018)
ctx.setLineCap(.round)

for side: CGFloat in [-1, 1] {
    let ex = headCx + side * eyeOffsetX
    ctx.move(to: CGPoint(x: ex - eyeR * 0.72, y: eyeCy - eyeR * 1.55))
    ctx.addQuadCurve(
        to: CGPoint(x: ex + eyeR * 0.72, y: eyeCy - eyeR * 1.55),
        control: CGPoint(x: ex, y: eyeCy - eyeR * 2.1)
    )
    ctx.strokePath()
}

// ── Nose ──────────────────────────────────────────────────────────────────────
let noseCx = headCx, noseCy = headCy + headR * 0.16
ctx.setFillColor(color(0.92, 0.72, 0.65, 0.7))
ctx.fillEllipse(in: CGRect(x: noseCx - headR * 0.07, y: noseCy - headR * 0.045,
                            width: headR * 0.14, height: headR * 0.09))

// Nostril dots
fillCircle(cx: noseCx - headR * 0.05, cy: noseCy, r: headR * 0.028,
           fill: color(0.72, 0.48, 0.42, 0.65))
fillCircle(cx: noseCx + headR * 0.05, cy: noseCy, r: headR * 0.028,
           fill: color(0.72, 0.48, 0.42, 0.65))

// ── Smile ─────────────────────────────────────────────────────────────────────
ctx.setStrokeColor(color(0.75, 0.42, 0.38))
ctx.setLineWidth(S * 0.018)
ctx.setLineCap(.round)
let mouthCy = headCy + headR * 0.38
ctx.move(to: CGPoint(x: headCx - headR * 0.25, y: mouthCy))
ctx.addQuadCurve(
    to: CGPoint(x: headCx + headR * 0.25, y: mouthCy),
    control: CGPoint(x: headCx, y: mouthCy + headR * 0.22)
)
ctx.strokePath()

// ── Little heart decoration on swaddle ───────────────────────────────────────
let hCx = S * 0.5, hCy = S * 0.76, hS: CGFloat = S * 0.045
ctx.setFillColor(color(0.96, 0.42, 0.58, 0.85))
ctx.move(to: CGPoint(x: hCx, y: hCy + hS * 0.5))
ctx.addCurve(
    to: CGPoint(x: hCx - hS, y: hCy - hS * 0.3),
    control1: CGPoint(x: hCx - hS * 0.1, y: hCy + hS * 0.5),
    control2: CGPoint(x: hCx - hS, y: hCy + hS * 0.2)
)
ctx.addArc(center: CGPoint(x: hCx - hS * 0.5, y: hCy - hS * 0.3),
           radius: hS * 0.5, startAngle: .pi, endAngle: 0, clockwise: false)
ctx.addArc(center: CGPoint(x: hCx + hS * 0.5, y: hCy - hS * 0.3),
           radius: hS * 0.5, startAngle: .pi, endAngle: 0, clockwise: false)
ctx.addCurve(
    to: CGPoint(x: hCx, y: hCy + hS * 0.5),
    control1: CGPoint(x: hCx + hS, y: hCy + hS * 0.2),
    control2: CGPoint(x: hCx + hS * 0.1, y: hCy + hS * 0.5)
)
ctx.fillPath()

// ── Save PNGs ─────────────────────────────────────────────────────────────────
guard let cgImage = ctx.makeImage() else {
    print("ERROR: could not create CGImage")
    exit(1)
}

let iconFolder = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "./BreastFeeding/Assets.xcassets/AppIcon.appiconset")

func savePNG(_ image: CGImage, to folder: URL, name: String, side: Int) {
    let scaled: CGImage
    if side != size {
        let sCtx = CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8,
            bytesPerRow: side * 4, space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        sCtx.interpolationQuality = .high
        sCtx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        scaled = sCtx.makeImage()!
    } else {
        scaled = image
    }
    let url = folder.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, scaled, nil)
    CGImageDestinationFinalize(dest)
    print("Saved \(url.lastPathComponent)")
}

savePNG(cgImage, to: iconFolder, name: "AppIcon-1024.png", side: 1024)
savePNG(cgImage, to: iconFolder, name: "AppIcon-Dark-1024.png", side: 1024)
savePNG(cgImage, to: iconFolder, name: "AppIcon-Tinted-1024.png", side: 1024)

print("Done!")
