import SwiftUI

struct CalculatorView: View {
    @State private var display = "0"
    @State private var acc: Double?
    @State private var op: String?
    @State private var fresh = true

    private let rows: [[String]] = [
        ["C", "±", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
    ]

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(display)
                .font(.system(size: 64, weight: .light))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                ForEach(rows, id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { key in keyButton(key) }
                    }
                }
                GridRow {
                    keyButton("0").gridCellColumns(2)
                    keyButton(".")
                    keyButton("=")
                }
            }
            .padding(16)
        }
        .rubyScreen()
    }

    private func keyButton(_ key: String) -> some View {
        let isOp = "÷×−+=".contains(key)
        return Button { press(key) } label: {
            Text(key)
                .font(.title.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(
                    isOp
                        ? AnyView(LinearGradient(colors: [Theme.bright, Theme.ruby], startPoint: .top, endPoint: .bottom))
                        : AnyView(Theme.glass)
                )
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line))
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func press(_ key: String) {
        switch key {
        case "C":
            display = "0"; acc = nil; op = nil; fresh = true
        case "±":
            display = format(-(Double(display) ?? 0))
        case "%":
            display = format((Double(display) ?? 0) / 100)
        case "÷", "×", "−", "+":
            if !(fresh && op != nil) { commit() }
            if display != "Error" { op = key }
            fresh = true
        case "=":
            commit(); op = nil; fresh = true
        default:
            if fresh || display == "Error" {
                display = key == "." ? "0." : key
                fresh = false
            } else if key == "." {
                if !display.contains(".") { display += "." }
            } else {
                display = display == "0" ? key : display + key
            }
        }
    }

    private func commit() {
        let v = Double(display) ?? 0
        guard let a = acc, let o = op else { acc = v; return }
        let r: Double
        switch o {
        case "+": r = a + v
        case "−": r = a - v
        case "×": r = a * v
        default: r = a / v
        }
        if r.isFinite {
            acc = r
            display = format(r)
        } else {
            display = "Error"; acc = nil; op = nil
        }
    }

    private func format(_ v: Double) -> String {
        if v == v.rounded(), abs(v) < 1e15 { return String(Int(v)) }
        return String(format: "%.10g", v)
    }
}
