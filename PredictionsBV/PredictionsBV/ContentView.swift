//
//  ContentView.swift
//  PredictionsBV
//
//  Created by Luis Vega on 12/05/25.
//

//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    ContentView()
//}

import Foundation

struct StockPrediction: Identifiable {
    let id = UUID()
    let stock: Stock
    let predictedPrice: Double
    let currentPrice: Double
    let growthPotential: Double
    let confidenceLevel: Double
    var timeFrame: TimeFrame
    let keyFactors: [PredictionFactor]
    let technicalSignals: [TechnicalSignal]
    let newsAnalysis: NewsAnalysisResult
    let targetDate: Date
    
    // Definir TimeFrame como tipo anidado dentro de StockPrediction
    enum TimeFrame {
        case shortTerm
        case longTerm
        
        var description: String {
            switch self {
            case .shortTerm:
                return "Corto Plazo"
            case .longTerm:
                return "Largo Plazo"
            }
        }
        
        var days: Int {
            switch self {
            case .shortTerm:
                return 30
            case .longTerm:
                return 90
            }
        }
    }
    
    var formattedPotential: String {
        return String(format: "%.2f%%", growthPotential)
    }
    
    var isPotentialPositive: Bool {
        return growthPotential > 0
    }
    
    var formattedConfidence: String {
        return String(format: "%.0f%%", confidenceLevel * 100)
    }
}

import Foundation

struct PredictionFactor: Identifiable {
    let id = UUID()
    let name: String
    let impact: Double // Impacto en porcentaje sobre la predicción
    let description: String
    
    var formattedImpact: String {
        if impact > 0 {
            return "+\(String(format: "%.2f", impact))%"
        } else {
            return "\(String(format: "%.2f", impact))%"
        }
    }
}

import Foundation

enum TimeFrame: String, CaseIterable {
    case shortTerm = "Corto Plazo"
    case longTerm = "Largo Plazo"
    
    var description: String {
        switch self {
        case .shortTerm:
            return "4-6 semanas"
        case .longTerm:
            return "3-4 meses"
        }
    }
    
    var days: Int {
        switch self {
        case .shortTerm:
            return 30
        case .longTerm:
            return 90
        }
    }
}

import Foundation
import SwiftUI

enum TechnicalSignal: String, CaseIterable {
    case strongBuy = "Compra Fuerte"
    case buy = "Compra"
    case neutral = "Neutral"
    case sell = "Venta"
    case strongSell = "Venta Fuerte"
    
    var icon: String {
        switch self {
        case .strongBuy: return "arrow.up.circle.fill"
        case .buy: return "arrow.up.circle"
        case .neutral: return "minus.circle"
        case .sell: return "arrow.down.circle"
        case .strongSell: return "arrow.down.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .strongBuy: return .green
        case .buy: return .green.opacity(0.7)
        case .neutral: return .gray
        case .sell: return .red.opacity(0.7)
        case .strongSell: return .red
        }
    }
}

import Foundation

struct TechnicalAnalysisResult {
    let predictedChangePercent: Double
    let confidence: Double
    let signals: [TechnicalSignal]
    let keyFactors: [PredictionFactor]
    
    // Métricas adicionales para diagnóstico interno
    let movingAverages: MovingAverages
    let oscillators: Oscillators
    
    struct MovingAverages {
        let sma20: Double
        let sma50: Double
        let ema12: Double
        let ema26: Double
    }
    
    struct Oscillators {
        let rsi: Double
        let macdLine: Double
        let macdSignal: Double
        let stochasticK: Double
        let stochasticD: Double
    }
}

import Foundation

struct NewsAnalysisResult {
    let sentimentImpact: Double       // Impacto estimado en el precio (-10 a +10)
    let confidence: Double            // Confianza en el análisis (0.0 a 1.0)
    let keyFactors: [PredictionFactor] // Factores clave identificados en noticias
    let topArticles: [NewsArticle]    // Artículos más relevantes
    
    var overallSentiment: SentimentCategory {
        if sentimentImpact >= 3.0 {
            return .veryPositive
        } else if sentimentImpact >= 0.5 {
            return .positive
        } else if sentimentImpact <= -3.0 {
            return .veryNegative
        } else if sentimentImpact <= -0.5 {
            return .negative
        } else {
            return .neutral
        }
    }
    
    enum SentimentCategory: String {
        case veryPositive = "Muy Positivo"
        case positive = "Positivo"
        case neutral = "Neutral"
        case negative = "Negativo"
        case veryNegative = "Muy Negativo"
    }
}

import Foundation

struct MacroEconomicResult {
    let econImpact: Double            // Impacto estimado en precio (-10 a +10)
    let confidence: Double            // Confianza en el análisis (0.0 a 1.0)
    let keyFactors: [PredictionFactor] // Factores macroeconómicos clave
    
    // Métricas específicas
    let sectorOutlook: SectorOutlook
    let interestRateImpact: Double
    let marketTrend: MarketTrend
    
    enum SectorOutlook: String {
        case veryBullish = "Muy Alcista"
        case bullish = "Alcista"
        case neutral = "Neutral"
        case bearish = "Bajista"
        case veryBearish = "Muy Bajista"
    }
    
    enum MarketTrend: String {
        case strongUptrend = "Tendencia Alcista Fuerte"
        case uptrend = "Tendencia Alcista"
        case sideways = "Tendencia Lateral"
        case downtrend = "Tendencia Bajista"
        case strongDowntrend = "Tendencia Bajista Fuerte"
    }
}

import Foundation
import Combine

class StockPredictionViewModel: ObservableObject {
    @Published var shortTermPredictions: [StockPrediction] = []
    @Published var longTermPredictions: [StockPrediction] = []
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    private let predictionEngine = PredictionEngine()
    private var cancellables = Set<AnyCancellable>()
    
    func loadPredictions() {
        isLoading = true
        
        predictionEngine.generatePredictions(count: 50)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.showError = true
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] predictions in
                    self?.processAndCategorize(predictions: predictions)
                }
            )
            .store(in: &cancellables)
    }
    
    private func processAndCategorize(predictions: [StockPrediction]) {
        // Separar por timeFrame
        shortTermPredictions = predictions.filter { $0.timeFrame == .shortTerm }
        longTermPredictions = predictions.filter { $0.timeFrame == .longTerm }
        
        // Ordenar por potencial de crecimiento
        shortTermPredictions.sort { $0.growthPotential > $1.growthPotential }
        longTermPredictions.sort { $0.growthPotential > $1.growthPotential }
    }
    
    func refreshPredictions() {
        loadPredictions()
    }
    
    func getPredictionsByPrice(maxPrice: Double) -> [StockPrediction] {
        return shortTermPredictions.filter { $0.currentPrice <= maxPrice } +
               longTermPredictions.filter { $0.currentPrice <= maxPrice }
    }
    
    func filterByConfidence(minConfidence: Double) -> [StockPrediction] {
        let allPredictions = shortTermPredictions + longTermPredictions
        return allPredictions.filter { $0.confidenceLevel >= minConfidence }
    }
}

import Foundation
import Combine

class StockDetailViewModel: ObservableObject {
    @Published var historicalData: [HistoricalDataPoint] = []
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var companyProfile: CompanyProfile?
    
    private let symbol: String
    private let apiManager = APIManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(symbol: String) {
        self.symbol = symbol
    }
    
    func loadData() {
        isLoading = true
        
        // Cargar datos históricos
        apiManager.fetchHistoricalData(for: symbol, period: "1y")
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showError = true
                        self?.errorMessage = "Error cargando datos históricos: \(error.localizedDescription)"
                    }
                    self?.isLoading = false
                },
                receiveValue: { [weak self] data in
                    self?.historicalData = data
                }
            )
            .store(in: &cancellables)
        
        // Cargar perfil de la empresa
        apiManager.fetchStockProfile(symbol: symbol)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Error cargando perfil: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] profile in
                    self?.companyProfile = profile
                }
            )
            .store(in: &cancellables)
    }
}

import Foundation
import Combine

class NewsViewModel: ObservableObject {
    @Published var newsArticles: [NewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var sentimentAnalysis: NewsAnalysisResult?
    
    private let symbol: String
    private let apiManager = APIManager.shared
    private let newsAnalyzer = NewsSentimentAnalyzer()
    private var cancellables = Set<AnyCancellable>()
    
    init(symbol: String) {
        self.symbol = symbol
    }
    
    func loadNews(days: Int = 7) {
        isLoading = true
        
        apiManager.fetchNewsAndSentiment(for: symbol, days: days)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    if case .failure(let error) = completion {
                        self?.showError = true
                        self?.errorMessage = "Error cargando noticias: \(error.localizedDescription)"
                    }
                    self?.isLoading = false
                },
                receiveValue: { [weak self] (news: [NewsArticle]) in
                    guard let self = self else { return }
                    self.newsArticles = news
                    self.analyzeSentiment(news: news)
                }
            )
            .store(in: &cancellables)
    }
    
    private func analyzeSentiment(news: [NewsArticle]) {
        self.sentimentAnalysis = newsAnalyzer.analyze(news: news, symbol: symbol)
    }
}

import Foundation
import Combine

class FinnhubService {
    private let apiKey: String
    private let baseURL = "https://finnhub.io/api/v1"
    private let session: URLSession
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func fetchStockList() -> AnyPublisher<[Stock], Error> {
        // Obtenemos índices principales para extraer símbolos
        let indices = ["^GSPC", "^DJI", "^IXIC"] // S&P 500, Dow Jones, NASDAQ
        let publishers = indices.map { fetchIndexComponents(index: $0) }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { componentArrays -> [String] in
                // Fusionar y eliminar duplicados
                let allComponents = componentArrays.flatMap { $0 }
                return Array(Set(allComponents))
            }
            .flatMap { symbols -> AnyPublisher<[Stock], Error> in
                // Obtener cotizaciones para cada símbolo
                let symbolPublishers = symbols.map { self.fetchStockQuote(symbol: $0) }
                return Publishers.MergeMany(symbolPublishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func fetchIndexComponents(index: String) -> AnyPublisher<[String], Error> {
        let urlString = "\(baseURL)/index/constituents?symbol=\(index)&token=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ComponentsResponse.self, decoder: JSONDecoder())
            .map { $0.constituents }
            .eraseToAnyPublisher()
    }
    
    func fetchStockQuote(symbol: String) -> AnyPublisher<Stock, Error> {
        let quoteURLString = "\(baseURL)/quote?symbol=\(symbol)&token=\(apiKey)"
        let profileURLString = "\(baseURL)/stock/profile2?symbol=\(symbol)&token=\(apiKey)"
        
        guard let quoteURL = URL(string: quoteURLString),
              let profileURL = URL(string: profileURLString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        let quotePublisher = session.dataTaskPublisher(for: quoteURL)
            .map(\.data)
            .decode(type: QuoteResponse.self, decoder: JSONDecoder())
        
        let profilePublisher = session.dataTaskPublisher(for: profileURL)
            .map(\.data)
            .decode(type: CompanyProfile.self, decoder: JSONDecoder())
        
        return Publishers.CombineLatest(quotePublisher, profilePublisher)
            .map { quote, profile -> Stock in
                return Stock(
                    symbol: symbol,
                    name: profile.name,
                    currentPrice: quote.c,
                    priceCategory: Stock.determinePriceCategory(price: quote.c),
                    sector: profile.finnhubIndustry,
                    industry: profile.finnhubIndustry,
                    country: profile.country
                )
            }
            .eraseToAnyPublisher()
    }
    
    func fetchHistoricalData(for symbol: String, period: String = "1y") -> AnyPublisher<[HistoricalDataPoint], Error> {
        // Calcular fechas según el período
        let toDate = Date()
        var fromDate: Date
        
        switch period {
        case "1w":
            fromDate = Calendar.current.date(byAdding: .day, value: -7, to: toDate)!
        case "1m":
            fromDate = Calendar.current.date(byAdding: .month, value: -1, to: toDate)!
        case "3m":
            fromDate = Calendar.current.date(byAdding: .month, value: -3, to: toDate)!
        case "6m":
            fromDate = Calendar.current.date(byAdding: .month, value: -6, to: toDate)!
        case "1y":
            fromDate = Calendar.current.date(byAdding: .year, value: -1, to: toDate)!
        default:
            fromDate = Calendar.current.date(byAdding: .year, value: -1, to: toDate)!
        }
        
        let fromTimestamp = Int(fromDate.timeIntervalSince1970)
        let toTimestamp = Int(toDate.timeIntervalSince1970)
        
        // Construir URL
        let urlString = "\(baseURL)/stock/candle?symbol=\(symbol)&resolution=W&from=\(fromTimestamp)&to=\(toTimestamp)&token=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: CandleResponse.self, decoder: JSONDecoder())
            .map { response -> [HistoricalDataPoint] in
                var dataPoints: [HistoricalDataPoint] = []
                
                for i in 0..<response.t.count {
                    // Verificar que existan todos los datos necesarios
                    guard i < response.o.count && i < response.h.count &&
                          i < response.l.count && i < response.c.count &&
                          i < response.v.count else {
                        continue
                    }
                    
                    let timestamp = response.t[i]
                    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                    
                    let dataPoint = HistoricalDataPoint(
                        date: date,
                        openPrice: response.o[i],
                        highPrice: response.h[i],
                        lowPrice: response.l[i],
                        closePrice: response.c[i],
                        volume: response.v[i]
                    )
                    dataPoints.append(dataPoint)
                }
                
                return dataPoints
            }
            .eraseToAnyPublisher()
    }
    
    func fetchCompanyProfile(symbol: String) -> AnyPublisher<CompanyProfile, Error> {
        let urlString = "\(baseURL)/stock/profile2?symbol=\(symbol)&token=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: CompanyProfile.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

// Estructuras para decodificación de respuestas
struct ComponentsResponse: Decodable {
    let constituents: [String]
    let symbol: String
}

struct QuoteResponse: Decodable {
    let c: Double  // Precio actual
    let h: Double  // Alto del día
    let l: Double  // Bajo del día
    let o: Double  // Apertura
    let pc: Double // Cierre previo
}

struct CandleResponse: Decodable {
    let c: [Double]  // Precios de cierre
    let h: [Double]  // Precios altos
    let l: [Double]  // Precios bajos
    let o: [Double]  // Precios de apertura
    let s: String    // Status
    let t: [Int]     // Timestamps
    let v: [Int]     // Volúmenes
}

import Foundation
import Combine

class AlphaVantageService {
    private let apiKey: String
    private let baseURL = "https://www.alphavantage.co/query"
    private let session: URLSession
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func fetchNews(for symbol: String, days: Int = 7) -> AnyPublisher<[NewsArticle], Error> {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        let today = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: today)!
        
        let todayStr = formatter.string(from: today)
        let startDateStr = formatter.string(from: startDate)
        
        let urlString = "\(baseURL)?function=NEWS_SENTIMENT&tickers=\(symbol)&time_from=\(startDateStr)T0000&time_to=\(todayStr)T2359&apikey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AlphaVantageNewsResponse.self, decoder: JSONDecoder())
            .map { response in
                response.feed.map { item in
                    NewsArticle(
                        id: item.id ?? Int(Date().timeIntervalSince1970),
                        title: item.title,
                        summary: item.summary,
                        url: item.url,
                        publishedDate: Self.parseDate(item.timePublished),
                        source: item.source,
                        relevance: item.relevanceScore ?? 0.5,
                        sentimentScore: item.overallSentimentScore ?? 0.0,
                        sentimentLabel: item.overallSentiment ?? "neutral"
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    private static func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddTHHmmss"
        return formatter.date(from: dateString) ?? Date()
    }
}

struct AlphaVantageNewsResponse: Decodable {
    let feed: [NewsItem]
    
    struct NewsItem: Decodable {
        let id: Int?
        let title: String
        let summary: String
        let url: String
        let timePublished: String
        let source: String
        let relevanceScore: Double?
        let overallSentimentScore: Double?
        let overallSentiment: String?
        
        enum CodingKeys: String, CodingKey {
            case title, summary, url, source
            case id = "news_id"
            case timePublished = "time_published"
            case relevanceScore = "relevance_score"
            case overallSentimentScore = "overall_sentiment_score"
            case overallSentiment = "overall_sentiment"
        }
    }
}

import Foundation

class TechnicalAnalyzer {
    func analyze(historicalData: [HistoricalDataPoint]) -> TechnicalAnalysisResult {
        // Obtener precios de cierre para los cálculos
        let closePrices = historicalData.map { $0.closePrice }
        
        // Calcular indicadores técnicos
        let sma20 = calculateSMA(prices: closePrices, period: 20).last ?? 0
        let sma50 = calculateSMA(prices: closePrices, period: 50).last ?? 0
        let ema12 = calculateEMA(prices: closePrices, period: 12).last ?? 0
        let ema26 = calculateEMA(prices: closePrices, period: 26).last ?? 0
        
        let rsi = calculateRSI(prices: closePrices, period: 14).last ?? 0
        let macd = calculateMACD(prices: closePrices)
        let stochastic = calculateStochastic(
            high: historicalData.map { $0.highPrice },
            low: historicalData.map { $0.lowPrice },
            close: closePrices,
            period: 14
        )
        
        // Interpretar señales técnicas
        let signals = interpretTechnicalSignals(
            sma20: sma20,
            sma50: sma50,
            ema12: ema12,
            ema26: ema26,
            currentPrice: closePrices.last ?? 0,
            rsi: rsi,
            macdLine: macd.macd.last ?? 0,
            macdSignal: macd.signal.last ?? 0,
            stochasticK: stochastic.k.last ?? 0,
            stochasticD: stochastic.d.last ?? 0
        )
        
        // Calcular predicción basada en indicadores
        let predictedChange = calculatePrediction(
            historicalData: historicalData,
            signals: signals,
            rsi: rsi,
            macd: macd,
            stochastic: stochastic
        )
        
        // Identificar factores clave que influyeron en la predicción
        let keyFactors = identifyKeyFactors(
            sma20: sma20,
            sma50: sma50,
            ema12: ema12,
            ema26: ema26,
            currentPrice: closePrices.last ?? 0,
            rsi: rsi,
            macdLine: macd.macd.last ?? 0,
            macdSignal: macd.signal.last ?? 0,
            signals: signals
        )
        
        // Evaluar la confianza de la predicción
        let confidence = evaluateConfidence(signals: signals)
        
        return TechnicalAnalysisResult(
            predictedChangePercent: predictedChange,
            confidence: confidence,
            signals: signals,
            keyFactors: keyFactors,
            movingAverages: TechnicalAnalysisResult.MovingAverages(
                sma20: sma20,
                sma50: sma50,
                ema12: ema12,
                ema26: ema26
            ),
            oscillators: TechnicalAnalysisResult.Oscillators(
                rsi: rsi,
                macdLine: macd.macd.last ?? 0,
                macdSignal: macd.signal.last ?? 0,
                stochasticK: stochastic.k.last ?? 0,
                stochasticD: stochastic.d.last ?? 0
            )
        )
    }
    
    // Métodos para calcular indicadores técnicos
    private func calculateSMA(prices: [Double], period: Int) -> [Double] {
        guard period > 0, !prices.isEmpty, prices.count >= period else {
            return []
        }
        
        var result = [Double]()
        
        for i in period-1..<prices.count {
            let sum = prices[(i-period+1)...i].reduce(0, +)
            let average = sum / Double(period)
            result.append(average)
        }
        
        return result
    }
    
    private func calculateEMA(prices: [Double], period: Int) -> [Double] {
        guard period > 0, !prices.isEmpty, prices.count >= period else {
            return []
        }
        
        let multiplier = 2.0 / Double(period + 1)
        
        // Inicializar con SMA
        let sma = calculateSMA(prices: Array(prices.prefix(period)), period: period)[0]
        
        var result = [sma]
        
        for i in period..<prices.count {
            let ema = (prices[i] - result.last!) * multiplier + result.last!
            result.append(ema)
        }
        
        return result
    }
    
    private func calculateRSI(prices: [Double], period: Int = 14) -> [Double] {
        guard prices.count > period else {
            return []
        }
        
        var gains = [Double]()
        var losses = [Double]()
        
        // Calcular ganancias y pérdidas para cada período
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            gains.append(max(0, change))
            losses.append(max(0, -change))
        }
        
        var result = [Double]()
        
        // Inicializar con promedios iniciales
        var avgGain = gains.prefix(period).reduce(0, +) / Double(period)
        var avgLoss = losses.prefix(period).reduce(0, +) / Double(period)
        
        // Primer RSI
        var rs = avgGain / max(avgLoss, 0.001) // Evitar división por cero
        var rsi = 100 - (100 / (1 + rs))
        result.append(rsi)
        
        // Calcular RSI para el resto de datos
        for i in period..<gains.count {
            avgGain = (avgGain * Double(period - 1) + gains[i]) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + losses[i]) / Double(period)
            
            rs = avgGain / max(avgLoss, 0.001)
            rsi = 100 - (100 / (1 + rs))
            result.append(rsi)
        }
        
        return result
    }
    
    private func calculateMACD(prices: [Double]) -> (macd: [Double], signal: [Double], histogram: [Double]) {
        let ema12 = calculateEMA(prices: prices, period: 12)
        let ema26 = calculateEMA(prices: prices, period: 26)
        
        // Alinear los arrays para asegurar que tengan la misma longitud
        let diff = ema26.count - ema12.count
        let alignedEMA12 = diff > 0 ? ema12 : Array(ema12.suffix(ema26.count))
        let alignedEMA26 = diff > 0 ? ema26 : Array(ema26.suffix(ema12.count))
        
        // Calcular la línea MACD
        var macdLine = [Double]()
        for i in 0..<min(alignedEMA12.count, alignedEMA26.count) {
            macdLine.append(alignedEMA12[i] - alignedEMA26[i])
        }
        
        // Calcular la señal (EMA de 9 períodos de la línea MACD)
        let signal = calculateEMA(prices: macdLine, period: 9)
        
        // Calcular el histograma (MACD - Signal)
        var histogram = [Double]()
        for i in 0..<min(macdLine.count, signal.count) {
            histogram.append(macdLine[i] - signal[i])
        }
        
        return (macdLine, signal, histogram)
    }
    
    private func calculateStochastic(high: [Double], low: [Double], close: [Double], period: Int) -> (k: [Double], d: [Double]) {
        guard high.count == low.count, high.count == close.count, high.count >= period else {
            return ([], [])
        }
        
        var kValues = [Double]()
        
        // Calcular %K
        for i in period-1..<close.count {
            let highestHigh = high[(i-period+1)...i].max() ?? 0
            let lowestLow = low[(i-period+1)...i].min() ?? 0
            let range = highestHigh - lowestLow
            
            let k = range > 0 ? ((close[i] - lowestLow) / range) * 100 : 50
            kValues.append(k)
        }
        
        // Calcular %D (SMA de 3 períodos de %K)
        let dValues = calculateSMA(prices: kValues, period: 3)
        
        return (kValues, dValues)
    }
    
    // Interpretación de señales técnicas
    private func interpretTechnicalSignals(
        sma20: Double,
        sma50: Double,
        ema12: Double,
        ema26: Double,
        currentPrice: Double,
        rsi: Double,
        macdLine: Double,
        macdSignal: Double,
        stochasticK: Double,
        stochasticD: Double
    ) -> [TechnicalSignal] {
        var signals = [TechnicalSignal]()
        
        // Señales de medias móviles
        if currentPrice > sma20 && sma20 > sma50 {
            signals.append(.buy)
        } else if currentPrice < sma20 && sma20 < sma50 {
            signals.append(.sell)
        }
        
        // Señales de MACD
        if macdLine > macdSignal && macdLine > 0 {
            signals.append(.buy)
        } else if macdLine < macdSignal && macdLine < 0 {
            signals.append(.sell)
        }
        
        // Señales de RSI
        if rsi > 70 {
            signals.append(.sell)
        } else if rsi < 30 {
            signals.append(.buy)
        }
        
        // Señales de Estocástico
        if stochasticK > 80 && stochasticD > 80 {
            signals.append(.sell)
        } else if stochasticK < 20 && stochasticD < 20 {
            signals.append(.buy)
        }
        
        // Determinar señal consolidada
        let buySignals = signals.filter { $0 == .buy }.count
        let sellSignals = signals.filter { $0 == .sell }.count
        
        if buySignals >= 3 {
            return [.strongBuy]
        } else if buySignals >= 2 {
            return [.buy]
        } else if sellSignals >= 3 {
            return [.strongSell]
        } else if sellSignals >= 2 {
            return [.sell]
        } else {
            return [.neutral]
        }
    }
    
    // Cálculo de predicción basada en indicadores
    private func calculatePrediction(
        historicalData: [HistoricalDataPoint],
        signals: [TechnicalSignal],
        rsi: Double,
        macd: (macd: [Double], signal: [Double], histogram: [Double]),
        stochastic: (k: [Double], d: [Double])
    ) -> Double {
        // Extraer último precio
        guard let latestPrice = historicalData.last?.closePrice,
              historicalData.count > 20 else {
            return 0.0
        }
        
        // Obtener tendencia reciente (últimas 4 semanas)
        let recentPrices = historicalData.suffix(4).map { $0.closePrice }
        let linearTrend = calculateLinearTrend(prices: recentPrices)
        
        // Calcular predicción base como continuación de tendencia
        var predictedChangePercent = linearTrend * 4 // Proyectar 4 semanas adelante
        
        // Ajustar basado en señales técnicas
        switch signals.first {
        case .strongBuy:
            predictedChangePercent += 5.0
        case .buy:
            predictedChangePercent += 2.5
        case .neutral:
            // Mantener la tendencia base
            break
        case .sell:
            predictedChangePercent -= 2.5
        case .strongSell:
            predictedChangePercent -= 5.0
        case .none:
            break
        }
        
        // Ajustar por RSI (sobrecompra/sobreventa)
        if rsi > 75 {
            predictedChangePercent -= 1.5 // Probable corrección a la baja
        } else if rsi < 25 {
            predictedChangePercent += 1.5 // Probable rebote al alza
        }
        
        // Ajustar por volatilidad histórica
        let volatility = calculateVolatility(historicalData: historicalData)
        predictedChangePercent *= (1 + volatility/100) // Mayor volatilidad = mayor movimiento potencial
        
        // Limitar a rangos razonables
        return max(-20.0, min(20.0, predictedChangePercent))
    }
    
    // Identificación de factores clave
    private func identifyKeyFactors(
        sma20: Double,
        sma50: Double,
        ema12: Double,
        ema26: Double,
        currentPrice: Double,
        rsi: Double,
        macdLine: Double,
        macdSignal: Double,
        signals: [TechnicalSignal]
    ) -> [PredictionFactor] {
        var factors = [PredictionFactor]()
        
        // Factor de medias móviles
        if currentPrice > sma20 && sma20 > sma50 {
            factors.append(PredictionFactor(
                name: "Tendencia Alcista",
                impact: 3.5,
                description: "Precio por encima de SMA20 y SMA50, confirmando tendencia alcista"
            ))
        } else if currentPrice < sma20 && sma20 < sma50 {
            factors.append(PredictionFactor(
                name: "Tendencia Bajista",
                impact: -3.5,
                description: "Precio por debajo de SMA20 y SMA50, confirmando tendencia bajista"
            ))
        }
        
        // Factor de MACD
        if macdLine > macdSignal && macdLine > 0 {
            factors.append(PredictionFactor(
                name: "Cruce MACD Alcista",
                impact: 2.8,
                description: "MACD por encima de línea de señal, indicando impulso alcista"
            ))
        } else if macdLine < macdSignal && macdLine < 0 {
            factors.append(PredictionFactor(
                name: "Cruce MACD Bajista",
                impact: -2.8,
                description: "MACD por debajo de línea de señal, indicando impulso bajista"
            ))
        }
        
        // Factor de RSI
        if rsi > 70 {
            factors.append(PredictionFactor(
                name: "Sobrecompra RSI",
                impact: -2.5,
                description: "RSI por encima de 70, indicando condición de sobrecompra"
            ))
        } else if rsi < 30 {
            factors.append(PredictionFactor(
                name: "Sobreventa RSI",
                impact: 2.5,
                description: "RSI por debajo de 30, indicando condición de sobreventa"
            ))
        }
        
        // Factor de señal principal
        if let signal = signals.first {
            let impact: Double
            let description: String
            
            switch signal {
            case .strongBuy:
                impact = 5.0
                description = "Múltiples indicadores muestran señales de compra fuerte"
            case .buy:
                impact = 2.5
                description = "Indicadores técnicos inclinados hacia señal de compra"
            case .neutral:
                impact = 0.0
                description = "Indicadores técnicos muestran señal neutral"
            case .sell:
                impact = -2.5
                description = "Indicadores técnicos inclinados hacia señal de venta"
            case .strongSell:
                impact = -5.0
                description = "Múltiples indicadores muestran señales de venta fuerte"
            }
            
            factors.append(PredictionFactor(
                name: "Señal \(signal.rawValue)",
                impact: impact,
                description: description
            ))
        }
        
        return factors
    }
    
    // Evaluación de confianza
    private func evaluateConfidence(signals: [TechnicalSignal]) -> Double {
        // La confianza es mayor cuando hay señales fuertes
        if signals.contains(.strongBuy) || signals.contains(.strongSell) {
            return 0.85
        } else if signals.contains(.buy) || signals.contains(.sell) {
            return 0.70
        } else {
            return 0.50
        }
    }
    
    // Funciones auxiliares
    
    private func calculateLinearTrend(prices: [Double]) -> Double {
        guard prices.count > 1 else { return 0.0 }
        
        // Calcular pendiente de la recta de tendencia
        let n = Double(prices.count)
        let indices = Array(0..<prices.count).map { Double($0) }
        
        let sumX = indices.reduce(0, +)
        let sumY = prices.reduce(0, +)
        let sumXY = zip(indices, prices).map { $0 * $1 }.reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        
        // Convertir pendiente a porcentaje de cambio por período
        let avgPrice = sumY / n
        return (slope / avgPrice) * 100
    }
    
    private func calculateVolatility(historicalData: [HistoricalDataPoint]) -> Double {
        let closePrices = historicalData.map { $0.closePrice }
        
        // Calcular rendimientos diarios
        var returns = [Double]()
        for i in 1..<closePrices.count {
            let dailyReturn = (closePrices[i] / closePrices[i-1]) - 1
            returns.append(dailyReturn)
        }
        
        // Calcular desviación estándar de rendimientos
        let mean = returns.reduce(0, +) / Double(returns.count)
        let squaredDifferences = returns.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(returns.count)
        
        return sqrt(variance) * 100 // Volatilidad como porcentaje
    }
}

import Foundation
import NaturalLanguage

class NewsSentimentAnalyzer {
    private var sentimentModel: NLModel?
    
    init() {
        setupSentimentModel()
    }
    
    private func setupSentimentModel() {
        // En una implementación real, aquí cargaríamos un modelo CoreML pre-entrenado
        // Para esta implementación, usaremos un análisis de palabras clave
    }
    
    func analyze(news: [NewsArticle], symbol: String) -> NewsAnalysisResult {
        // Ordenar noticias por relevancia y fecha
        let relevantNews = news
            .filter { $0.relevance > 0.3 }
            .sorted { ($0.relevance, $0.publishedDate) > ($1.relevance, $1.publishedDate) }
        
        // Si no hay noticias, devolver resultado neutral
        if relevantNews.isEmpty {
            return createNeutralResult(news: news)
        }
        
        // Procesar cada noticia para extraer sentimiento
        let processedNews = processNewsArticles(relevantNews)
        
        // Calcular impacto ponderado global
        var weightedScoreSum = 0.0
        var weightsSum = 0.0
        
        for article in processedNews {
            let weight = article.article.relevance
            weightedScoreSum += article.sentimentScore * weight
            weightsSum += weight
        }
        
        let averageSentiment = weightsSum > 0 ? weightedScoreSum / weightsSum : 0
        
        // Convertir el sentimiento a impacto de predicción (-10 a +10)
        let sentimentImpact = averageSentiment * 10
        
        // Evaluar confianza basada en la consistencia del sentimiento
        let confidence = evaluateConfidence(processedNews: processedNews)
        
        // Identificar factores clave basados en temas recurrentes
        let keyFactors = identifyKeyFactors(processedNews: processedNews, symbol: symbol)
        
        return NewsAnalysisResult(
            sentimentImpact: sentimentImpact,
            confidence: confidence,
            keyFactors: keyFactors,
            topArticles: relevantNews.prefix(5).map { $0 }
        )
    }
    
    private func processNewsArticles(_ news: [NewsArticle]) -> [ProcessedNewsArticle] {
        return news.map { article in
            // Usar el sentimiento pre-calculado de Alpha Vantage si está disponible
            let score = article.sentimentScore
            
            return ProcessedNewsArticle(
                article: article,
                sentimentScore: score,
                keyTopics: extractKeyTopics(from: article),
                impactEstimate: estimateImpact(article: article, score: score)
            )
        }
    }
    
    private func extractKeyTopics(from article: NewsArticle) -> [String: Double] {
        let keywords = [
            "earnings": 0.9,
            "revenue": 0.8,
            "growth": 0.7,
            "profit": 0.8,
            "loss": 0.8,
            "layoffs": 0.7,
            "acquisition": 0.9,
            "merger": 0.9,
            "partnership": 0.8,
            "lawsuit": 0.8,
            "regulation": 0.7,
            "product": 0.6,
            "launch": 0.7,
            "upgrade": 0.6,
            "downgrade": 0.6,
            "report": 0.5,
            "dividend": 0.7,
            "economy": 0.5,
            "market": 0.4,
            "stock": 0.4
        ]
        
        var foundTopics = [String: Double]()
        let content = "\(article.title) \(article.summary)".lowercased()
        
        for (keyword, relevance) in keywords {
            if content.contains(keyword) {
                foundTopics[keyword] = relevance
            }
        }
        
        return foundTopics
    }
    
    private func estimateImpact(article: NewsArticle, score: Double) -> Double {
        // Convertir el score de sentimiento (-1 a 1) a un impacto potencial (-5 a 5)
        let baseImpact = score * 5
        
        // Ajustar por relevancia
        let relevanceMultiplier = 0.5 + (article.relevance * 0.5) // 0.5 a 1.0
        
        // Ajustar por tiempo (noticias más recientes tienen más impacto)
        let daysAgo = Calendar.current.dateComponents([.day], from: article.publishedDate, to: Date()).day ?? 0
        let timeDecay = max(0.5, 1.0 - (Double(daysAgo) * 0.1)) // 1.0 a 0.5
        
        return baseImpact * relevanceMultiplier * timeDecay
    }
    
    private func evaluateConfidence(processedNews: [ProcessedNewsArticle]) -> Double {
        // Si hay pocas noticias, la confianza es menor
        if processedNews.count < 3 {
            return 0.5
        }
        
        // Calcular la varianza del sentimiento (mayor varianza = menor confianza)
        let sentiments = processedNews.map { $0.sentimentScore }
        let mean = sentiments.reduce(0, +) / Double(sentiments.count)
        let squaredDiffs = sentiments.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(squaredDiffs.count)
        
        // Invertir la varianza para obtener confianza (mayor varianza = menor confianza)
        let varianceConfidence = max(0.3, 1.0 - (variance * 2))
        
        // Ajustar por cantidad y relevancia promedio
        let relevanceAvg = processedNews.map { $0.article.relevance }.reduce(0, +) / Double(processedNews.count)
        let countFactor = min(1.0, Double(processedNews.count) / 10.0) // Máximo con 10+ noticias
        
        return (varianceConfidence * 0.5) + (relevanceAvg * 0.3) + (countFactor * 0.2)
    }
    
    private func identifyKeyFactors(processedNews: [ProcessedNewsArticle], symbol: String) -> [PredictionFactor] {
        var topicCount = [String: (count: Int, totalImpact: Double, sentiment: Double)]()
        
        // Contar ocurrencias e impacto por tema
        for article in processedNews {
            for (topic, relevance) in article.keyTopics {
                let currentValue = topicCount[topic] ?? (0, 0.0, 0.0)
                topicCount[topic] = (
                    currentValue.count + 1,
                    currentValue.totalImpact + (article.impactEstimate * relevance),
                    currentValue.sentiment + article.sentimentScore
                )
            }
        }
        
        // Convertir a factores
        let factors = topicCount.compactMap { (topic, data) -> PredictionFactor? in
            // Solo incluir temas que aparecen en múltiples noticias
            guard data.count >= 2 else { return nil }
            
            let avgImpact = data.totalImpact / Double(data.count)
            let avgSentiment = data.sentiment / Double(data.count)
            
            // Crear descripción basada en sentimiento
            let sentimentDesc = avgSentiment > 0.3 ? "positivo" :
                                avgSentiment < -0.3 ? "negativo" : "mixto"
            
            return PredictionFactor(
                name: "Noticias: \(topic.capitalized)",
                impact: avgImpact,
                description: "Sentimiento \(sentimentDesc) en noticias sobre \(topic) relacionadas con \(symbol)"
            )
        }
        
        // Ordenar por impacto absoluto (positivo o negativo)
        return factors.sorted { abs($0.impact) > abs($1.impact) }
    }
    
    private func createNeutralResult(news: [NewsArticle]) -> NewsAnalysisResult {
        return NewsAnalysisResult(
            sentimentImpact: 0.0,
            confidence: 0.3,
            keyFactors: [
                PredictionFactor(
                    name: "Pocas noticias relevantes",
                    impact: 0.0,
                    description: "No hay suficientes noticias recientes para determinar un impacto claro"
                )
            ],
            topArticles: news.prefix(3).map { $0 }
        )
    }
}

struct ProcessedNewsArticle {
    let article: NewsArticle
    let sentimentScore: Double
    let keyTopics: [String: Double]
    let impactEstimate: Double
}

import Foundation

class MacroEconomicAnalyzer {
    // Datos simulados de indicadores macroeconómicos para 2025
    private let interestRate = 3.75
    private let inflationRate = 2.8
    private let unemploymentRate = 4.1
    private let gdpGrowth = 2.3
    private let consumerSentiment = 83.6
    private let manufacturingIndex = 54.2
    private let retailSales = 3.1  // Crecimiento porcentual anual
    
    // Tendencias de sectores (simuladas)
    private let sectorTrends: [String: MacroEconomicResult.SectorOutlook] = [
        "Technology": .bullish,
        "Healthcare": .bullish,
        "Financial Services": .neutral,
        "Consumer Cyclical": .neutral,
        "Energy": .bearish,
        "Real Estate": .bearish,
        "Utilities": .neutral,
        "Communication Services": .bullish,
        "Consumer Defensive": .neutral,
        "Basic Materials": .bearish,
        "Industrials": .neutral
    ]
    
    // Sensibilidad a tasas de interés por sector
    private let interestRateSensitivity: [String: Double] = [
        "Technology": 0.7,
        "Healthcare": 0.4,
        "Financial Services": 1.2,
        "Consumer Cyclical": 0.8,
        "Energy": 0.5,
        "Real Estate": 1.5,
        "Utilities": 1.3,
        "Communication Services": 0.6,
        "Consumer Defensive": 0.3,
        "Basic Materials": 0.6,
        "Industrials": 0.7
    ]
    
    // Sensibilidad a inflación por sector
    private let inflationSensitivity: [String: Double] = [
        "Technology": 0.5,
        "Healthcare": 0.4,
        "Financial Services": 0.8,
        "Consumer Cyclical": 1.1,
        "Energy": 1.3,
        "Real Estate": 1.0,
        "Utilities": 0.7,
        "Communication Services": 0.5,
        "Consumer Defensive": 0.9,
        "Basic Materials": 1.2,
        "Industrials": 0.9
    ]
    
    func analyze(symbol: String, profile: CompanyProfile) -> MacroEconomicResult {
        // Identificar sector
        let sector = profile.finnhubIndustry
        
        // Obtener outlook del sector
        let sectorOutlook = sectorTrends[sector] ?? .neutral
        
        // Calcular impacto de tasas de interés según el sector
        let interestRateImpact = calculateInterestRateImpact(sector: sector, interestRate: interestRate)
        
        // Determinar tendencia general del mercado
        let marketTrend = determineMarketTrend()
        
        // Calcular impacto por inflación
        let inflationImpact = calculateInflationImpact(sector: sector, inflationRate: inflationRate)
        
        // Calcular impacto por crecimiento económico
        let growthImpact = calculateGrowthImpact(sector: sector, gdpGrowth: gdpGrowth)
        
        // Calcular impacto por sentimiento del consumidor
        let sentimentImpact = calculateConsumerSentimentImpact(sector: sector, sentiment: consumerSentiment)
        
        // Calcular impacto económico general (combinación de todos los factores)
        let econImpact = calculateEconomicImpact(
            sectorOutlook: sectorOutlook,
            interestRateImpact: interestRateImpact,
            inflationImpact: inflationImpact,
            growthImpact: growthImpact,
            sentimentImpact: sentimentImpact,
            marketTrend: marketTrend,
            sector: sector
        )
        
        // Identificar factores clave
        let keyFactors = identifyKeyFactors(
            sectorOutlook: sectorOutlook,
            interestRateImpact: interestRateImpact,
            inflationImpact: inflationImpact,
            growthImpact: growthImpact,
            sentimentImpact: sentimentImpact,
            marketTrend: marketTrend,
            sector: sector,
            symbol: symbol
        )
        
        // Evaluar confianza basada en la calidad y especificidad de los datos
        let confidence = evaluateConfidence(sector: sector)
        
        return MacroEconomicResult(
            econImpact: econImpact,
            confidence: confidence,
            keyFactors: keyFactors,
            sectorOutlook: sectorOutlook,
            interestRateImpact: interestRateImpact,
            marketTrend: marketTrend
        )
    }
    
    private func calculateInterestRateImpact(sector: String, interestRate: Double) -> Double {
        // Sensibilidad base del sector a las tasas de interés (mayor valor = más sensible)
        let sensitivity = interestRateSensitivity[sector] ?? 0.7
        
        // Calcular impacto basado en tasas actuales y sensibilidad
        // Tasas más altas generalmente tienen impacto negativo (con algunas excepciones)
        let baseImpact: Double
        
        if sector == "Financial Services" {
            // Financieras pueden beneficiarse de mayores tasas (hasta cierto punto)
            baseImpact = interestRate > 5.0 ? -1.0 : (interestRate > 2.0 ? 1.5 : 0.5)
        } else {
            // Para otros sectores, tasas más altas son generalmente negativas
            baseImpact = interestRate > 5.0 ? -3.0 : (interestRate > 4.0 ? -2.0 : (interestRate > 3.0 ? -1.0 : 0.0))
        }
        
        // Aplicar sensibilidad específica del sector
        return baseImpact * sensitivity
    }
    
    private func calculateInflationImpact(sector: String, inflationRate: Double) -> Double {
        // Sensibilidad base del sector a la inflación
        let sensitivity = inflationSensitivity[sector] ?? 0.8
        
        // Calcular impacto basado en inflación actual
        let baseImpact: Double
        
        if sector == "Energy" || sector == "Basic Materials" {
            // Estos sectores pueden beneficiarse de mayor inflación (commodities)
            baseImpact = inflationRate > 4.0 ? 2.0 : (inflationRate > 2.5 ? 1.0 : 0.0)
        } else if sector == "Consumer Defensive" {
            // Bienes básicos tienen menor sensibilidad a inflación
            baseImpact = inflationRate > 4.0 ? -1.0 : (inflationRate > 2.5 ? -0.5 : 0.0)
        } else {
            // Para otros sectores, mayor inflación es negativa
            baseImpact = inflationRate > 4.0 ? -2.5 : (inflationRate > 2.5 ? -1.5 : 0.0)
        }
        
        return baseImpact * sensitivity
    }
    
    private func calculateGrowthImpact(sector: String, gdpGrowth: Double) -> Double {
        // Diferentes sectores responden diferente al crecimiento económico
        let baseImpact: Double
        
        if sector == "Consumer Cyclical" || sector == "Industrials" {
            // Sectores cíclicos son muy sensibles al crecimiento económico
            baseImpact = gdpGrowth > 3.0 ? 3.5 : (gdpGrowth > 2.0 ? 2.0 : (gdpGrowth > 1.0 ? 0.5 : -2.0))
        } else if sector == "Consumer Defensive" || sector == "Healthcare" {
            // Sectores defensivos son menos sensibles al crecimiento
            baseImpact = gdpGrowth > 3.0 ? 1.0 : (gdpGrowth > 2.0 ? 0.5 : (gdpGrowth > 0.0 ? 0.0 : -1.0))
        } else if sector == "Technology" {
            // Tecnología responde bien al crecimiento y puede crecer aún en economías estancadas
            baseImpact = gdpGrowth > 2.0 ? 3.0 : (gdpGrowth > 1.0 ? 1.5 : 0.0)
        } else {
            // Otros sectores
            baseImpact = gdpGrowth > 2.5 ? 2.0 : (gdpGrowth > 1.5 ? 1.0 : (gdpGrowth > 0.5 ? 0.0 : -1.5))
        }
        
        return baseImpact
    }
    
    private func calculateConsumerSentimentImpact(sector: String, sentiment: Double) -> Double {
        // Impacto basado en sentimiento del consumidor y sector
        let baseImpact: Double
        
        // Sentimiento alto (>85) es bueno, bajo (<70) es malo, 70-85 es neutral
        if sector == "Consumer Cyclical" || sector == "Retail" {
            // Sectores de consumo discreto son muy sensibles al sentimiento
            baseImpact = sentiment > 85.0 ? 2.5 : (sentiment > 75.0 ? 1.0 : (sentiment > 70.0 ? 0.0 : -2.0))
        } else if sector == "Technology" || sector == "Communication Services" {
            // Tecnología y comunicaciones son moderadamente sensibles
            baseImpact = sentiment > 85.0 ? 1.5 : (sentiment > 75.0 ? 0.8 : (sentiment > 70.0 ? 0.0 : -1.0))
        } else if sector == "Consumer Defensive" || sector == "Healthcare" {
            // Sectores defensivos pueden incluso beneficiarse de sentimiento bajo
            baseImpact = sentiment > 85.0 ? 0.5 : (sentiment > 70.0 ? 0.0 : 0.5)
        } else {
            // Otros sectores
            baseImpact = sentiment > 85.0 ? 1.0 : (sentiment > 75.0 ? 0.5 : (sentiment > 70.0 ? 0.0 : -0.5))
        }
        
        return baseImpact
    }
    
    private func determineMarketTrend() -> MacroEconomicResult.MarketTrend {
        // Simulación de tendencia de mercado basada en factores combinados
        let combinedFactor = (gdpGrowth - inflationRate) +
                            (interestRate < 4.0 ? 1.0 : -1.0) +
                            (consumerSentiment > 80.0 ? 1.0 : -0.5)
        
        if combinedFactor > 2.5 {
            return .strongUptrend
        } else if combinedFactor > 1.0 {
            return .uptrend
        } else if combinedFactor > -0.5 {
            return .sideways
        } else if combinedFactor > -2.0 {
            return .downtrend
        } else {
            return .strongDowntrend
        }
    }
    
    private func calculateEconomicImpact(
        sectorOutlook: MacroEconomicResult.SectorOutlook,
        interestRateImpact: Double,
        inflationImpact: Double,
        growthImpact: Double,
        sentimentImpact: Double,
        marketTrend: MacroEconomicResult.MarketTrend,
        sector: String
    ) -> Double {
        var impact = 0.0
        
        // Ponderación por importancia de factores (total = 1.0)
        let sectorWeight = 0.30       // Tendencia del sector
        let interestRateWeight = 0.20 // Impacto de tasas de interés
        let inflationWeight = 0.15    // Impacto de inflación
        let growthWeight = 0.20       // Impacto de crecimiento económico
        let sentimentWeight = 0.10    // Impacto de sentimiento del consumidor
        let marketTrendWeight = 0.05  // Tendencia general del mercado
        
        // Impacto por outlook sectorial
        switch sectorOutlook {
        case .veryBullish: impact += 4.0 * sectorWeight
        case .bullish: impact += 2.0 * sectorWeight
        case .neutral: impact += 0.0 * sectorWeight
        case .bearish: impact -= 2.0 * sectorWeight
        case .veryBearish: impact -= 4.0 * sectorWeight
        }
        
        // Impacto por tasas de interés
        impact += interestRateImpact * interestRateWeight
        
        // Impacto por inflación
        impact += inflationImpact * inflationWeight
        
        // Impacto por crecimiento económico
        impact += growthImpact * growthWeight
        
        // Impacto por sentimiento del consumidor
        impact += sentimentImpact * sentimentWeight
        
        // Impacto por tendencia general del mercado
        switch marketTrend {
        case .strongUptrend: impact += 2.0 * marketTrendWeight
        case .uptrend: impact += 1.0 * marketTrendWeight
        case .sideways: impact += 0.0 * marketTrendWeight
        case .downtrend: impact -= 1.0 * marketTrendWeight
        case .strongDowntrend: impact -= 2.0 * marketTrendWeight
        }
        
        // Escalar el impacto total al rango esperado (-10 a 10)
        impact = impact * 10
        
        // Limitar el rango
        return max(-10.0, min(10.0, impact))
    }
    
    private func identifyKeyFactors(
        sectorOutlook: MacroEconomicResult.SectorOutlook,
        interestRateImpact: Double,
        inflationImpact: Double,
        growthImpact: Double,
        sentimentImpact: Double,
        marketTrend: MacroEconomicResult.MarketTrend,
        sector: String,
        symbol: String
    ) -> [PredictionFactor] {
        var factors = [PredictionFactor]()
        
        // Factor de tendencia sectorial
        let sectorImpact: Double
        let sectorDescription: String
        
        switch sectorOutlook {
        case .veryBullish:
            sectorImpact = 4.0
            sectorDescription = "Sector \(sector) con perspectivas muy alcistas"
        case .bullish:
            sectorImpact = 2.0
            sectorDescription = "Sector \(sector) con perspectivas alcistas"
        case .neutral:
            sectorImpact = 0.0
            sectorDescription = "Sector \(sector) con perspectivas neutrales"
        case .bearish:
            sectorImpact = -2.0
            sectorDescription = "Sector \(sector) con perspectivas bajistas"
        case .veryBearish:
            sectorImpact = -4.0
            sectorDescription = "Sector \(sector) con perspectivas muy bajistas"
        }
        
        factors.append(PredictionFactor(
            name: "Tendencia Sectorial",
            impact: sectorImpact,
            description: sectorDescription
        ))
        
        // Factor de tasas de interés (si es significativo)
        if abs(interestRateImpact) >= 1.0 {
            let direction = interestRateImpact > 0 ? "positivo" : "negativo"
            factors.append(PredictionFactor(
                name: "Impacto de Tasas de Interés",
                impact: interestRateImpact,
                description: "Tasa de interés actual (\(interestRate)%) tiene impacto \(direction) en \(sector)"
            ))
        }
        
        // Factor de inflación (si es significativo)
        if abs(inflationImpact) >= 1.0 {
            let direction = inflationImpact > 0 ? "positivo" : "negativo"
            factors.append(PredictionFactor(
                name: "Impacto de Inflación",
                impact: inflationImpact,
                description: "Tasa de inflación actual (\(inflationRate)%) tiene impacto \(direction) en \(sector)"
            ))
        }
        
        // Factor de crecimiento económico (si es significativo)
        if abs(growthImpact) >= 1.0 {
            let direction = growthImpact > 0 ? "positivo" : "negativo"
            factors.append(PredictionFactor(
                name: "Crecimiento Económico",
                impact: growthImpact,
                description: "Crecimiento del PIB (\(gdpGrowth)%) tiene impacto \(direction) en \(sector)"
            ))
        }
        
        // Factor de sentimiento del consumidor (si es significativo)
        if abs(sentimentImpact) >= 1.0 {
            let direction = sentimentImpact > 0 ? "positivo" : "negativo"
            factors.append(PredictionFactor(
                name: "Sentimiento del Consumidor",
                impact: sentimentImpact,
                description: "Índice de sentimiento (\(consumerSentiment)) tiene impacto \(direction) en \(sector)"
            ))
        }
        
        // Factor de tendencia general del mercado
        let marketTrendImpact: Double
        let marketTrendDescription: String
        
        switch marketTrend {
        case .strongUptrend:
            marketTrendImpact = 2.0
            marketTrendDescription = "Mercado general en tendencia alcista fuerte"
        case .uptrend:
            marketTrendImpact = 1.0
            marketTrendDescription = "Mercado general en tendencia alcista"
        case .sideways:
            marketTrendImpact = 0.0
            marketTrendDescription = "Mercado general en tendencia lateral"
        case .downtrend:
            marketTrendImpact = -1.0
            marketTrendDescription = "Mercado general en tendencia bajista"
        case .strongDowntrend:
            marketTrendImpact = -2.0
            marketTrendDescription = "Mercado general en tendencia bajista fuerte"
        }
        
        factors.append(PredictionFactor(
            name: "Tendencia de Mercado",
            impact: marketTrendImpact,
            description: marketTrendDescription
        ))
        
        // Ordenar factores por impacto absoluto (para mostrar los más relevantes primero)
        return factors.sorted { abs($0.impact) > abs($1.impact) }
    }
    
    private func evaluateConfidence(sector: String) -> Double {
        // La confianza es mayor para sectores con datos más completos y relaciones más establecidas
        let sectorConfidenceMap: [String: Double] = [
            "Technology": 0.85,
            "Financial Services": 0.85,
            "Healthcare": 0.80,
            "Consumer Cyclical": 0.80,
            "Energy": 0.75,
            "Real Estate": 0.75,
            "Utilities": 0.80,
            "Communication Services": 0.75,
            "Consumer Defensive": 0.75,
            "Basic Materials": 0.70,
            "Industrials": 0.75
        ]
        
        // Base de confianza por sector
        let sectorConfidence = sectorConfidenceMap[sector] ?? 0.70
        
        // Ajustar confianza basada en calidad de datos macroeconómicos
        // Para una implementación real, esto evaluaría la frescura y fiabilidad de los datos
        let dataQualityAdjustment = 0.05
        
        // La confianza final
        return sectorConfidence + dataQualityAdjustment
    }
    
    // Datos para escenarios específicos de sectores (para análisis más detallados)
    private func getSectorSpecificScenarios(sector: String) -> [String: Double] {
        switch sector {
        case "Technology":
            return [
                "disruption_risk": 0.4,
                "innovation_potential": 0.8,
                "regulation_impact": -0.3
            ]
        case "Financial Services":
            return [
                "regulation_impact": -0.5,
                "interest_rate_sensitivity": 0.7,
                "market_volatility_benefit": 0.3
            ]
        case "Healthcare":
            return [
                "aging_population_impact": 0.6,
                "regulation_risk": -0.4,
                "innovation_potential": 0.7
            ]
        default:
            return [
                "general_economic_sensitivity": 0.5
            ]
        }
    }
}

import Foundation
import Combine

class APIManager {
    // Singleton para el acceso global
    static let shared = APIManager()
    
    // Servicios individuales de APIs
    private let finnhubService: FinnhubService
    private let alphaVantageService: AlphaVantageService
    
    // Contadores para gestionar límites de solicitud
    private var finnhubRequestCount = 0
    private var alphaVantageRequestCount = 0
    private var lastFinnhubRequestMinute = 0
    private var lastAlphaVantageRequestDay = 0
    
    // Cache para minimizar solicitudes repetidas
    private var stockDataCache: [String: StockData] = [:]
    private var newsCache: [String: (timestamp: Date, news: [NewsArticle])] = [:]
    
    private init() {
        self.finnhubService = FinnhubService(apiKey: APIConfig.Finnhub.apiKey)
        self.alphaVantageService = AlphaVantageService(apiKey: APIConfig.AlphaVantage.apiKey)
        
        // Resetear contadores basado en el calendario
        setupRequestCounters()
    }
    
    // Métodos para acceder a datos de mercado (usando Finnhub primariamente)
    func fetchStockList() -> AnyPublisher<[Stock], Error> {
        if !canMakeFinnhubRequest() {
            return Fail(error: APIError.rateLimitExceeded).eraseToAnyPublisher()
        }
        
        incrementFinnhubCounter()
        return finnhubService.fetchStockList()
            .map { stocks in
                // Filtrar y procesar las acciones según los criterios (precio, etc.)
                self.filterAndProcessStocks(stocks)
            }
            .eraseToAnyPublisher()
    }
    
    func fetchHistoricalData(for symbol: String, period: String = "1y") -> AnyPublisher<[HistoricalDataPoint], Error> {
        // Verificar cache primero
        if let cachedData = stockDataCache["\(symbol)_\(period)"],
           Date().timeIntervalSince(cachedData.lastUpdated) < 3600 { // Cache de 1 hora
            return Just(cachedData.historicalData)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        if !canMakeFinnhubRequest() {
            return Fail(error: APIError.rateLimitExceeded).eraseToAnyPublisher()
        }
        
        incrementFinnhubCounter()
        return finnhubService.fetchHistoricalData(for: symbol, period: period)
            .handleEvents(receiveOutput: { data in
                // Actualizar caché
                self.stockDataCache["\(symbol)_\(period)"] = StockData(
                    symbol: symbol,
                    historicalData: data,
                    lastUpdated: Date()
                )
            })
            .eraseToAnyPublisher()
    }
    
    // Métodos para acceder a noticias y sentimiento (usando Alpha Vantage)
    func fetchNewsAndSentiment(for symbol: String, days: Int = 7) -> AnyPublisher<[NewsArticle], Error> {
        // Verificar cache para noticias
        if let cachedNews = newsCache[symbol],
           Date().timeIntervalSince(cachedNews.timestamp) < 21600 { // Cache de 6 horas para noticias
            return Just(cachedNews.news)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        if !canMakeAlphaVantageRequest() {
            return Fail(error: APIError.rateLimitExceeded).eraseToAnyPublisher()
        }
        
        incrementAlphaVantageCounter()
        return alphaVantageService.fetchNews(for: symbol, days: days)
            .handleEvents(receiveOutput: { news in
                // Actualizar caché de noticias
                self.newsCache[symbol] = (timestamp: Date(), news: news)
            })
            .eraseToAnyPublisher()
    }
    
    // Método combinado para obtener todos los datos necesarios para la predicción
    func fetchCompleteDataForPrediction(symbol: String) -> AnyPublisher<PredictionInputData, Error> {
        return Publishers.CombineLatest3(
            fetchHistoricalData(for: symbol),
            fetchNewsAndSentiment(for: symbol),
            fetchStockProfile(symbol: symbol)
        )
        .map { historicalData, news, profile in
            PredictionInputData(
                symbol: symbol,
                historicalData: historicalData,
                news: news,
                profile: profile
            )
        }
        .eraseToAnyPublisher()
    }
    
    // Métodos adicionales para datos complementarios
    func fetchStockProfile(symbol: String) -> AnyPublisher<CompanyProfile, Error> {
        if !canMakeFinnhubRequest() {
            return Fail(error: APIError.rateLimitExceeded).eraseToAnyPublisher()
        }
        
        incrementFinnhubCounter()
        return finnhubService.fetchCompanyProfile(symbol: symbol)
            .eraseToAnyPublisher()
    }
    
    // Métodos para gestión de límites de API
    private func canMakeFinnhubRequest() -> Bool {
        let calendar = Calendar.current
        let currentMinute = calendar.component(.minute, from: Date())
        
        if currentMinute != lastFinnhubRequestMinute {
            finnhubRequestCount = 0
            lastFinnhubRequestMinute = currentMinute
        }
        
        return finnhubRequestCount < APIConfig.Finnhub.requestLimit
    }
    
    private func canMakeAlphaVantageRequest() -> Bool {
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: Date())
        
        if currentDay != lastAlphaVantageRequestDay {
            alphaVantageRequestCount = 0
            lastAlphaVantageRequestDay = currentDay
        }
        
        return alphaVantageRequestCount < APIConfig.AlphaVantage.requestLimit
    }
    
    private func incrementFinnhubCounter() {
        finnhubRequestCount += 1
    }
    
    private func incrementAlphaVantageCounter() {
        alphaVantageRequestCount += 1
    }
    
    private func setupRequestCounters() {
        let calendar = Calendar.current
        lastFinnhubRequestMinute = calendar.component(.minute, from: Date())
        lastAlphaVantageRequestDay = calendar.component(.day, from: Date())
    }
    
    // Procesamiento de datos
    private func filterAndProcessStocks(_ stocks: [Stock]) -> [Stock] {
        // Dividir stocks en económicos y premium basado en precio
        let economicThreshold: Double = 50.0
        
        var economicStocks = stocks.filter { $0.currentPrice < economicThreshold }
        var premiumStocks = stocks.filter { $0.currentPrice >= economicThreshold }
        
        // Asegurarnos de tener 25 de cada categoría
        economicStocks = Array(economicStocks.prefix(25))
        premiumStocks = Array(premiumStocks.prefix(25))
        
        // Mezclar para asegurar diversidad
        let result = economicStocks + premiumStocks
        return result.shuffled()
    }
}

// Estructuras complementarias
struct StockData {
    let symbol: String
    let historicalData: [HistoricalDataPoint]
    let lastUpdated: Date
}

struct PredictionInputData {
    let symbol: String
    let historicalData: [HistoricalDataPoint]
    let news: [NewsArticle]
    let profile: CompanyProfile
}

enum APIError: Error {
    case rateLimitExceeded
    case invalidResponse
    case dataProcessingError
}

import Foundation

struct APIConfig {
    struct AlphaVantage {
        static let apiKey = "EM64GJ2S1Y1XOK7G"
        static let baseURL = "https://www.alphavantage.co/query"
        static let requestLimit = 500 // Solicitudes diarias permitidas
    }
    
    struct Finnhub {
        static let apiKey = "d0h91i1r01qv1u361or0d0h91i1r01qv1u361org"
        static let baseURL = "https://finnhub.io/api/v1"
        static let requestLimit = 60 // Solicitudes por minuto
    }
    
    // Fecha de la última actualización de datos
    static let lastUpdated = Date() // Fecha actual para comenzar
}

import Foundation
import Combine
import CoreML

class PredictionEngine {
    // Gestor de APIs para obtener datos
    private let apiManager = APIManager.shared
    
    // Analizadores especializados
    private let technicalAnalyzer = TechnicalAnalyzer()
    private let newsAnalyzer = NewsSentimentAnalyzer()
    private let macroAnalyzer = MacroEconomicAnalyzer()
    
    // Pesos ponderados para el modelo ensemble
    private let technicalWeight = 0.55
    private let newsWeight = 0.30
    private let macroWeight = 0.15
    
    // Umbrales para clasificación de predicciones
    private let shortTermConfidenceThreshold = 0.65
    private let longTermConfidenceThreshold = 0.70
    
    // Pipeline de procesamiento
    private var cancellables = Set<AnyCancellable>()
    
    // Método principal para generar predicciones
    func generatePredictions(count: Int = 50) -> AnyPublisher<[StockPrediction], Error> {
        // 1. Obtener lista inicial de stocks
        return apiManager.fetchStockList()
            // 2. Realizar puntuación preliminar para filtrar stocks
            .flatMap { stocks -> AnyPublisher<[Stock], Error> in
                let stocksToAnalyze = Array(stocks.prefix(100))
                return self.performPreliminaryScoring(stocks: stocksToAnalyze)
            }
            // 3. Generar predicciones detalladas con los mejores stocks
            .flatMap { scoredStocks -> AnyPublisher<[StockPrediction], Error> in
                let topStocks = Array(scoredStocks.prefix(count * 2))
                return self.generateDetailedPredictions(for: topStocks)
            }
            // 4. Categorizar y ordenar las predicciones finales
            .map { predictions -> [StockPrediction] in
                return self.categorizeAndRankPredictions(predictions, targetCount: count)
            }
            .eraseToAnyPublisher()
    }
    
    // Análisis preliminar rápido para filtrar stocks
    private func performPreliminaryScoring(stocks: [Stock]) -> AnyPublisher<[Stock], Error> {
        let publishers = stocks.map { stock -> AnyPublisher<(Stock, Double), Error> in
            // Obtener solo datos históricos básicos para evaluación preliminar
            return apiManager.fetchHistoricalData(for: stock.symbol, period: "3m")
                .map { historicalData -> (Stock, Double) in
                    // Evaluar tendencia reciente y momentum
                    let score = self.calculatePreliminaryScore(stock: stock, historicalData: historicalData)
                    return (stock, score)
                }
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { scoredStocks -> [Stock] in
                // Ordenar por puntuación preliminar
                return scoredStocks.sorted { $0.1 > $1.1 }.map { $0.0 }
            }
            .eraseToAnyPublisher()
    }
    
    // Calcular puntaje preliminar basado en indicadores simples
    private func calculatePreliminaryScore(stock: Stock, historicalData: [HistoricalDataPoint]) -> Double {
        guard historicalData.count >= 20 else { return 0.0 }
        
        // Obtener precios recientes
        let prices = historicalData.map { $0.closePrice }
        let recentPrices = Array(prices.suffix(20))
        
        // Calcular tendencia simple (pendiente de la recta)
        var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0
        let n = Double(recentPrices.count)
        
        for (i, price) in recentPrices.enumerated() {
            let x = Double(i)
            sumX += x
            sumY += price
            sumXY += x * price
            sumX2 += x * x
        }
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let avgPrice = sumY / n
        let trendPercent = (slope / avgPrice) * 100
        
        // Calcular volatilidad
        var variance = 0.0
        for price in recentPrices {
            variance += pow(price - avgPrice, 2)
        }
        variance /= n
        let volatility = sqrt(variance) / avgPrice * 100
        
        // Calcular volumen relativo (cambio en volumen)
        let volumes = historicalData.map { Double($0.volume) }
        let recentVolumes = Array(volumes.suffix(10))
        let earlierVolumes = Array(volumes.suffix(20).prefix(10))
        
        let avgRecentVolume = recentVolumes.reduce(0, +) / Double(recentVolumes.count)
        let avgEarlierVolume = earlierVolumes.reduce(0, +) / Double(earlierVolumes.count)
        let volumeChange = (avgRecentVolume - avgEarlierVolume) / avgEarlierVolume * 100
        
        // Combinar factores para puntaje preliminar
        // Ponderar tendencia positiva, volatilidad moderada y volumen creciente
        
        // Ajustar puntuación de tendencia: valores positivos son buenos, negativos son malos
        let trendScore = trendPercent * 2
        
        // Ajustar puntuación de volatilidad: volatilidad moderada (5-15%) es óptima
        let volatilityScore = volatility < 5 ? volatility :
                              volatility < 15 ? 15 :
                              25 - volatility
        
        // Ajustar puntuación de volumen: crecimiento es positivo
        let volumeScore = min(20, max(-10, volumeChange * 0.5))
        
        // Puntaje total
        return trendScore + volatilityScore + volumeScore
    }
    
    // Generar predicciones detalladas para los stocks seleccionados
    private func generateDetailedPredictions(for stocks: [Stock]) -> AnyPublisher<[StockPrediction], Error> {
        let publishers = stocks.map { stock -> AnyPublisher<StockPrediction, Error> in
            return apiManager.fetchCompleteDataForPrediction(symbol: stock.symbol)
                .map { inputData -> StockPrediction in
                    return self.predictStockPerformance(stock: stock, inputData: inputData)
                }
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    // Método principal de predicción que combina todos los análisis
    private func predictStockPerformance(stock: Stock, inputData: PredictionInputData) -> StockPrediction {
        // 1. Análisis técnico
        let technicalAnalysis = technicalAnalyzer.analyze(historicalData: inputData.historicalData)
        
        // 2. Análisis de noticias y sentimiento
        let newsAnalysis = newsAnalyzer.analyze(news: inputData.news, symbol: stock.symbol)
        
        // 3. Análisis macroeconómico
        let macroAnalysis = macroAnalyzer.analyze(symbol: stock.symbol, profile: inputData.profile)
        
        // 4. Combinar los tres análisis con pesos ponderados
        let predictedChangePercent = (
            technicalAnalysis.predictedChangePercent * technicalWeight +
            newsAnalysis.sentimentImpact * newsWeight +
            macroAnalysis.econImpact * macroWeight
        )
        
        // 5. Calcular precio objetivo
        let predictedPrice = stock.currentPrice * (1.0 + predictedChangePercent / 100.0)
        
        // 6. Determinar nivel de confianza basado en la concordancia entre modelos
        let confidenceLevel = calculateConfidenceLevel(
            technical: technicalAnalysis,
            news: newsAnalysis,
            macro: macroAnalysis
        )
        
        // 7. Determinar horizonte temporal basado en características de los datos
        let timeFrame = determineTimeFrame(
            technical: technicalAnalysis,
            news: newsAnalysis,
            confidence: confidenceLevel
        )
        
        // 8. Identificar factores clave que influyeron en la predicción
        let keyFactors = combineKeyFactors(
            technical: technicalAnalysis.keyFactors,
            news: newsAnalysis.keyFactors,
            macro: macroAnalysis.keyFactors
        )
        
        // 9. Calcular fecha objetivo basada en el horizonte temporal
        let targetDate = calculateTargetDate(timeFrame: timeFrame)
        
        // 10. Construir objeto de predicción final
        return StockPrediction(
            stock: stock,
            predictedPrice: predictedPrice,
            currentPrice: stock.currentPrice,
            growthPotential: predictedChangePercent,
            confidenceLevel: confidenceLevel,
            timeFrame: timeFrame,
            keyFactors: keyFactors,
            technicalSignals: technicalAnalysis.signals,
            newsAnalysis: newsAnalysis,
            targetDate: targetDate
        )
    }
    
    // Calcular nivel de confianza combinado
    private func calculateConfidenceLevel(
        technical: TechnicalAnalysisResult,
        news: NewsAnalysisResult,
        macro: MacroEconomicResult
    ) -> Double {
        // Ponderar confianza de cada modelo
        let weightedTechnicalConfidence = technical.confidence * technicalWeight
        let weightedNewsConfidence = news.confidence * newsWeight
        let weightedMacroConfidence = macro.confidence * macroWeight
        
        // Confianza base ponderada
        let baseConfidence = weightedTechnicalConfidence + weightedNewsConfidence + weightedMacroConfidence
        
        // Verificar concordancia entre modelos (si todos apuntan en la misma dirección)
        let technicalDirection = technical.predictedChangePercent >= 0 ? 1 : -1
        let newsDirection = news.sentimentImpact >= 0 ? 1 : -1
        let macroDirection = macro.econImpact >= 0 ? 1 : -1
        
        // Bonificación por concordancia
        var concordanceBonus = 0.0
        if technicalDirection == newsDirection && technicalDirection == macroDirection {
            concordanceBonus = 0.15 // Bonus máximo si todos concuerdan
        } else if technicalDirection == newsDirection || technicalDirection == macroDirection || newsDirection == macroDirection {
            concordanceBonus = 0.05 // Bonus parcial si dos concuerdan
        }
        
        // Confianza final (limitada a 0.95 máximo)
        return min(0.95, baseConfidence + concordanceBonus)
    }
    
    // Determinar si la predicción es a corto o largo plazo
    private func determineTimeFrame(
        technical: TechnicalAnalysisResult,
        news: NewsAnalysisResult,
        confidence: Double
    ) -> StockPrediction.TimeFrame {
        // Factores que favorecen predicción a corto plazo:
        // - Alta volatilidad reciente
        // - Noticias recientes de alto impacto
        // - Señales técnicas fuertes a corto plazo
        
        // El análisis técnico nos da pistas sobre el horizonte más apropiado
        let technicalVote = technical.signals.contains(.strongBuy) ||
                           technical.signals.contains(.strongSell) ?
                           StockPrediction.TimeFrame.shortTerm : StockPrediction.TimeFrame.longTerm
        
        // Noticias recientes con alto impacto favorecen corto plazo
        let newsVote = abs(news.sentimentImpact) > 5.0 ?
                      StockPrediction.TimeFrame.shortTerm : StockPrediction.TimeFrame.longTerm
        
        // Considerar umbrales de confianza diferentes para cada horizonte
        if confidence >= shortTermConfidenceThreshold && technicalVote == .shortTerm {
            return .shortTerm
        } else if confidence >= longTermConfidenceThreshold {
            return .longTerm
        } else if newsVote == .shortTerm && abs(news.sentimentImpact) > 7.0 {
            // Noticias de muy alto impacto pueden definir el horizonte en caso dudoso
            return .shortTerm
        } else {
            // Default a largo plazo si no hay señales fuertes
            return .longTerm
        }
    }
    
    // Combinar factores clave de todos los análisis
    private func combineKeyFactors(
        technical: [PredictionFactor],
        news: [PredictionFactor],
        macro: [PredictionFactor]
    ) -> [PredictionFactor] {
        // Tomar algunos factores de cada categoría, priorizando los de mayor impacto
        var combinedFactors = [PredictionFactor]()
        
        // Añadir los factores técnicos más relevantes
        combinedFactors.append(contentsOf: technical.prefix(3))
        
        // Añadir los factores de noticias más relevantes
        combinedFactors.append(contentsOf: news.prefix(2))
        
        // Añadir los factores macroeconómicos más relevantes
        combinedFactors.append(contentsOf: macro.prefix(2))
        
        // Ordenar por impacto absoluto
        return combinedFactors.sorted { abs($0.impact) > abs($1.impact) }
    }
    
    // Calcular fecha objetivo basada en el horizonte temporal
    private func calculateTargetDate(timeFrame: StockPrediction.TimeFrame) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        switch timeFrame {
        case .shortTerm:
            // 4-6 semanas (30-45 días)
            return calendar.date(byAdding: .day, value: 30, to: today) ?? today
        case .longTerm:
            // 3-4 meses (90-120 días)
            return calendar.date(byAdding: .day, value: 90, to: today) ?? today
        }
    }
    
    // Categorizar predicciones en corto y largo plazo, y ordenarlas por potencial
    private func categorizeAndRankPredictions(_ predictions: [StockPrediction], targetCount: Int) -> [StockPrediction] {
        // Separar predicciones por horizonte temporal
        var shortTermPredictions = predictions.filter { $0.timeFrame == .shortTerm }
        var longTermPredictions = predictions.filter { $0.timeFrame == .longTerm }
        
        // Ordenar cada grupo por potencial de crecimiento
        shortTermPredictions.sort { $0.growthPotential > $1.growthPotential }
        longTermPredictions.sort { $0.growthPotential > $1.growthPotential }
        
        // Asegurar que tenemos suficientes predicciones de cada tipo
        let shortTermCount = min(targetCount / 2, shortTermPredictions.count)
        let longTermCount = min(targetCount / 2, longTermPredictions.count)
        
        // Tomar las mejores predicciones de cada grupo
        var result = Array(shortTermPredictions.prefix(shortTermCount))
        result.append(contentsOf: longTermPredictions.prefix(longTermCount))
        
        // Si no tenemos suficientes de algún tipo, compensar con el otro
        if result.count < targetCount {
            if shortTermPredictions.count > shortTermCount {
                let additionalShortTerm = min(targetCount - result.count, shortTermPredictions.count - shortTermCount)
                result.append(contentsOf: shortTermPredictions[shortTermCount..<(shortTermCount + additionalShortTerm)])
            } else if longTermPredictions.count > longTermCount {
                let additionalLongTerm = min(targetCount - result.count, longTermPredictions.count - longTermCount)
                result.append(contentsOf: longTermPredictions[longTermCount..<(longTermCount + additionalLongTerm)])
            }
        }
        
        return result
    }
    
    // Método para análisis individual de una acción específica
    func analyzeStock(symbol: String) -> AnyPublisher<StockPrediction, Error> {
        // Primero obtenemos datos básicos del stock
        return apiManager.fetchStockList()
            .flatMap { stocks -> AnyPublisher<Stock, Error> in
                if let stock = stocks.first(where: { $0.symbol == symbol }) {
                    return Just(stock).setFailureType(to: Error.self).eraseToAnyPublisher()
                } else {
                    return Fail(error: PredictionError.stockNotFound).eraseToAnyPublisher()
                }
            }
            .flatMap { stock -> AnyPublisher<StockPrediction, Error> in
                // Luego obtenemos todos los datos necesarios para el análisis
                return self.apiManager.fetchCompleteDataForPrediction(symbol: stock.symbol)
                    .map { inputData -> StockPrediction in
                        // Generar predicción detallada
                        return self.predictStockPerformance(stock: stock, inputData: inputData)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

// Errores específicos del motor de predicción
enum PredictionError: Error {
    case insufficientData
    case stockNotFound
    case apiLimitExceeded
    case processingError
    
    var localizedDescription: String {
        switch self {
        case .insufficientData:
            return "No hay suficientes datos para generar una predicción confiable."
        case .stockNotFound:
            return "No se encontró la acción especificada."
        case .apiLimitExceeded:
            return "Se ha excedido el límite de solicitudes a la API. Por favor, inténtelo más tarde."
        case .processingError:
            return "Error procesando los datos. Por favor, inténtelo de nuevo."
        }
    }
}


import Foundation

// Esta estructura es un modelo básico de predicción que se utilizaba en los cálculos iniciales.
// Se debe usar StockPrediction para la implementación final.
struct Prediction: Identifiable {
    let id = UUID()
    let stock: Stock
    let targetDate: Date
    let predictedPrice: Double
    let confidenceLevel: Double
    let growthPotential: Double
    let timeFrame: TimeFrame
    
    enum TimeFrame: String {
        case shortTerm = "Corto Plazo"
        case longTerm = "Largo Plazo"
    }
}
