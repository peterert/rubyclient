import SwiftUI

struct ConverterView: View {
    private struct Category: Identifiable {
        let name: String
        let units: [(String, Dimension)]
        var id: String { name }
    }

    private let categories: [Category] = [
        Category(name: "Length", units: [
            ("Meters", UnitLength.meters), ("Kilometers", UnitLength.kilometers),
            ("Miles", UnitLength.miles), ("Feet", UnitLength.feet), ("Inches", UnitLength.inches),
        ]),
        Category(name: "Mass", units: [
            ("Kilograms", UnitMass.kilograms), ("Grams", UnitMass.grams),
            ("Pounds", UnitMass.pounds), ("Ounces", UnitMass.ounces),
        ]),
        Category(name: "Temperature", units: [
            ("Celsius", UnitTemperature.celsius), ("Fahrenheit", UnitTemperature.fahrenheit),
            ("Kelvin", UnitTemperature.kelvin),
        ]),
    ]

    @State private var categoryIndex = 0
    @State private var fromIndex = 0
    @State private var toIndex = 1
    @State private var input = "1"

    private var units: [(String, Dimension)] { categories[categoryIndex].units }

    private var result: String {
        guard let v = Double(input.replacingOccurrences(of: ",", with: ".")) else { return "–" }
        let from = units[min(fromIndex, units.count - 1)].1
        let to = units[min(toIndex, units.count - 1)].1
        let out = Measurement(value: v, unit: from).converted(to: to).value
        return String(format: "%.6g", out)
    }

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $categoryIndex) {
                    ForEach(categories.indices, id: \.self) { Text(categories[$0].name).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: categoryIndex) { _ in fromIndex = 0; toIndex = 1 }
            }
            .listRowBackground(Theme.glass)
            Section("From") {
                TextField("Value", text: $input).keyboardType(.decimalPad)
                Picker("Unit", selection: $fromIndex) {
                    ForEach(units.indices, id: \.self) { Text(units[$0].0).tag($0) }
                }
            }
            .listRowBackground(Theme.glass)
            Section("To") {
                Picker("Unit", selection: $toIndex) {
                    ForEach(units.indices, id: \.self) { Text(units[$0].0).tag($0) }
                }
                Text(result).font(.title2.weight(.semibold)).foregroundColor(Theme.gold)
            }
            .listRowBackground(Theme.glass)
        }
        .rubyScreen()
    }
}
