//
//  ConverterViewModel.swift
//  PaypayChallenge
//
//  Created by Chung Han Hsin on 2025/2/16.
//

import Foundation

/// Converter ViewModel Errors
enum ConverterViewModelError: Error {
    case unableToConvert(fromCurrency: String, toCurrency: String)
    case failedToFetchRates
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .unableToConvert(let from, let to):
            return "Unable to convert from \(from) to \(to) using available exchange rates."
        case .failedToFetchRates:
            return "Failed to fetch the latest exchange rates."
        case .unknownError:
            return "An unknown error occurred during conversion."
        }
    }
}

class ConverterViewModel {
    let getCurrenciesUseCase: GetCurrenciesUseCaseProtocol
    let convertCurrencyUseCase: ConvertCurrencyUseCaseProtocol

    var convertedAmountHandler: ((Float) -> Void)?
    var convertedResultsHandler: (([(String, Float)]) -> Void)? // Updates conversion results for all currencies
    var currencyListUpdatedHandler: ((Int) -> Void)? // Updates picker view and selects USD by default
    var errorHandler: ((String) -> Void)?
    var isLoadingHandler: ((Bool) -> Void)?

    var currencyList: [String] = []
    let defaultSelectedCurrency = "USD"
    lazy var selectedCurrency = defaultSelectedCurrency

    init(getCurrenciesUseCase: GetCurrenciesUseCaseProtocol, convertCurrencyUseCase: ConvertCurrencyUseCaseProtocol) {
        self.getCurrenciesUseCase = getCurrenciesUseCase
        self.convertCurrencyUseCase = convertCurrencyUseCase
    }

    // MARK: - Fetch Latest Exchange Rates
    func fetchLatestCurrencies() async {
        do {
            isLoadingHandler?(true)
            let rates = try await getCurrenciesUseCase.getLatestCurrencies()
            currencyList = rates.map { $0.currency }.sorted()
            convertCurrencyUseCase.updateRates(rates) // Ensures the latest data is used
            isLoadingHandler?(false)

            // Find the index of USD and notify the picker view to select USD by default
            currencyListUpdatedHandler?(currencyList.firstIndex(of: defaultSelectedCurrency) ?? 0)
        } catch {
            isLoadingHandler?(false)
            errorHandler?(ConverterViewModelError.failedToFetchRates.localizedDescription)
        }
    }

    // MARK: - Perform Currency Conversion
    func doConvertProcess(fromCurrency: String, toCurrency: String, amount: Float) async {
        do {
            isLoadingHandler?(true)

            // Ensure ConvertCurrencyUseCase has the latest data
            if convertCurrencyUseCase.rates.isEmpty {
                let latestRates = try await getCurrenciesUseCase.getLatestCurrencies()
                convertCurrencyUseCase.updateRates(latestRates)
            }

            // Attempt currency conversion
            let converted = try convertCurrencyUseCase.convert(fromCurrency, toCurrency: toCurrency, withAmount: amount)

            isLoadingHandler?(false)
            convertedAmountHandler?(converted) // Returns the converted amount to ViewController
        } catch let error as ConverterViewModelError {
            isLoadingHandler?(false)
            errorHandler?(error.localizedDescription)
        } catch _ as ConvertCurrencyUseCaseError {
            isLoadingHandler?(false)
            errorHandler?(ConverterViewModelError.unableToConvert(fromCurrency: fromCurrency, toCurrency: toCurrency).localizedDescription)
        } catch {
            isLoadingHandler?(false)
            errorHandler?(ConverterViewModelError.unknownError.localizedDescription)
        }
    }

    // MARK: - Update Conversion Results for All Currencies
    func updateConversionResults(amountText: String) {
        guard let amount = Float(amountText), amount > 0 else {
            convertedResultsHandler?([]) // Clears conversion results if the amount is empty or zero
            return
        }
        
        let results = convertCurrencyUseCase.convertToAllCurrencies(fromCurrency: selectedCurrency, amount: amount)
        convertedResultsHandler?(results) // Notifies ViewController to update the table view
    }

    // MARK: - Update Selected Currency
    func setSelectedCurrency(_ currency: String) {
        selectedCurrency = currency
    }
}

