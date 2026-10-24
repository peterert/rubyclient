import SwiftUI

/// Uses the free Open-Meteo API (no key needed).
struct WeatherView: View {
    private struct Geocode: Decodable {
        struct Place: Decodable {
            let name: String
            let country: String?
            let latitude: Double
            let longitude: Double
        }
        let results: [Place]?
    }

    private struct Forecast: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let wind_speed_10m: Double
            let weather_code: Int
        }
        let current: Current
    }

    @AppStorage("weather.city") private var city = ""
    @State private var place = ""
    @State private var summary: String?
    @State private var temp: Double?
    @State private var wind: Double?
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        Form {
            Section {
                TextField("City", text: $city)
                    .submitLabel(.search)
                    .onSubmit { Task { await load() } }
                Button("Get weather") { Task { await load() } }
                    .disabled(city.trimmingCharacters(in: .whitespaces).isEmpty || loading)
            }
            .listRowBackground(Theme.glass)
            Section {
                if loading {
                    ProgressView()
                } else if let error {
                    Text(error).foregroundColor(Theme.dim)
                } else if let temp, let wind, let summary {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(place).font(.headline)
                        Text("\(Int(temp.rounded()))°C")
                            .font(.system(size: 56, weight: .thin))
                            .foregroundColor(Theme.gold)
                        Text(summary)
                        Text("Wind \(Int(wind.rounded())) km/h").font(.caption).foregroundColor(Theme.dim)
                    }
                } else {
                    Text("Enter a city to see the weather.").foregroundColor(Theme.dim)
                }
            }
            .listRowBackground(Theme.glass)
        }
        .rubyScreen()
        .task { if !city.isEmpty { await load() } }
    }

    private func load() async {
        let name = city.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        loading = true
        error = nil
        defer { loading = false }
        do {
            var g = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
            g.queryItems = [URLQueryItem(name: "name", value: name), URLQueryItem(name: "count", value: "1")]
            let (gData, _) = try await URLSession.shared.data(from: g.url!)
            guard let found = try JSONDecoder().decode(Geocode.self, from: gData).results?.first else {
                error = "City not found."
                return
            }
            var f = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            f.queryItems = [
                URLQueryItem(name: "latitude", value: String(found.latitude)),
                URLQueryItem(name: "longitude", value: String(found.longitude)),
                URLQueryItem(name: "current", value: "temperature_2m,wind_speed_10m,weather_code"),
            ]
            let (fData, _) = try await URLSession.shared.data(from: f.url!)
            let current = try JSONDecoder().decode(Forecast.self, from: fData).current
            place = [found.name, found.country].compactMap { $0 }.joined(separator: ", ")
            temp = current.temperature_2m
            wind = current.wind_speed_10m
            summary = Self.describe(current.weather_code)
        } catch {
            self.error = "Could not load the weather. Check your connection."
        }
    }

    private static func describe(_ code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1, 2: return "Mostly clear"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51...57: return "Drizzle"
        case 61...67: return "Rain"
        case 71...77: return "Snow"
        case 80...82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95...99: return "Thunderstorm"
        default: return "Unknown"
        }
    }
}
