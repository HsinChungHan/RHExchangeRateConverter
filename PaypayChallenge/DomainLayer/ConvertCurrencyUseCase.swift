//
//  ConvertCurrencyUseCase.swift
//  PaypayChallenge
//
//  Created by Chung Han Hsin on 2025/2/16.
//

import Foundation

/// Currency Conversion Errors
enum ConvertCurrencyUseCaseError: Error, Equatable {
    case unableToConvert(fromCurrency: String, toCurrency: String)

    var localizedDescription: String {
        switch self {
        case .unableToConvert(let from, let to):
            return "Unable to convert from \(from) to \(to) using available exchange rates."
        }
    }
}

/// Protocol for currency conversion operations
protocol ConvertCurrencyUseCaseProtocol {
    var rates: [Rate] { get set }
    func updateRates(_ rates: [Rate])
    func convert(_ fromCurrency: String, toCurrency: String, withAmount amount: Float) throws -> Float
    func convertToAllCurrencies(fromCurrency: String, amount: Float) -> [(String, Float)]
}

/// **Handles the logic for currency conversion**
class ConvertCurrencyUseCase: ConvertCurrencyUseCaseProtocol {
    var rates: [Rate] = []

    // MARK: - Update Exchange Rates
    /// Updates the exchange rate data
    func updateRates(_ rates: [Rate]) {
        self.rates = rates
    }

    // MARK: - Convert Single Currency
    /// Converts an amount from one currency to another
    func convert(_ fromCurrency: String, toCurrency: String, withAmount amount: Float) throws -> Float {
        guard fromCurrency != toCurrency else { return amount }
        guard !rates.isEmpty else {
            throw ConvertCurrencyUseCaseError.unableToConvert(fromCurrency: fromCurrency, toCurrency: toCurrency)
        }

        // Create a dictionary for quick lookup of exchange rates**
        let rateDict = Dictionary(uniqueKeysWithValues: rates.map { ($0.currency, $0.rate) })

        // Direct conversion if a direct exchange rate exists**
        if let fromRate = rateDict[fromCurrency], let toRate = rateDict[toCurrency] {
            return (amount / fromRate) * toRate
        }

        // Use an intermediary currency for conversion**
        if let convertedAmount = findMediatorConversion(fromCurrency: fromCurrency, toCurrency: toCurrency, amount: amount, rateDict: rateDict) {
            return convertedAmount
        }

        throw ConvertCurrencyUseCaseError.unableToConvert(fromCurrency: fromCurrency, toCurrency: toCurrency)
    }

    // MARK: - Convert to All Currencies
    /// Converts an amount to all available currencies
    func convertToAllCurrencies(fromCurrency: String, amount: Float) -> [(String, Float)] {
        guard amount > 0 else {
            return [] // Clear results if amount is zero
        }

        let rateDict = Dictionary(uniqueKeysWithValues: rates.map { ($0.currency, $0.rate) })

        return rates.compactMap { rate -> (String, Float)? in
            guard let fromRate = rateDict[fromCurrency] else { return nil }
            let convertedAmount = (amount / fromRate) * rate.rate
            return (rate.currency, convertedAmount)
        }
    }
}

// MARK: - Private Helpers
extension ConvertCurrencyUseCase {
    
    // MARK: - Convert Using an Intermediary Currency
    /// Attempts to find an intermediary currency to facilitate the conversion
    private func findMediatorConversion(fromCurrency: String, toCurrency: String, amount: Float, rateDict: [String: Float]) -> Float? {
        for mediatorCurrency in rateDict.keys {
            
            // Case 1: fromCurrency → mediatorCurrency → toCurrency
            if let fromRate = rateDict[fromCurrency], let mediatorToTargetRate = rateDict[mediatorCurrency],
               let targetRate = rateDict[toCurrency] {
                let amountInMediator = amount / fromRate * mediatorToTargetRate
                return amountInMediator / mediatorToTargetRate * targetRate
            }

            // **Case 2: fromCurrency → mediatorCurrency → toCurrency (Alternative Calculation)
            if let fromRate = rateDict[mediatorCurrency], let mediatorFromRate = rateDict[fromCurrency],
               let targetRate = rateDict[toCurrency] {
                let amountInMediator = amount * mediatorFromRate / fromRate
                return amountInMediator * targetRate
            }
        }
        return nil
    }
}
