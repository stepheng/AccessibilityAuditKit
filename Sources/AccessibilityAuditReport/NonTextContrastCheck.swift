//
//  NonTextContrastCheck.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import CoreGraphics
import Foundation

extension SupplementalAccessibilityChecks {
    /// WCAG 1.4.11's minimum contrast for graphical objects.
    public static let nonTextContrastThreshold: Double = 3.0
    /// Minimum Otsu separability (between-class ÷ total luminance variance) for a
    /// cropped region to count as a two-toned graphical object rather than a
    /// photo, gradient, or flat fill. η ≈ 1 for a clean icon, ≈ 0.75 for a
    /// gradient; below this the region is skipped.
    public static let nonTextContrastMinSeparability: Double = 0.8
    /// Minimum share of cropped pixels the minority luminance class must hold, so
    /// a stray speck is not treated as the foreground.
    public static let nonTextContrastMinClassFraction: Double = 0.03

    /// Flags icon-style graphical objects whose dominant foreground and
    /// background differ by less than 3:1 contrast (WCAG 1.4.11 Non-text
    /// Contrast, Level AA). Frames are in points; `scale` maps them to pixels of
    /// `image` (screenshot pixel width ÷ point width). Each emitted issue keeps
    /// the original point frame so the report overlay still aligns.
    ///
    /// Advisory **warning**: the foreground/background split is inferred from
    /// pixels, so it estimates rather than proves a failure, and it evaluates
    /// only regions that are clearly two-toned (see
    /// `nonTextContrastMinSeparability`). Photos, gradients, flat fills, and tiny
    /// or thin glyphs are skipped rather than guessed at.
    public static func nonTextContrastIssues(
        graphicalElements: [AuditedElement],
        image: PixelImage,
        scale: CGFloat = 1,
        threshold: Double = nonTextContrastThreshold,
        minSeparability: Double = nonTextContrastMinSeparability,
        minClassFraction: Double = nonTextContrastMinClassFraction
    ) -> [Issue] {
        graphicalElements.compactMap { element in
            guard let ratio = dominantContrastRatio(
                frame: element.frame,
                image: image,
                scale: scale,
                minSeparability: minSeparability,
                minClassFraction: minClassFraction
            ), ratio < threshold else {
                return nil
            }

            let measured = String(format: "%.1f", ratio)
            return Issue(
                auditType: "Non-text Contrast",
                compactDescription: "Graphical object contrast is about \(measured):1, below the 3:1 minimum",
                detailedDescription: "The dominant foreground and background of this graphical object differ by only about \(measured):1, measured from the screenshot. WCAG 1.4.11 (Level AA) requires graphical objects needed to understand the interface to have at least 3:1 contrast against adjacent colours. This is estimated from pixels — confirm against the design, and check states the snapshot cannot (focus, selection).",
                elementIdentifier: element.identifier,
                elementLabel: element.label,
                elementFrame: element.frame,
                reviewerHints: issueReviewerHints(for: element, auditType: "Non-text Contrast"),
                severity: .warning
            )
        }
    }

    /// Contrast ratio between the dominant dark and light luminance classes
    /// inside the element's pixel region, or nil when the region is
    /// offscreen/degenerate or not a clear two-toned graphic.
    private static func dominantContrastRatio(
        frame: CGRect,
        image: PixelImage,
        scale: CGFloat,
        minSeparability: Double,
        minClassFraction: Double
    ) -> Double? {
        let minX = max(0, Int((frame.minX * scale).rounded(.down)))
        let minY = max(0, Int((frame.minY * scale).rounded(.down)))
        let maxX = min(image.width, Int((frame.maxX * scale).rounded(.up)))
        let maxY = min(image.height, Int((frame.maxY * scale).rounded(.up)))
        guard maxX - minX >= 1, maxY - minY >= 1 else { return nil }

        // Histogram of relative luminance bucketed to 0…255, plus the true
        // luminance sum per bucket so class means use real luminance, not the
        // quantised bucket index.
        var counts = [Int](repeating: 0, count: 256)
        var luminanceSums = [Double](repeating: 0, count: 256)
        var total = 0
        for y in minY..<maxY {
            for x in minX..<maxX {
                let luminance = image.relativeLuminance(x: x, y: y)
                let bucket = min(255, max(0, Int((luminance * 255).rounded())))
                counts[bucket] += 1
                luminanceSums[bucket] += luminance
                total += 1
            }
        }
        guard total > 0 else { return nil }

        guard let split = otsuSplit(counts: counts, total: total),
              split.separability >= minSeparability else {
            return nil
        }

        var darkCount = 0
        var lightCount = 0
        var darkLuminance = 0.0
        var lightLuminance = 0.0
        for bucket in 0...255 {
            if bucket <= split.threshold {
                darkCount += counts[bucket]
                darkLuminance += luminanceSums[bucket]
            } else {
                lightCount += counts[bucket]
                lightLuminance += luminanceSums[bucket]
            }
        }
        guard darkCount > 0, lightCount > 0 else { return nil }

        let minorityFraction = Double(min(darkCount, lightCount)) / Double(total)
        guard minorityFraction >= minClassFraction else { return nil }

        let darkMean = darkLuminance / Double(darkCount)
        let lightMean = lightLuminance / Double(lightCount)
        return PixelImage.contrastRatio(darkMean, lightMean)
    }

    /// The Otsu threshold (bucket index) maximising between-class variance, with
    /// separability η = σ²_between ÷ σ²_total (0…1). Returns nil for a flat
    /// region (zero total variance).
    private static func otsuSplit(
        counts: [Int], total: Int
    ) -> (threshold: Int, separability: Double)? {
        let totalD = Double(total)
        var sumAll = 0.0
        var sumSquares = 0.0
        for bucket in 0...255 {
            let count = Double(counts[bucket])
            sumAll += Double(bucket) * count
            sumSquares += Double(bucket) * Double(bucket) * count
        }
        let meanAll = sumAll / totalD
        let totalVariance = sumSquares / totalD - meanAll * meanAll
        guard totalVariance > 0.000001 else { return nil }

        var weightBelow = 0.0
        var sumBelow = 0.0
        var bestVariance = -1.0
        var bestThreshold: Int? = nil
        for bucket in 0...255 {
            weightBelow += Double(counts[bucket])
            if weightBelow == 0 { continue }
            let weightAbove = totalD - weightBelow
            if weightAbove == 0 { break }
            sumBelow += Double(bucket) * Double(counts[bucket])
            let meanBelow = sumBelow / weightBelow
            let meanAbove = (sumAll - sumBelow) / weightAbove
            let betweenVariance = (weightBelow / totalD) * (weightAbove / totalD)
                * (meanBelow - meanAbove) * (meanBelow - meanAbove)
            if betweenVariance > bestVariance {
                bestVariance = betweenVariance
                bestThreshold = bucket
            }
        }
        guard let threshold = bestThreshold, bestVariance >= 0 else { return nil }
        return (threshold, bestVariance / totalVariance)
    }
}
