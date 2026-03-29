import SwiftUI
import WidgetKit

// MARK: - Root

struct ValidatorWidgetView: View {
    let entry: ValidatorEntry
    @Environment(\.widgetFamily) var family

    private var beaconURL: URL? {
        URL(string: "https://beaconcha.in/validator/\(entry.validatorIndex)#charts")
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:  SmallValidatorView(entry: entry)
            default:            MediumValidatorView(entry: entry)
            }
        }
        .widgetURL(beaconURL)
        .containerBackground(for: .widget) {
            Color.black
        }
    }
}

// MARK: - Small
//
//  [Ξ diamond]         123456
//
//  ● …deadbeef
//
//  Validating
//
//  3:08 PM

private struct SmallValidatorView: View {
    let entry: ValidatorEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Row 1 — ETH diamond left, validator index right
            HStack(alignment: .top) {
                EthDiamond(size: 32)
                Spacer()
                Text(String(entry.validatorIndex))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            // Row 2 — pubkey pill  ("→ Chicago" row)
            if entry.isError {
                PubKeyPill(text: "Error", color: .orange)
            } else if let pk = entry.pubKeyShort {
                PubKeyPill(text: pk, color: statusColor)
            }

            Spacer(minLength: 6)

            // Row 3 — large status word  ("118 Days" row)
            Text(statusWord)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer(minLength: 6)

            // Row 4 — time only
            Text(entry.date, format: .dateTime.hour().minute())
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(12)
    }

    private var statusColor: Color {
        entry.isSlashed ? .orange : (entry.isHealthy ? .green : .red)
    }

    private var statusWord: String {
        entry.isError ? (entry.errorMessage ?? "Error") : friendlyStatus(entry.statusLabel)
    }
}

// MARK: - Medium

private struct MediumValidatorView: View {
    let entry: ValidatorEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            // ── Left column (mirrors small)
            VStack(alignment: .leading, spacing: 0) {
                EthDiamond(size: 32)

                Spacer()

                if entry.isError {
                    PubKeyPill(text: "Error", color: .orange)
                } else if let pk = entry.pubKeyShort {
                    PubKeyPill(text: pk, color: statusColor)
                }

                Spacer(minLength: 6)

                Text(statusWord)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text(entry.date, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // ── Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, 4)

            // ── Right column — index + stats
            VStack(alignment: .leading, spacing: 0) {
                Text(String(entry.validatorIndex))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                if !entry.isError {
                    if let bal = entry.balanceETH {
                        StatCell(label: "Current", value: String(format: "%.4f ETH", bal))
                    }
                    if let eff = entry.effectiveBalanceETH {
                        StatCell(label: "Effective", value: String(format: "%.4f ETH", eff))
                            .padding(.top, 8)
                    }
                    if entry.isSlashed {
                        StatCell(label: "Slashed", value: "Yes", valueColor: .orange)
                            .padding(.top, 8)
                    }
                } else {
                    Text(entry.errorMessage ?? "Error")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(4)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
    }

    private var statusColor: Color {
        entry.isSlashed ? .orange : (entry.isHealthy ? .green : .red)
    }

    private var statusWord: String {
        entry.isError ? "Error" : friendlyStatus(entry.statusLabel)
    }
}

// MARK: - ETH diamond logo

/// Draws the Ethereum diamond logo as a proper geometric shape using Canvas —
/// four triangular faces with depth shading, no background box.
private struct EthDiamond: View {
    let size: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width
            let h = sz.height
            let cx = w / 2

            // Key y-coordinates (proportional to the real ETH logo)
            let top    = CGPoint(x: cx,  y: 0)
            let left1  = CGPoint(x: 0,   y: h * 0.40)
            let right1 = CGPoint(x: w,   y: h * 0.40)
            let mid    = CGPoint(x: cx,  y: h * 0.525)
            let left2  = CGPoint(x: 0,   y: h * 0.625)
            let right2 = CGPoint(x: w,   y: h * 0.625)
            let bottom = CGPoint(x: cx,  y: h)

            func face(_ pts: [CGPoint]) -> Path {
                var p = Path()
                p.move(to: pts[0])
                pts.dropFirst().forEach { p.addLine(to: $0) }
                p.closeSubpath()
                return p
            }

            // Upper-left (dim)
            ctx.fill(face([top, mid, left1]),  with: .color(.white.opacity(0.55)))
            // Upper-right (bright)
            ctx.fill(face([top, right1, mid]), with: .color(.white.opacity(0.9)))
            // Lower-left (dim)
            ctx.fill(face([mid, left2, bottom]),  with: .color(.white.opacity(0.55)))
            // Lower-right (bright)
            ctx.fill(face([mid, bottom, right2]), with: .color(.white.opacity(0.9)))
        }
        .frame(width: size * 0.6, height: size)  // ETH logo is taller than wide
    }
}

// MARK: - Shared sub-views

private struct PubKeyPill: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.caption.weight(.medium).monospaced())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: Capsule())
    }
}

private struct StatCell: View {
    let label: String
    let value: String
    var valueColor: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Helpers

private func friendlyStatus(_ label: String) -> String {
    switch label {
    case "active_online":                    return "Validating"
    case "active_offline":                   return "Offline"
    case "active_exiting":                   return "Exiting"
    case "active_slashed":                   return "Slashed"
    case _ where label.hasPrefix("pending"): return "Pending"
    case _ where label.hasPrefix("exited"):  return "Exited"
    case "no_api_key":                       return "No API Key"
    case "error":                            return "Error"
    default:
        return label.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    ValidatorWidget()
} timeline: {
    ValidatorEntry.placeholder
    ValidatorEntry(
        date: .now,
        validatorIndex: 123456,
        isHealthy: false,
        isSlashed: false,
        statusLabel: "active_offline",
        balanceETH: 32.0419,
        effectiveBalanceETH: 32.0,
        pubKeyShort: "…deadbeef",
        isError: false,
        errorMessage: nil
    )
}

#Preview(as: .systemMedium) {
    ValidatorWidget()
} timeline: {
    ValidatorEntry.placeholder
}
