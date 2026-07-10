//
//  PredictionsBVApp.swift
//  PredictionsBV
//
//  Created by Luis Vega on 12/05/25.
//

import SwiftUI

@main
struct StockPredictorApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = StockPredictionViewModel()
    @State private var selectedTab = 0
    @State private var showSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Vista de Predicciones a Corto Plazo
            ShortTermPredictionsView(predictions: viewModel.shortTermPredictions)
                .tabItem {
                    Label("Corto Plazo", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)
            
            // Vista de Predicciones a Largo Plazo
            LongTermPredictionsView(predictions: viewModel.longTermPredictions)
                .tabItem {
                    Label("Largo Plazo", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            // Vista de Análisis
            AnalyticsView(viewModel: viewModel)
                .tabItem {
                    Label("Análisis", systemImage: "magnifyingglass.circle")
                }
                .tag(2)
            
            // Vista de Favoritos
            WatchlistView(viewModel: viewModel)
                .tabItem {
                    Label("Favoritos", systemImage: "star.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            viewModel.loadPredictions()
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
        )
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gear")
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.refreshPredictions()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

import SwiftUI

struct ShortTermPredictionsView: View {
    let predictions: [StockPrediction]
    @State private var sortOrder: SortOrder = .potential
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Barra de búsqueda
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                if predictions.isEmpty {
                    EmptyPredictionsView(isShortTerm: true)
                } else {
                    // Lista de predicciones
                    List {
                        ForEach(filteredPredictions, id: \.id) { prediction in
                            NavigationLink(destination: StockDetailView(prediction: prediction)) {
                                PredictionRow(prediction: prediction)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Corto Plazo (4-6 semanas)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SortButton(sortOrder: $sortOrder)
                }
            }
        }
    }
    
    private var filteredPredictions: [StockPrediction] {
        let filtered = searchText.isEmpty ?
            predictions :
            predictions.filter {
                $0.stock.symbol.lowercased().contains(searchText.lowercased()) ||
                $0.stock.name.lowercased().contains(searchText.lowercased())
            }
        
        return sortPredictions(filtered)
    }
    
    private func sortPredictions(_ predictions: [StockPrediction]) -> [StockPrediction] {
        switch sortOrder {
            case .potential:
                return predictions.sorted { $0.growthPotential > $1.growthPotential }
            case .confidence:
                return predictions.sorted { $0.confidenceLevel > $1.confidenceLevel }
            case .price:
                return predictions.sorted { $0.currentPrice < $1.currentPrice }
            case .alphabetical:
                return predictions.sorted { $0.stock.symbol < $1.stock.symbol }
        }
    }
}

import SwiftUI

//struct LongTermPredictionsView: View {
//    let predictions: [StockPrediction]
//    @State private var sortOrder: SortOrder = .potential
//    @State private var searchText = ""
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                // Barra de búsqueda
//                SearchBar(text: $searchText)
//                    .padding(.horizontal)
//                
//                if predictions.isEmpty {
//                    EmptyPredictionsView(isShortTerm: false)
//                } else {
//                    // Lista de predicciones
//                    List {
//                        ForEach(filteredPredictions, id: \.id) { prediction in
//                            NavigationLink(destination: StockDetailView(prediction: prediction)) {
//                                PredictionRow(prediction: prediction)
//                            }
//                        }
//                    }
//                    .listStyle(PlainListStyle())
//                }
//            }
//            .navigationTitle("Largo Plazo (3-4 meses)")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    SortButton(sortOrder: $sortOrder)
//                }
//            }
//        }
//    }
//    
//    private var filteredPredictions: [StockPrediction] {
//        let filtered = searchText.isEmpty ?
//            predictions :
//            predictions.filter {
//                $0.stock.symbol.lowercased().contains(searchText.lowercased()) ||
//                $0.stock.name.lowercased().contains(searchText.lowercased())
//            }
//        
//        return sortPredictions(filtered)
//    }
//    
//    private func sortPredictions(_ predictions: [StockPrediction]) -> [StockPrediction] {
//        switch sortOrder {
//            case .potential:
//                return predictions.sorted { $0.growthPotential > $1.growthPotential }
//            case .confidence:
//                return predictions.sorted { $0.confidenceLevel > $1.confidenceLevel }
//            case .price:
//                return predictions.sorted { $0.currentPrice < $1.currentPrice }
//            case .alphabetical:
//                return predictions.sorted { $0.stock.symbol < $1.stock.symbol }
//        }
//    }
//}

import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var viewModel: StockPredictionViewModel
    @State private var selectedSector: String? = nil
    @State private var showAllSectors = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Resumen de predicciones
                    SummaryCardView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // Distribución por sector
                    SectorDistributionView(viewModel: viewModel, selectedSector: $selectedSector, showAllSectors: $showAllSectors)
                        .padding(.horizontal)
                    
                    // Mejores predicciones
                    TopPredictionsView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // Distribución de confianza
                    ConfidenceDistributionView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // Estado del mercado
                    MarketStatusView()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Análisis de Mercado")
        }
    }
}

import SwiftUI

struct PredictionRow: View {
    let prediction: StockPrediction
    
    var body: some View {
        HStack {
            // Columna izquierda: Símbolo y Nombre
            VStack(alignment: .leading, spacing: 4) {
                Text(prediction.stock.symbol)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(prediction.stock.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Columna central: Precio actual y objetivo
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(prediction.currentPrice, specifier: "%.2f")")
                    .font(.subheadline)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(prediction.predictedPrice, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(prediction.isPotentialPositive ? .green : .red)
                }
            }
            
            Spacer()
            
            // Columna derecha: Potencial de crecimiento y confianza
            VStack(alignment: .trailing, spacing: 4) {
                Text(prediction.formattedPotential)
                    .font(.headline)
                    .foregroundColor(prediction.isPotentialPositive ? .green : .red)
                
                // Barra de confianza
                ConfidenceMeter(level: prediction.confidenceLevel)
                    .frame(width: 60, height: 6)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ConfidenceMeter: View {
    let level: Double // 0.0 a 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Fondo de la barra
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .foregroundColor(Color(.systemGray5))
                    .cornerRadius(geometry.size.height / 2)
                
                // Barra de progreso
                Rectangle()
                    .frame(width: CGFloat(level) * geometry.size.width, height: geometry.size.height)
                    .foregroundColor(meterColor)
                    .cornerRadius(geometry.size.height / 2)
            }
        }
    }
    
    private var meterColor: Color {
        if level >= 0.8 {
            return .green
        } else if level >= 0.6 {
            return .yellow
        } else if level >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

import SwiftUI

struct WatchlistView: View {
    @ObservedObject var viewModel: StockPredictionViewModel
    @AppStorage("watchlist") private var watchlistData: Data = Data()
    @State private var watchlist: [String] = []
    
    var body: some View {
        NavigationView {
            Group {
                if watchlist.isEmpty {
                    EmptyWatchlistView()
                } else {
                    List {
                        ForEach(filteredPredictions, id: \.id) { prediction in
                            NavigationLink(destination: StockDetailView(prediction: prediction)) {
                                PredictionRow(prediction: prediction)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    removeFromWatchlist(symbol: prediction.stock.symbol)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Favoritos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Acción para agregar a favoritos
                    }) {
                        Image(systemName: "plus")
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            loadWatchlist()
        }
    }
    
    private var filteredPredictions: [StockPrediction] {
        let allPredictions = viewModel.shortTermPredictions + viewModel.longTermPredictions
        return allPredictions.filter { watchlist.contains($0.stock.symbol) }
    }
    
    private func loadWatchlist() {
        if let decoded = try? JSONDecoder().decode([String].self, from: watchlistData) {
            watchlist = decoded
        }
    }
    
    private func saveWatchlist() {
        if let encoded = try? JSONEncoder().encode(watchlist) {
            watchlistData = encoded
        }
    }
    
    private func removeFromWatchlist(symbol: String) {
        watchlist.removeAll { $0 == symbol }
        saveWatchlist()
    }
}

struct EmptyWatchlistView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No hay favoritos")
                .font(.headline)
            
            Text("Agrega acciones a tus favoritos para seguir su desempeño y predicciones más fácilmente.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: {
                // Acción para agregar favorito
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Agregar favorito")
                }
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

struct SummaryCardView: View {
    @ObservedObject var viewModel: StockPredictionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resumen de Predicciones")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack(spacing: 30) {
                VStack {
                    Text("\(viewModel.shortTermPredictions.count)")
                        .font(.title)
                        .bold()
                    Text("Corto Plazo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.longTermPredictions.count)")
                        .font(.title)
                        .bold()
                    Text("Largo Plazo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(countPositivePredictions())")
                        .font(.title)
                        .bold()
                        .foregroundColor(.green)
                    Text("Alcistas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(countNegativePredictions())")
                        .font(.title)
                        .bold()
                        .foregroundColor(.red)
                    Text("Bajistas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func countPositivePredictions() -> Int {
        let shortTerm = viewModel.shortTermPredictions.filter { $0.growthPotential > 0 }.count
        let longTerm = viewModel.longTermPredictions.filter { $0.growthPotential > 0 }.count
        return shortTerm + longTerm
    }
    
    private func countNegativePredictions() -> Int {
        let shortTerm = viewModel.shortTermPredictions.filter { $0.growthPotential <= 0 }.count
        let longTerm = viewModel.longTermPredictions.filter { $0.growthPotential <= 0 }.count
        return shortTerm + longTerm
    }
}

struct SectorDistributionView: View {
    @ObservedObject var viewModel: StockPredictionViewModel
    @Binding var selectedSector: String?
    @Binding var showAllSectors: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Distribución por Sector")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showAllSectors.toggle()
                }) {
                    Text(showAllSectors ? "Mostrar Top 5" : "Ver Todos")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 5)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(sectorData, id: \.sector) { item in
                        SectorMark(
                            angle: .value("Valor", item.count),
                            innerRadius: .ratio(0.618)
                        )
                        .foregroundStyle(by: .value("Sector", item.sector))
                        .annotation(position: .overlay) {
                            Text("\(item.percentage)%")
                                .font(.caption)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                    }
                }
                .frame(height: 200)
                .chartForegroundStyleScale([
                    "Tecnología": Color.blue,
                    "Finanzas": Color.green,
                    "Salud": Color.red,
                    "Consumo": Color.orange,
                    "Energía": Color.purple,
                    "Otros": Color.gray
                ])
            } else {
                // Fallback para iOS anterior a 16
                HStack {
                    ForEach(sectorData, id: \.sector) { item in
                        VStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(sectorColor(for: item.sector))
                                .frame(height: 100 * CGFloat(item.percentage) / 100)
                            
                            Text(item.sector)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Text("\(item.percentage)%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 150)
            }
            
            // Leyenda
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(sectorData, id: \.sector) { item in
                    HStack {
                        Circle()
                            .fill(sectorColor(for: item.sector))
                            .frame(width: 10, height: 10)
                        
                        Text(item.sector)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var sectorData: [(sector: String, count: Int, percentage: Int)] {
        let allPredictions = viewModel.shortTermPredictions + viewModel.longTermPredictions
        
        // Contar por sector
        var sectorCounts: [String: Int] = [:]
        for prediction in allPredictions {
            let sector = prediction.stock.sector
            sectorCounts[sector, default: 0] += 1
        }
        
        // Convertir a array y ordenar
        var sectorArray = sectorCounts.map { (sector: $0.key, count: $0.value, percentage: 0) }
        sectorArray.sort { $0.count > $1.count }
        
        // Calcular porcentajes
        let total = allPredictions.count
        sectorArray = sectorArray.map { (sector: $0.sector, count: $0.count, percentage: Int(Double($0.count) / Double(total) * 100)) }
        
        // Limitar a top 5 o mostrar todos
        if !showAllSectors && sectorArray.count > 5 {
            var result = Array(sectorArray.prefix(5))
            
            // Agrupar el resto como "Otros"
            let otherCount = sectorArray.dropFirst(5).reduce(0) { $0 + $1.count }
            let otherPercentage = Int(Double(otherCount) / Double(total) * 100)
            result.append((sector: "Otros", count: otherCount, percentage: otherPercentage))
            
            return result
        }
        
        return sectorArray
    }
    
    private func sectorColor(for sector: String) -> Color {
        switch sector {
        case "Tecnología": return .blue
        case "Finanzas": return .green
        case "Salud": return .red
        case "Consumo": return .orange
        case "Energía": return .purple
        default: return .gray
        }
    }
}

struct TopPredictionsView: View {
    @ObservedObject var viewModel: StockPredictionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mejores Oportunidades")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(topPredictions, id: \.id) { prediction in
                NavigationLink(destination: StockDetailView(prediction: prediction)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(prediction.stock.symbol)
                                .font(.subheadline)
                                .bold()
                            
                            Text(prediction.stock.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(prediction.growthPotential, specifier: "+%.1f")%")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            
                            Text(prediction.timeFrame == .shortTerm ? "Corto Plazo" : "Largo Plazo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
                .buttonStyle(PlainButtonStyle())
                
                if prediction.id != topPredictions.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var topPredictions: [StockPrediction] {
        let allPredictions = viewModel.shortTermPredictions + viewModel.longTermPredictions
        return allPredictions
            .filter { $0.growthPotential > 0 }
            .sorted { $0.growthPotential > $1.growthPotential }
            .prefix(5)
            .map { $0 }
    }
}

struct ConfidenceDistributionView: View {
    @ObservedObject var viewModel: StockPredictionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Distribución de Confianza")
                .font(.headline)
                .padding(.bottom, 5)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(confidenceRanges, id: \.range) { item in
                        BarMark(
                            x: .value("Rango", item.range),
                            y: .value("Cantidad", item.count)
                        )
                        .foregroundStyle(barColor(for: item.confidenceValue))
                    }
                }
                .frame(height: 150)
            } else {
                // Fallback para iOS anterior a 16
                HStack(alignment: .bottom, spacing: 15) {
                    ForEach(confidenceRanges, id: \.range) { item in
                        VStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: item.confidenceValue))
                                .frame(height: CGFloat(item.count) * 10)
                            
                            Text(item.range)
                                .font(.caption)
                                .rotationEffect(.degrees(-45))
                                .offset(y: 5)
                        }
                    }
                }
                .frame(height: 150)
                .padding(.bottom, 20)
            }
            
            Text("La confianza indica la precisión estimada de la predicción")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var confidenceRanges: [(range: String, count: Int, confidenceValue: Double)] {
        let allPredictions = viewModel.shortTermPredictions + viewModel.longTermPredictions
        
        let ranges: [(label: String, min: Double, max: Double)] = [
            ("50-60%", 0.5, 0.6),
            ("60-70%", 0.6, 0.7),
            ("70-80%", 0.7, 0.8),
            ("80-90%", 0.8, 0.9),
            ("90-100%", 0.9, 1.0)
        ]
        
        return ranges.map { range in
            let count = allPredictions.filter {
                $0.confidenceLevel >= range.min && $0.confidenceLevel < range.max
            }.count
            return (range: range.label, count: count, confidenceValue: range.min + (range.max - range.min) / 2)
        }
    }
    
    private func barColor(for confidence: Double) -> Color {
        if confidence >= 0.9 {
            return .green
        } else if confidence >= 0.8 {
            return .green.opacity(0.8)
        } else if confidence >= 0.7 {
            return .yellow
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct MarketStatusView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Estado del Mercado")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack(spacing: 25) {
                // S&P 500
                MarketIndexItem(
                    name: "S&P 500",
                    value: "5,342.56",
                    change: "+0.87%",
                    isUp: true
                )
                
                // NASDAQ
                MarketIndexItem(
                    name: "NASDAQ",
                    value: "17,698.31",
                    change: "+1.23%",
                    isUp: true
                )
                
                // Dow Jones
                MarketIndexItem(
                    name: "DOW",
                    value: "42,103.22",
                    change: "-0.12%",
                    isUp: false
                )
            }
            .padding(.vertical, 5)
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Tasa de Interés Fed")
                        .font(.subheadline)
                    Text("3.75%")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Inflación Anual")
                        .font(.subheadline)
                    Text("2.8%")
                        .font(.headline)
                }
            }
            .padding(.vertical, 5)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MarketIndexItem: View {
    let name: String
    let value: String
    let change: String
    let isUp: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .bold()
            
            Text(change)
                .font(.caption)
                .foregroundColor(isUp ? .green : .red)
        }
    }
}

import SwiftUI

struct LongTermPredictionsView: View {
    let predictions: [StockPrediction]
    @State private var sortOrder: SortOrder = .potential
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Barra de búsqueda
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                if predictions.isEmpty {
                    EmptyPredictionsView(isShortTerm: false)
                } else {
                    // Lista de predicciones
                    List {
                        ForEach(filteredPredictions, id: \.id) { prediction in
                            NavigationLink(destination: StockDetailView(prediction: prediction)) {
                                PredictionRow(prediction: prediction)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Largo Plazo (3-4 meses)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SortButton(sortOrder: $sortOrder)
                }
            }
        }
    }
    
    private var filteredPredictions: [StockPrediction] {
        let filtered = searchText.isEmpty ?
            predictions :
            predictions.filter {
                $0.stock.symbol.lowercased().contains(searchText.lowercased()) ||
                $0.stock.name.lowercased().contains(searchText.lowercased())
            }
        
        return sortPredictions(filtered)
    }
    
    private func sortPredictions(_ predictions: [StockPrediction]) -> [StockPrediction] {
        switch sortOrder {
            case .potential:
                return predictions.sorted { $0.growthPotential > $1.growthPotential }
            case .confidence:
                return predictions.sorted { $0.confidenceLevel > $1.confidenceLevel }
            case .price:
                return predictions.sorted { $0.currentPrice < $1.currentPrice }
            case .alphabetical:
                return predictions.sorted { $0.stock.symbol < $1.stock.symbol }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Buscar símbolo o empresa", text: $text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EmptyPredictionsView: View {
    let isShortTerm: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Sin predicciones disponibles")
                .font(.headline)
            
            Text("No hay predicciones a \(isShortTerm ? "corto" : "largo") plazo disponibles en este momento. Por favor, intenta actualizar los datos.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: {
                // Acción para actualizar
            }) {
                Text("Actualizar datos")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

enum SortOrder {
    case potential, confidence, price, alphabetical
}

struct SortButton: View {
    @Binding var sortOrder: SortOrder
    
    var body: some View {
        Menu {
            Button("Mayor Potencial") { sortOrder = .potential }
            Button("Mayor Confianza") { sortOrder = .confidence }
            Button("Menor Precio") { sortOrder = .price }
            Button("Orden Alfabético") { sortOrder = .alphabetical }
        } label: {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                Text("Ordenar")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Analizando datos del mercado...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Esto puede tardar unos momentos")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemGray6).opacity(0.9))
            )
            .shadow(radius: 10)
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("maxStockPrice") private var maxStockPrice = 100.0
    @AppStorage("minConfidence") private var minConfidence = 0.6
    @AppStorage("refreshInterval") private var refreshInterval = 3
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Filtros de Predicción")) {
                    VStack(alignment: .leading) {
                        Text("Precio Máximo de Acción: $\(Int(maxStockPrice))")
                        Slider(value: $maxStockPrice, in: 10...500, step: 10)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Confianza Mínima: \(Int(minConfidence * 100))%")
                        Slider(value: $minConfidence, in: 0.5...0.9, step: 0.05)
                    }
                }
                
                Section(header: Text("Actualización de Datos")) {
                    Picker("Intervalo de Actualización", selection: $refreshInterval) {
                        Text("1 hora").tag(1)
                        Text("3 horas").tag(3)
                        Text("6 horas").tag(6)
                        Text("12 horas").tag(12)
                        Text("24 horas").tag(24)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("APIs")) {
                    HStack {
                        Text("Alpha Vantage")
                        Spacer()
                        Text("Conectado")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Finnhub")
                        Spacer()
                        Text("Conectado")
                            .foregroundColor(.green)
                    }
                }
                
                Section(header: Text("Información")) {
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Última actualización")
                        Spacer()
                        Text("13 May 2025, 00:45")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Configuración")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

import Foundation

struct Stock: Identifiable, Equatable, Hashable {
    let id = UUID()
    let symbol: String
    let name: String
    let currentPrice: Double
    let priceCategory: PriceCategory
    var sector: String
    var industry: String
    var country: String
    
    // Datos históricos se cargan bajo demanda
    var historicalData: [HistoricalDataPoint] = []
    
    enum PriceCategory: String, Codable {
        case economic
        case premium
    }
    
    // Determina si la acción es económica o premium
    static func determinePriceCategory(price: Double) -> PriceCategory {
        return price < 50.0 ? .economic : .premium
    }
    
    static func == (lhs: Stock, rhs: Stock) -> Bool {
        return lhs.symbol == rhs.symbol
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(symbol)
    }
}

import Foundation

struct HistoricalDataPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let openPrice: Double
    let highPrice: Double
    let lowPrice: Double
    let closePrice: Double
    let volume: Int
    
    // Campos calculados para análisis
    var change: Double {
        return closePrice - openPrice
    }
    
    var percentChange: Double {
        guard openPrice > 0 else { return 0 }
        return (closePrice - openPrice) / openPrice * 100
    }
    
    enum CodingKeys: String, CodingKey {
        case date = "t"
        case openPrice = "o"
        case highPrice = "h"
        case lowPrice = "l"
        case closePrice = "c"
        case volume = "v"
    }
}

import Foundation

struct NewsArticle: Identifiable, Codable {
    let id: Int
    let title: String
    let summary: String
    let url: String
    let publishedDate: Date
    let source: String
    let relevance: Double
    let sentimentScore: Double
    let sentimentLabel: String
    
    // Propiedad calculada para formatear la fecha
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: publishedDate)
    }
    
    // Propiedad calculada para determinar la categoría de sentimiento
    var sentiment: SentimentCategory {
        if sentimentScore >= 0.3 {
            return .positive
        } else if sentimentScore <= -0.3 {
            return .negative
        } else {
            return .neutral
        }
    }
    
    // Enum para las categorías de sentimiento
    enum SentimentCategory: String {
        case positive = "Positivo"
        case neutral = "Neutral"
        case negative = "Negativo"
    }
    
    // CodingKeys para personalizar la decodificación
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case url
        case publishedDate
        case source
        case relevance
        case sentimentScore
        case sentimentLabel
    }
    
    // Inicializador para cuando todos los datos están disponibles
    init(id: Int, title: String, summary: String, url: String, publishedDate: Date, source: String, relevance: Double, sentimentScore: Double, sentimentLabel: String) {
        self.id = id
        self.title = title
        self.summary = summary
        self.url = url
        self.publishedDate = publishedDate
        self.source = source
        self.relevance = relevance
        self.sentimentScore = sentimentScore
        self.sentimentLabel = sentimentLabel
    }
    
    // Inicializador desde Decoder para manejar valores opcionales/faltantes
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        
        // Valores con manejo de opcionalidad
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        url = try container.decode(String.self, forKey: .url)
        
        // Fechas - asume un formato específico
        if let dateString = try container.decodeIfPresent(String.self, forKey: .publishedDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let date = formatter.date(from: dateString) {
                publishedDate = date
            } else {
                publishedDate = Date()
            }
        } else {
            publishedDate = try container.decodeIfPresent(Date.self, forKey: .publishedDate) ?? Date()
        }
        
        source = try container.decode(String.self, forKey: .source)
        relevance = try container.decodeIfPresent(Double.self, forKey: .relevance) ?? 1.0
        sentimentScore = try container.decode(Double.self, forKey: .sentimentScore)
        
        // Corregido: primero decodificamos sentimentScore, luego calculamos la etiqueta si es necesario
        let decodedLabel = try container.decodeIfPresent(String.self, forKey: .sentimentLabel)
        if let label = decodedLabel {
            sentimentLabel = label
        } else {
            // Generar la etiqueta basada en el puntaje
            if sentimentScore >= 0.3 {
                sentimentLabel = "Positivo"
            } else if sentimentScore <= -0.3 {
                sentimentLabel = "Negativo"
            } else {
                sentimentLabel = "Neutral"
            }
        }
    }
}

// Extensión para funcionalidades adicionales
extension NewsArticle {
    // Método estático para crear un artículo de muestra (útil para previsualizaciones)
    static func sample(id: Int = 1, positive: Bool = true) -> NewsArticle {
        if positive {
            return NewsArticle(
                id: id,
                title: "Resultados trimestrales de Apple superan estimaciones; acciones suben 5%",
                summary: "Apple Inc. anunció resultados financieros que superaron las expectativas de Wall Street, impulsados por fuertes ventas del iPhone y crecimiento en servicios.",
                url: "https://example.com/apple-earnings",
                publishedDate: Date(),
                source: "Bloomberg",
                relevance: 0.85,
                sentimentScore: 0.75,
                sentimentLabel: "Positivo"
            )
        } else {
            return NewsArticle(
                id: id,
                title: "Tesla reporta pérdidas inesperadas en el primer trimestre",
                summary: "El fabricante de vehículos eléctricos reportó pérdidas mayores a las esperadas, citando problemas en la cadena de suministro y menor demanda en China.",
                url: "https://example.com/tesla-loss",
                publishedDate: Date(),
                source: "CNBC",
                relevance: 0.78,
                sentimentScore: -0.6,
                sentimentLabel: "Negativo"
            )
        }
    }
}
// Extensión para funcionalidades adicionales
//extension NewsArticle {
//    // Método estático para crear un artículo de muestra (útil para previsualizaciones)
//    static func sample(id: Int = 1, positive: Bool = true) -> NewsArticle {
//        if positive {
//            return NewsArticle(
//                id: id,
//                title: "Resultados trimestrales de Apple superan estimaciones; acciones suben 5%",
//                summary: "Apple Inc. anunció resultados financieros que superaron las expectativas de Wall Street, impulsados por fuertes ventas del iPhone y crecimiento en servicios.",
//                url: "https://example.com/apple-earnings",
//                publishedDate: Date(),
//                source: "Bloomberg",
//                relevance: 0.85,
//                sentimentScore: 0.75,
//                sentimentLabel: "Positivo"
//            )
//        } else {
//            return NewsArticle(
//                id: id,
//                title: "Tesla reporta pérdidas inesperadas en el primer trimestre",
//                summary: "El fabricante de vehículos eléctricos reportó pérdidas mayores a las esperadas, citando problemas en la cadena de suministro y menor demanda en China.",
//                url: "https://example.com/tesla-loss",
//                publishedDate: Date(),
//                source: "CNBC",
//                relevance: 0.78,
//                sentimentScore: -0.6,
//                sentimentLabel: "Negativo"
//            )
//        }
//    }
//}

import Foundation

struct CompanyProfile: Codable {
    let country: String
    let currency: String
    let exchange: String
    let name: String
    let ticker: String
    let webUrl: String
    let logo: String
    let finnhubIndustry: String
    let marketCapitalization: Double?
    let shareOutstanding: Double?
    
    var formattedMarketCap: String {
        guard let marketCap = marketCapitalization else { return "N/A" }
        
        if marketCap >= 1_000_000 {
            return String(format: "$%.2fB", marketCap / 1_000_000)
        } else if marketCap >= 1_000 {
            return String(format: "$%.2fM", marketCap / 1_000)
        } else {
            return String(format: "$%.2fK", marketCap)
        }
    }
}


import SwiftUI
import Charts

struct StockDetailView: View {
    let prediction: StockPrediction
    @StateObject private var viewModel: StockDetailViewModel
    
    init(prediction: StockPrediction) {
        self.prediction = prediction
        _viewModel = StateObject(wrappedValue: StockDetailViewModel(symbol: prediction.stock.symbol))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cabecera con resumen de predicción
                PredictionHeaderView(prediction: prediction)
                
                // Gráfico de precios históricos y predicción
                StockChartView(
                    prediction: prediction, historicalData: viewModel.historicalData
                )
                .frame(height: 250)
                .padding(.vertical)
                
                // Sección de Factores Clave
                KeyFactorsView(factors: prediction.keyFactors)
                
                // Sección de Noticias y Sentimiento
                NewsImpactView(newsAnalysis: prediction.newsAnalysis)
                
                // Indicadores Técnicos
                TechnicalIndicatorsView(signals: prediction.technicalSignals)
            }
            .padding()
        }
        .navigationTitle(prediction.stock.symbol)
        .onAppear {
            viewModel.loadData()
        }
    }
}

import SwiftUI
import Charts

struct StockChartView: View {
    let prediction: StockPrediction
    let historicalData: [HistoricalDataPoint]
    
    @State private var selectedTimeRange: TimeRange = .oneMonth
    @State private var showVolume: Bool = false
    @State private var showPrediction: Bool = true
    @State private var selectedDataPoint: HistoricalDataPoint?
    @State private var showIndicators: Bool = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cabecera de gráfico
            HStack {
                Text("Historial y Predicción")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showIndicators.toggle()
                }) {
                    Label(showIndicators ? "Ocultar Indicadores" : "Mostrar Indicadores",
                          systemImage: showIndicators ? "chart.xyaxis.line" : "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Controles de tiempo
            HStack {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedTimeRange = range
                    }) {
                        Text(range.title)
                            .font(.caption)
                            .fontWeight(selectedTimeRange == range ? .bold : .regular)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedTimeRange == range ? Color.blue.opacity(0.2) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                Button(action: {
                    showVolume.toggle()
                }) {
                    Label("Volumen", systemImage: showVolume ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    showPrediction.toggle()
                }) {
                    Label("Predicción", systemImage: showPrediction ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Gráfico principal
            if #available(iOS 16.0, *) {
                mainChartView
                    .frame(height: 300)
            } else {
                legacyChartView
                    .frame(height: 300)
            }
            
            // Panel de indicadores técnicos
            if showIndicators {
                technicalIndicatorsView
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Gráfico principal (iOS 16+)
    @available(iOS 16.0, *)
    private var mainChartView: some View {
        Chart {
            // Datos históricos - línea de precio
            ForEach(filteredHistoricalData) { dataPoint in
                LineMark(
                    x: .value("Fecha", dataPoint.date),
                    y: .value("Precio", dataPoint.closePrice)
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.monotone)
            }
            
            // Punto seleccionado
            if let selectedPoint = selectedDataPoint {
                PointMark(
                    x: .value("Fecha", selectedPoint.date),
                    y: .value("Precio", selectedPoint.closePrice)
                )
                .foregroundStyle(Color.blue)
                .symbolSize(100)
            }
            
            // Volumen (opcional)
            if showVolume {
                ForEach(filteredHistoricalData) { dataPoint in
                    BarMark(
                        x: .value("Fecha", dataPoint.date),
                        y: .value("Volumen", Double(dataPoint.volume) / volumeScale)
                    )
                    .foregroundStyle(Color.gray.opacity(0.5))
                }
                .position(by: .value("Serie", "Volumen"))
            }
            
            // Línea de predicción (opcional)
            if showPrediction, let lastPoint = filteredHistoricalData.last {
                // Regla vertical en el último punto de datos
                RuleMark(
                    x: .value("Último", lastPoint.date)
                )
                .foregroundStyle(Color.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                
                // Línea de tendencia hacia el precio predicho
                LineMark(
                    x: .value("Fecha", lastPoint.date),
                    y: .value("Precio", lastPoint.closePrice)
                )
                .foregroundStyle(prediction.isPotentialPositive ? Color.green : Color.red)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                
                LineMark(
                    x: .value("Fecha", prediction.targetDate),
                    y: .value("Precio", prediction.predictedPrice)
                )
                .foregroundStyle(prediction.isPotentialPositive ? Color.green : Color.red)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                
                // Punto de predicción final
                PointMark(
                    x: .value("Fecha Objetivo", prediction.targetDate),
                    y: .value("Precio Predicho", prediction.predictedPrice)
                )
                .foregroundStyle(prediction.isPotentialPositive ? Color.green : Color.red)
                .annotation(position: .top) {
                    Text("$\(prediction.predictedPrice, specifier: "%.2f")")
                        .font(.caption)
                        .bold()
                        .foregroundColor(prediction.isPotentialPositive ? .green : .red)
                        .padding(4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(4)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: xAxisStride)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel("$\(value.as(Double.self)?.formatted(.number.precision(.fractionLength(2))) ?? "")")
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                if let date = proxy.value(atX: x) as Date?,
                                   let dataPoint = closestDataPoint(to: date) {
                                    selectedDataPoint = dataPoint
                                }
                            }
                            .onEnded { _ in
                                selectedDataPoint = nil
                            }
                    )
            }
        }
    }
    
    // Gráfico para iOS anterior a 16 (fallback)
    private var legacyChartView: some View {
        VStack(spacing: 10) {
            // Barra de info precio/fecha
            HStack {
                if let selectedPoint = selectedDataPoint {
                    Text(dateFormatter.string(from: selectedPoint.date))
                    Spacer()
                    Text("$\(selectedPoint.closePrice, specifier: "%.2f")")
                        .bold()
                } else if let lastPoint = filteredHistoricalData.last {
                    Text(dateFormatter.string(from: lastPoint.date))
                    Spacer()
                    Text("$\(lastPoint.closePrice, specifier: "%.2f")")
                        .bold()
                }
            }
            .font(.caption)
            .padding(6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)
            
            // Gráfico simplificado para iOS 15 y anteriores
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Líneas de cuadrícula horizontales
                    VStack(alignment: .leading) {
                        ForEach(0..<5) { i in
                            Divider()
                                .opacity(0.5)
                            Spacer()
                                .frame(maxHeight: .infinity)
                        }
                        Divider()
                            .opacity(0.5)
                    }
                    
                    // Línea de precio histórico
                    Path { path in
                        let points = filteredHistoricalData
                        let maxPrice = points.map { $0.highPrice }.max() ?? 1
                        let minPrice = points.map { $0.lowPrice }.min() ?? 0
                        let priceRange = maxPrice - minPrice
                        
                        guard let firstPoint = points.first, points.count > 1 else { return }
                        
                        let stepX = geometry.size.width / CGFloat(points.count - 1)
                        
                        path.move(to: CGPoint(
                            x: 0,
                            y: geometry.size.height * (1 - CGFloat((firstPoint.closePrice - minPrice) / priceRange))
                        ))
                        
                        for (index, point) in points.dropFirst().enumerated() {
                            let x = CGFloat(index + 1) * stepX
                            let y = geometry.size.height * (1 - CGFloat((point.closePrice - minPrice) / priceRange))
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                    
                    // Línea de predicción
                    if showPrediction, let lastPoint = filteredHistoricalData.last {
                        let maxPrice = filteredHistoricalData.map { $0.highPrice }.max() ?? 1
                        let minPrice = filteredHistoricalData.map { $0.lowPrice }.min() ?? 0
                        let priceRange = max(maxPrice, prediction.predictedPrice) - min(minPrice, prediction.predictedPrice)
                        
                        let startX = CGFloat(filteredHistoricalData.count - 1) * (geometry.size.width / CGFloat(filteredHistoricalData.count - 1))
                        let startY = geometry.size.height * (1 - CGFloat((lastPoint.closePrice - minPrice) / priceRange))
                        let endY = geometry.size.height * (1 - CGFloat((prediction.predictedPrice - minPrice) / priceRange))
                        
                        Path { path in
                            path.move(to: CGPoint(x: startX, y: startY))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: endY))
                        }
                        .stroke(prediction.isPotentialPositive ? Color.green : Color.red, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        
                        // Punto de predicción
                        Circle()
                            .fill(prediction.isPotentialPositive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                            .position(x: geometry.size.width, y: endY)
                            .overlay(
                                Text("$\(prediction.predictedPrice, specifier: "%.2f")")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(prediction.isPotentialPositive ? .green : .red)
                                    .offset(y: -15)
                            )
                    }
                }
            }
        }
    }
    
    // Vista de indicadores técnicos
    private var technicalIndicatorsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Indicadores Técnicos")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Mostrar indicadores en formato tabla
            VStack(spacing: 8) {
                // SMA 20 y 50
                HStack {
                    Text("SMA 20/50")
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    let (sma20, sma50) = calculateSMAs()
                    let comparison = compareSMAs(sma20: sma20, sma50: sma50)
                    
                    HStack(spacing: 4) {
                        Text("$\(sma20, specifier: "%.2f")")
                            .font(.caption)
                        Text("/")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("$\(sma50, specifier: "%.2f")")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Image(systemName: comparison == .bullish ? "arrow.up" : (comparison == .bearish ? "arrow.down" : "minus"))
                        .foregroundColor(comparison == .bullish ? .green : (comparison == .bearish ? .red : .gray))
                        .font(.caption)
                }
                
                Divider()
                
                // RSI
                HStack {
                    Text("RSI (14)")
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    let rsi = calculateRSI()
                    Text("\(rsi, specifier: "%.1f")")
                        .font(.caption)
                    
                    Spacer()
                    
                    // Categoría RSI
                    Text(rsiCategory(rsi))
                        .font(.caption)
                        .foregroundColor(rsiColor(rsi))
                }
                
                Divider()
                
                // MACD
                HStack {
                    Text("MACD")
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    let (macdLine, signalLine) = calculateMACD()
                    let macdDiff = macdLine - signalLine
                    
                    Text("\(macdDiff, specifier: "%.2f")")
                        .font(.caption)
                    
                    Spacer()
                    
                    // Señal MACD
                    Text(macdDiff > 0 ? "Alcista" : (macdDiff < 0 ? "Bajista" : "Neutral"))
                        .font(.caption)
                        .foregroundColor(macdDiff > 0 ? .green : (macdDiff < 0 ? .red : .gray))
                }
                
                Divider()
                
                // Bandas de Bollinger
                HStack {
                    Text("Bollinger")
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    let (upper, middle, lower) = calculateBollingerBands()
                    let current = filteredHistoricalData.last?.closePrice ?? 0
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Superior: $\(upper, specifier: "%.2f")")
                            .font(.caption)
                        Text("Media: $\(middle, specifier: "%.2f")")
                            .font(.caption)
                        Text("Inferior: $\(lower, specifier: "%.2f")")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    // Posición actual en las bandas
                    let position = bollingerPosition(current: current, upper: upper, lower: lower)
                    Text(position.description)
                        .font(.caption)
                        .foregroundColor(position.color)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.5))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Datos y cálculos
    
    private var filteredHistoricalData: [HistoricalDataPoint] {
        let filteredData: [HistoricalDataPoint]
        
        // Filtrar según el rango de tiempo seleccionado
        switch selectedTimeRange {
        case .oneWeek:
            filteredData = historicalData.filter {
                $0.date >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            }
        case .oneMonth:
            filteredData = historicalData.filter {
                $0.date >= Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            }
        case .threeMonths:
            filteredData = historicalData.filter {
                $0.date >= Calendar.current.date(byAdding: .month, value: -3, to: Date())!
            }
        case .sixMonths:
            filteredData = historicalData.filter {
                $0.date >= Calendar.current.date(byAdding: .month, value: -6, to: Date())!
            }
        case .oneYear:
            filteredData = historicalData.filter {
                $0.date >= Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            }
        case .all:
            filteredData = historicalData
        }
        
        // Si no hay suficientes datos después del filtro, devolver todo
        return filteredData.count > 1 ? filteredData : historicalData
    }
    
    private var xAxisStride: Calendar.Component {
        switch selectedTimeRange {
        case .oneWeek: return .day
        case .oneMonth: return .weekOfMonth
        case .threeMonths: return .month
        case .sixMonths: return .month
        case .oneYear: return .month
        case .all: return .year
        }
    }
    
    private var volumeScale: Double {
        // Escalar volumen para mostrarlo en el mismo gráfico que los precios
        let maxVolume = filteredHistoricalData.map { Double($0.volume) }.max() ?? 1.0
        let avgPrice = filteredHistoricalData.map { $0.closePrice }.reduce(0, +) / Double(filteredHistoricalData.count)
        return maxVolume / (avgPrice * 3)
    }
    
    private func closestDataPoint(to date: Date) -> HistoricalDataPoint? {
        // Encontrar el punto de datos más cercano a la fecha seleccionada
        guard !filteredHistoricalData.isEmpty else { return nil }
        
        return filteredHistoricalData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    // MARK: - Cálculos de Indicadores Técnicos
    
    // SMA - Simple Moving Average
    private func calculateSMAs() -> (sma20: Double, sma50: Double) {
        let prices = filteredHistoricalData.map { $0.closePrice }
        
        // SMA 20
        let sma20Count = min(20, prices.count)
        let sma20 = prices.suffix(sma20Count).reduce(0, +) / Double(sma20Count)
        
        // SMA 50
        let sma50Count = min(50, prices.count)
        let sma50 = prices.suffix(sma50Count).reduce(0, +) / Double(sma50Count)
        
        return (sma20, sma50)
    }
    
    private enum SMAComparison {
        case bullish, bearish, neutral
    }
    
    private func compareSMAs(sma20: Double, sma50: Double) -> SMAComparison {
        let currentPrice = filteredHistoricalData.last?.closePrice ?? 0
        
        if currentPrice > sma20 && sma20 > sma50 {
            return .bullish
        } else if currentPrice < sma20 && sma20 < sma50 {
            return .bearish
        } else {
            return .neutral
        }
    }
    
    // RSI - Relative Strength Index
    private func calculateRSI() -> Double {
        guard filteredHistoricalData.count >= 15 else { return 50.0 }
        
        let prices = filteredHistoricalData.map { $0.closePrice }
        let period = 14
        
        // Calcular cambios diarios
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            gains.append(max(0, change))
            losses.append(max(0, -change))
        }
        
        // Limitar a los últimos 14 cambios para RSI
        let recentGains = Array(gains.suffix(period))
        let recentLosses = Array(losses.suffix(period))
        
        let avgGain = recentGains.reduce(0, +) / Double(period)
        let avgLoss = recentLosses.reduce(0, +) / Double(period)
        
        // Evitar división por cero
        guard avgLoss > 0 else { return 100.0 }
        
        let rs = avgGain / avgLoss
        let rsi = 100.0 - (100.0 / (1.0 + rs))
        
        return rsi
    }
    
    private func rsiCategory(_ rsi: Double) -> String {
        if rsi >= 70 {
            return "Sobrecompra"
        } else if rsi <= 30 {
            return "Sobreventa"
        } else {
            return "Neutral"
        }
    }
    
    private func rsiColor(_ rsi: Double) -> Color {
        if rsi >= 70 {
            return .red
        } else if rsi <= 30 {
            return .green
        } else {
            return .gray
        }
    }
    
    // MACD - Moving Average Convergence Divergence
    private func calculateMACD() -> (macdLine: Double, signalLine: Double) {
        guard filteredHistoricalData.count >= 26 else { return (0, 0) }
        
        let prices = filteredHistoricalData.map { $0.closePrice }
        
        // Versión simplificada (en una implementación real sería más precisa)
        // EMA 12
        let ema12Weight = 2.0 / (12.0 + 1.0)
        var ema12 = prices.prefix(12).reduce(0, +) / 12.0
        
        for price in prices.suffix(from: 12) {
            ema12 = (price - ema12) * ema12Weight + ema12
        }
        
        // EMA 26
        let ema26Weight = 2.0 / (26.0 + 1.0)
        var ema26 = prices.prefix(26).reduce(0, +) / 26.0
        
        for price in prices.suffix(from: 26) {
            ema26 = (price - ema26) * ema26Weight + ema26
        }
        
        // MACD Line = EMA 12 - EMA 26
        let macdLine = ema12 - ema26
        
        // Signal Line (EMA 9 del MACD)
        // Simplificación para este ejemplo
        let signalLine = macdLine * 0.9  // Aproximación
        
        return (macdLine, signalLine)
    }
    
    // Bandas de Bollinger
    private func calculateBollingerBands() -> (upper: Double, middle: Double, lower: Double) {
        guard filteredHistoricalData.count >= 20 else {
            let avg = filteredHistoricalData.map { $0.closePrice }.reduce(0, +) / Double(filteredHistoricalData.count)
            return (avg * 1.1, avg, avg * 0.9)
        }
        
        let prices = filteredHistoricalData.suffix(20).map { $0.closePrice }
        let sma = prices.reduce(0, +) / Double(prices.count)
        
        // Calcular desviación estándar
        let variance = prices.map { pow($0 - sma, 2) }.reduce(0, +) / Double(prices.count)
        let stdDev = sqrt(variance)
        
        // Bandas = SMA ± (2 * StdDev)
        return (sma + (2 * stdDev), sma, sma - (2 * stdDev))
    }
    
    private enum BollingerPosition {
        case above, within, below
        
        var description: String {
            switch self {
            case .above: return "Sobrecompra"
            case .within: return "Neutral"
            case .below: return "Sobreventa"
            }
        }
        
        var color: Color {
            switch self {
            case .above: return .red
            case .within: return .gray
            case .below: return .green
            }
        }
    }
    
    private func bollingerPosition(current: Double, upper: Double, lower: Double) -> BollingerPosition {
        if current > upper {
            return .above
        } else if current < lower {
            return .below
        } else {
            return .within
        }
    }
}

// Añadir al principio, fuera de la vista principal:
struct PredictionPoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
    var isFuture: Bool {
        return date > Date()
    }
}

// Opciones de rango de tiempo para el gráfico
enum TimeRange: String, CaseIterable {
    case oneWeek = "1S"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1A"
    case all = "Todo"
    
    var title: String {
        return self.rawValue
    }
}

// Vista previa para SwiftUI Canvas
struct StockChartView_Previews: PreviewProvider {
    static var previews: some View {
        let historicalData = generateMockHistoricalData()
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 185.92,
            priceCategory: .premium,
            sector: "Technology",
            industry: "Consumer Electronics",
            country: "United States"
        )
        
        let prediction = StockPrediction(
            stock: stock,
            predictedPrice: 195.45,
            currentPrice: 185.92,
            growthPotential: 5.12,
            confidenceLevel: 0.82,
            timeFrame: .shortTerm,
            keyFactors: [
                PredictionFactor(name: "Tendencia Alcista", impact: 3.2, description: "Precio por encima de medias móviles")
            ],
            technicalSignals: [.buy],
            newsAnalysis: NewsAnalysisResult(
                sentimentImpact: 2.5,
                confidence: 0.75,
                keyFactors: [],
                topArticles: []
            ),
            targetDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        )
        
        return StockChartView(prediction: prediction, historicalData: historicalData)
            .frame(height: 500)
            .padding()
            .previewLayout(.sizeThatFits)
    }
    
    // Generar datos históricos de muestra para previsualización
    static func generateMockHistoricalData() -> [HistoricalDataPoint] {
        var data: [HistoricalDataPoint] = []
        let calendar = Calendar.current
        var date = calendar.date(byAdding: .year, value: -1, to: Date())!
        
        var price = 150.0
        let volatility = 2.0
        
        while date < Date() {
            // Simular cambio de precio aleatorio
            let change = Double.random(in: -volatility...volatility)
            let percentChange = change / 100.0
            price = price * (1.0 + percentChange)
            
            // Crear punto de datos
            let dataPoint = HistoricalDataPoint(
                date: date,
                openPrice: price * (1.0 - Double.random(in: 0.0...0.01)),
                highPrice: price * (1.0 + Double.random(in: 0.0...0.02)),
                lowPrice: price * (1.0 - Double.random(in: 0.0...0.02)),
                closePrice: price,
                volume: Int.random(in: 500000...5000000)
            )
            
            data.append(dataPoint)
            
            // Avanzar un día
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        return data
    }
}

struct PredictionHeaderView: View {
    let prediction: StockPrediction
    
    var body: some View {
        VStack(spacing: 12) {
            // Nombre de la empresa y detalles
            Text(prediction.stock.name)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            // Tipo de predicción
            Text(prediction.timeFrame == .shortTerm ? "Predicción a Corto Plazo" : "Predicción a Largo Plazo")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Resumen de predicción
            HStack(spacing: 30) {
                VStack {
                    Text("Actual")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(prediction.currentPrice, specifier: "%.2f")")
                        .font(.title3)
                        .bold()
                }
                
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundColor(.green)
                
                VStack {
                    Text("Objetivo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(prediction.predictedPrice, specifier: "%.2f")")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.green)
                }
            }
            
            // Crecimiento potencial y fecha objetivo
            HStack(spacing: 30) {
                VStack {
                    Text("Potencial")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(prediction.growthPotential, specifier: "+%.2f")%")
                        .font(.headline)
                        .foregroundColor(.green)
                        .bold()
                }
                
                VStack {
                    Text("Fecha Objetivo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prediction.targetDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                }
            }
            
            // Nivel de confianza
            VStack(spacing: 2) {
                Text("Nivel de Confianza: \(Int(prediction.confidenceLevel * 100))%")
                    .font(.subheadline)
                
                ConfidenceMeter(level: prediction.confidenceLevel)
                    .frame(height: 8)
                    .padding(.horizontal)
            }
            .padding(.top, 5)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KeyFactorsView: View {
    let factors: [PredictionFactor]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Factores Clave")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(factors) { factor in
                HStack {
                    Circle()
                        .fill(factor.impact > 0 ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
                    Text(factor.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(factor.impact > 0 ? "+\(factor.impact, specifier: "%.1f")%" : "\(factor.impact, specifier: "%.1f")%")
                        .font(.subheadline)
                        .foregroundColor(factor.impact > 0 ? .green : .red)
                }
                
                if let index = factors.firstIndex(where: { $0.id == factor.id }),
                   index < factors.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NewsImpactView: View {
    let newsAnalysis: NewsAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Impacto de Noticias")
                .font(.headline)
            
            // Medidor de impacto de sentimiento
            HStack {
                Text("Sentimiento:")
                Spacer()
                SentimentIndicator(value: newsAnalysis.sentimentImpact / 10) // Normalizar a escala -1 a 1
                    .frame(width: 120, height: 20)
            }
            
            Divider()
            
            // Noticias importantes
            Text("Noticias Relevantes")
                .font(.subheadline)
                .bold()
            
            ForEach(newsAnalysis.topArticles.prefix(3), id: \.id) { article in
                NewsItemView(article: article)
                    .padding(.vertical, 5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

import SwiftUI

struct NewsItemView: View {
    let article: NewsArticle
    var onTap: () -> Void = {}
    
    private var sentimentColor: Color {
        switch article.sentiment {
        case .positive:
            return Color.green
        case .negative:
            return Color.red
        case .neutral:
            return Color.gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Cabecera con fuente y fecha
                HStack {
                    Text(article.source)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(article.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Título de la noticia
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Resumen y sentimiento
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.summary ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Indicador de sentimiento
                    HStack {
                        Text(article.sentimentLabel)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(sentimentColor.opacity(0.2))
                            .foregroundColor(sentimentColor)
                            .cornerRadius(4)
                        
                        // Indicador de relevancia
                        Text("Relevancia: \(Int(article.relevance * 100))%")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Vista para usar en listas con diseño optimizado
struct NewsItemRow: View {
    let article: NewsArticle
    var onTap: () -> Void = {}
    
    var body: some View {
        NewsItemView(article: article, onTap: onTap)
            .padding(.horizontal)
            .padding(.vertical, 4)
    }
}

// Vista de previsualización para SwiftUI Canvas
struct NewsItemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Artículos de muestra para previsualización
            let positiveArticle = createPositiveArticle()
            let negativeArticle = createNegativeArticle()
            
            VStack(spacing: 16) {
                NewsItemView(article: positiveArticle)
                NewsItemView(article: negativeArticle)
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Noticias")
            
            // Vista en modo lista
            List {
                NewsItemRow(article: positiveArticle)
                NewsItemRow(article: negativeArticle)
            }
            .listStyle(InsetGroupedListStyle())
            .previewLayout(.fixed(width: 375, height: 280))
            .previewDisplayName("Lista de Noticias")
        }
    }
    
    // Métodos auxiliares para crear artículos de muestra
    static func createPositiveArticle() -> NewsArticle {
        return NewsArticle(
            id: 1,
            title: "Resultados trimestrales de Apple superan estimaciones; acciones suben 5%",
            summary: "Apple Inc. anunció resultados financieros que superaron las expectativas de Wall Street, impulsados por fuertes ventas del iPhone y crecimiento en servicios.",
            url: "https://example.com/apple-earnings",
            publishedDate: Date(),
            source: "Bloomberg",
            relevance: 0.85,
            sentimentScore: 0.75,
            sentimentLabel: "Positivo"
        )
    }
    
    static func createNegativeArticle() -> NewsArticle {
        return NewsArticle(
            id: 2,
            title: "Tesla reporta pérdidas inesperadas en el primer trimestre",
            summary: "El fabricante de vehículos eléctricos reportó pérdidas mayores a las esperadas, citando problemas en la cadena de suministro y menor demanda en China.",
            url: "https://example.com/tesla-loss",
            publishedDate: Date(),
            source: "CNBC",
            relevance: 0.78,
            sentimentScore: -0.6,
            sentimentLabel: "Negativo"
        )
    }
}

// Vista para usar en listas con diseño optimizado
//struct NewsItemRow: View {
//    let article: NewsArticle
//    var onTap: () -> Void = {}
//    
//    var body: some View {
//        NewsItemView(article: article, onTap: onTap)
//            .padding(.horizontal)
//            .padding(.vertical, 4)
//    }
//}

// Vista de previsualización para SwiftUI Canvas
//struct NewsItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            // Noticia positiva
//            let positiveArticle = NewsArticle(
//                id: "1",
//                headline: "Resultados trimestrales de Apple superan estimaciones; acciones suben 5%",
//                source: "Bloomberg",
//                url: "https://example.com/apple-earnings",
//                summary: "Apple Inc. anunció resultados financieros que superaron las expectativas de Wall Street, impulsados por fuertes ventas del iPhone y crecimiento en servicios.",
//                datetime: Date(),
//                image: nil,
//                imageUrl: "https://example.com/apple-logo.jpg",
//                related: nil,
//                sentiment: 0.75,
//                categories: ["Tecnología", "Finanzas"]
//            )
//            
//            // Noticia negativa
//            let negativeArticle = NewsArticle(
//                id: "2",
//                headline: "Tesla reporta pérdidas inesperadas en el primer trimestre",
//                source: "CNBC",
//                url: "https://example.com/tesla-loss",
//                summary: "El fabricante de vehículos eléctricos reportó pérdidas mayores a las esperadas, citando problemas en la cadena de suministro y menor demanda en China.",
//                datetime: Date(),
//                image: nil,
//                imageUrl: "https://example.com/tesla-logo.jpg",
//                related: nil,
//                sentiment: -0.6,
//                categories: ["Automotriz", "Finanzas"]
//            )
//            
//            VStack(spacing: 16) {
//                NewsItemView(article: positiveArticle)
//                NewsItemView(article: negativeArticle)
//            }
//            .padding()
//            .previewLayout(.sizeThatFits)
//            .previewDisplayName("Noticias")
//            
//            // Vista en modo lista
//            List {
//                NewsItemRow(article: positiveArticle)
//                NewsItemRow(article: negativeArticle)
//            }
//            .listStyle(InsetGroupedListStyle())
//            .previewLayout(.fixed(width: 375, height: 280))
//            .previewDisplayName("Lista de Noticias")
//        }
//    }
//}

import SwiftUI
import WebKit

struct NewsDetailView: View {
    let article: NewsArticle
    
    // Color calculado internamente basado en la categoría de sentimiento
    private var sentimentColor: Color {
        switch article.sentiment {
        case .positive:
            return .green
        case .negative:
            return .red
        case .neutral:
            return .gray
        }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showWebView: Bool = false
    @State private var showShareSheet: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Título y metadatos
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 10) {
                        // Fuente
                        Text(article.source)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Fecha
                        Text(dateFormatter.string(from: article.publishedDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Indicador de sentimiento

                    // Con:
                    // Indicador de sentimiento
                    SentimentIndicator(value: article.sentimentScore)
                    .padding(.vertical, 6)
                }
                
                Divider()
                
                // Resumen o contenido
                if !article.summary.isEmpty {
                    Text(article.summary)
                        .font(.body)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 4)
                } else {
                    Text("No hay resumen disponible para esta noticia.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.vertical, 4)
                }
                
                Divider()
                
                // Indicador de relevancia
                HStack {
                    Text("Relevancia")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Barra de relevancia
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: 150, height: 10)
                            .cornerRadius(5)
                            .foregroundColor(Color.gray.opacity(0.3))
                        
                        Rectangle()
                            .frame(width: 150 * CGFloat(article.relevance), height: 10)
                            .cornerRadius(5)
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(Int(article.relevance * 100))%")
                        .font(.caption)
                        .padding(.leading, 4)
                }
                .padding(.vertical, 8)
                
                // Botones de acción
                HStack(spacing: 20) {
                    // Botón para abrir en navegador
                    Button(action: {
                        showWebView = true
                    }) {
                        VStack {
                            Image(systemName: "safari")
                                .font(.title2)
                            Text("Ver artículo completo")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Botón para compartir
                    Button(action: {
                        showShareSheet = true
                    }) {
                        VStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                            Text("Compartir")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 10)
                
                // Fuente original y fecha de publicación
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fuente original:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link(article.url, destination: URL(string: article.url) ?? URL(string: "https://example.com")!)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationBarTitle("Noticia", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            showShareSheet = true
        }) {
            Image(systemName: "square.and.arrow.up")
        })
        .sheet(isPresented: $showWebView) {
            SafariWebView(url: URL(string: article.url) ?? URL(string: "https://example.com")!)
                .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = URL(string: article.url) {
                ActivityViewController(activityItems: [article.title, url])
            }
        }
    }
}

import SwiftUI
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    // Acciones que queremos excluir del menú de compartir (opcional)
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    // Callback cuando se completa la acción de compartir (opcional)
    var callback: ((Bool, [UIActivity.ActivityType]?) -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // Configurar las acciones excluidas si hay alguna
        if let excludedTypes = excludedActivityTypes {
            controller.excludedActivityTypes = excludedTypes
        }
        
        // Configurar el callback de finalización
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            callback?(completed, [activityType].compactMap { $0 })
        }
        
        // En iPad, necesitamos configurar el popover presentation
        if let popover = controller.popoverPresentationController {
            popover.permittedArrowDirections = .any
            popover.sourceView = UIView() // Esto se actualizará en updateUIViewController
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // En iPad, necesitamos asegurarnos de que el popover tenga una sourceView válida
        if let popover = uiViewController.popoverPresentationController {
            // Usar la vista raíz actual como sourceView
            if let sourceView = UIApplication.shared.windows.first?.rootViewController?.view {
                popover.sourceView = sourceView
                popover.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            }
        }
    }
}

// Extensión para hacer más fácil el uso desde SwiftUI
extension View {
    func shareSheet(
        isPresented: Binding<Bool>,
        items: [Any],
        excludedActivityTypes: [UIActivity.ActivityType]? = nil,
        onCompletion: ((Bool, [UIActivity.ActivityType]?) -> Void)? = nil
    ) -> some View {
        sheet(isPresented: isPresented) {
            ActivityViewController(
                activityItems: items,
                excludedActivityTypes: excludedActivityTypes,
                callback: onCompletion
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
}

#if DEBUG
// Vista previa para desarrollo
struct ActivityViewController_Previews: PreviewProvider {
    static var previews: some View {
        Button("Compartir") {
            // No podemos mostrar un ActivityViewController en previews
            // Esto es solo para mostrar el botón
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif

import SwiftUI
import WebKit

struct SafariWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

#if DEBUG
// Vista previa para desarrollo
struct SafariWebView_Previews: PreviewProvider {
    static var previews: some View {
        SafariWebView(url: URL(string: "https://www.apple.com")!)
            .previewLayout(.sizeThatFits)
            .frame(height: 300)
    }
}
#endif

import SwiftUI

struct SentimentIndicator: View {
    let value: Double
    
    private var sentimentLabel: String {
        if value > 0.3 {
            return "Positivo"
        } else if value < -0.3 {
            return "Negativo"
        } else {
            return "Neutral"
        }
    }
    
    private var sentimentColor: Color {
        if value > 0.3 {
            return .green
        } else if value < -0.3 {
            return .red
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Sentimiento:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(sentimentLabel)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(sentimentColor)
                .cornerRadius(12)
        }
    }
}

// Vista previa
struct SentimentIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SentimentIndicator(value: 0.7)
            SentimentIndicator(value: 0.1)
            SentimentIndicator(value: -0.5)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// Vista para indicador de sentimiento
//struct SentimentIndicator: View {
//    let sentiment: Double
//    let sentimentLabel: String
//    let color: Color
//    
//    var body: some View {
//        HStack(spacing: 8) {
//            Text("Sentimiento:")
//                .font(.caption)
//                .foregroundColor(.secondary)
//            
//            Text(sentimentLabel)
//                .font(.caption)
//                .foregroundColor(.white)
//                .padding(.horizontal, 10)
//                .padding(.vertical, 3)
//                .background(color)
//                .cornerRadius(12)
//        }
//    }
//}
//
//// Vista para indicador de sentimiento
//struct SentimentIndicator: View {
//    let sentiment: Double
//    let color: Color
//    
//    private var sentimentDescription: String {
//        if sentiment > 0.3 {
//            return "Positivo"
//        } else if sentiment < -0.3 {
//            return "Negativo"
//        } else {
//            return "Neutral"
//        }
//    }
//    
//    var body: some View {
//        HStack(spacing: 8) {
//            Text("Sentimiento:")
//                .font(.caption)
//                .foregroundColor(.secondary)
//            
//            Text(sentimentDescription)
//                .font(.caption)
//                .foregroundColor(.white)
//                .padding(.horizontal, 10)
//                .padding(.vertical, 3)
//                .background(color)
//                .cornerRadius(12)
//        }
//    }
//}
//
//// Resto del código igual...
//
//struct SentimentIndicator: View {
//    let value: Double // -1.0 a 1.0
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack(alignment: .leading) {
//                // Fondo
//                Rectangle()
//                    .frame(width: geometry.size.width, height: geometry.size.height)
//                    .foregroundColor(Color(.systemGray5))
//                    .cornerRadius(geometry.size.height / 2)
//                
//                // Gradiente
//                LinearGradient(
//                    gradient: Gradient(colors: [.red, .orange, .yellow, .green]),
//                    startPoint: .leading,
//                    endPoint: .trailing
//                )
//                .frame(width: geometry.size.width, height: geometry.size.height)
//                .cornerRadius(geometry.size.height / 2)
//                
//                // Indicador
//                Circle()
//                    .fill(Color.white)
//                    .frame(width: geometry.size.height * 1.2, height: geometry.size.height * 1.2)
//                    .shadow(radius: 2)
//                    .offset(x: CGFloat((value + 1) / 2) * (geometry.size.width - geometry.size.height * 1.2))
//            }
//        }
//    }
//}

struct TechnicalIndicatorsView: View {
    let signals: [TechnicalSignal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Señales Técnicas")
                .font(.headline)
            
            // Mostrar cada señal técnica
            ForEach(signals, id: \.self) { signal in
                HStack {
                    Image(systemName: iconForSignal(signal))
                        .foregroundColor(colorForSignal(signal))
                    
                    Text(signal.rawValue)
                        .font(.subheadline)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func iconForSignal(_ signal: TechnicalSignal) -> String {
        switch signal {
            case .strongBuy: return "arrow.up.circle.fill"
            case .buy: return "arrow.up.circle"
            case .neutral: return "minus.circle"
            case .sell: return "arrow.down.circle"
            case .strongSell: return "arrow.down.circle.fill"
        }
    }
    
    private func colorForSignal(_ signal: TechnicalSignal) -> Color {
        switch signal {
            case .strongBuy: return .green
            case .buy: return .green.opacity(0.7)
            case .neutral: return .gray
            case .sell: return .red.opacity(0.7)
            case .strongSell: return .red
        }
    }
}
