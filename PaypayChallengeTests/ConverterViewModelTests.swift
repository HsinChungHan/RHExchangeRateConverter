//
//  ConverterViewModelTests.swift
//  PaypayChallengeTests
//
//  Created by Chung Han Hsin on 2025/2/16.
//

import XCTest

// MARK: - Mock GetCurrenciesUseCase
/// A mock implementation of `GetCurrenciesUseCaseProtocol` for testing.
class MockGetCurrenciesUseCase: GetCurrenciesUseCaseProtocol {
    func getSortedCurrencyList() async throws -> [String] {
        return []
    }
    
    var mockRates: [Rate] = []
    var shouldThrowError = false

    func getLatestCurrencies() async throws -> [Rate] {
        if shouldThrowError {
            throw GetCurrenciesUseCaseError.FailedToGetCurrencies
        }
        return mockRates
    }
}

// MARK: - Mock ConvertCurrencyUseCase
/// A mock implementation of `ConvertCurrencyUseCaseProtocol` for testing.
class MockConvertCurrencyUseCase: ConvertCurrencyUseCaseProtocol {
    var rates: [Rate] = []
    var mockConversionResult: Float = 0.0
    var mockAllCurrencyResults: [(String, Float)] = []
    var shouldThrowError = false

    func updateRates(_ rates: [Rate]) {
        self.rates = rates
    }

    func convert(_ fromCurrency: String, toCurrency: String, withAmount amount: Float) throws -> Float {
        if shouldThrowError {
            throw ConvertCurrencyUseCaseError.unableToConvert(fromCurrency: fromCurrency, toCurrency: toCurrency)
        }
        return mockConversionResult
    }

    func convertToAllCurrencies(fromCurrency: String, amount: Float) -> [(String, Float)] {
        return mockAllCurrencyResults.isEmpty ? rates.map { ($0.currency, (amount / 1.0) * $0.rate) } : mockAllCurrencyResults
    }
}

// MARK: - ConverterViewModelTests
final class ConverterViewModelTests: XCTestCase {

    var mockGetCurrenciesUseCase: MockGetCurrenciesUseCase!
    var mockConvertCurrencyUseCase: MockConvertCurrencyUseCase!
    var viewModel: ConverterViewModel!
    
    override func setUp() {
        super.setUp()
        mockGetCurrenciesUseCase = MockGetCurrenciesUseCase()
        mockConvertCurrencyUseCase = MockConvertCurrencyUseCase()
        viewModel = ConverterViewModel(
            getCurrenciesUseCase: mockGetCurrenciesUseCase,
            convertCurrencyUseCase: mockConvertCurrencyUseCase
        )
    }

    override func tearDown() {
        mockGetCurrenciesUseCase = nil
        mockConvertCurrencyUseCase = nil
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Test fetching latest currencies and setting USD as default
    /// Tests that fetching latest currencies updates the rates and selects USD as the default.
    func test_getCurrencies_UpdatesRatesSuccessfullyAndSelectUSDAsDefault() async {
        let expectation = expectation(description: "Rates should be updated successfully")
        
        mockGetCurrenciesUseCase.mockRates = [
            Rate(currency: "JPY", rate: 110.0),
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85)
        ]

        viewModel.currencyListUpdatedHandler = { selectedIndex in
            let expectedSortedList = ["EUR", "JPY", "USD"] //  Sorted in A-Z order
            XCTAssertEqual(self.viewModel.currencyList, expectedSortedList, "Currency list should be sorted in A-Z order")
            
            //  Ensure USD is selected as the default currency
            XCTAssertEqual(selectedIndex, expectedSortedList.firstIndex(of: "USD"), "USD should be selected as the default currency")

            expectation.fulfill()
        }

        await viewModel.fetchLatestCurrencies()

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Test error handling when fetching currencies fails
    /// Tests that an error is returned when fetching latest currencies fails.
    func test_getCurrencies_ReturnsError_WhenFetchingRatesFails() async {
        let expectation = expectation(description: "Error should be received when fetching rates fails")
        
        mockGetCurrenciesUseCase.shouldThrowError = true

        viewModel.errorHandler = { error in
            XCTAssertEqual(error, ConverterViewModelError.failedToFetchRates.localizedDescription)
            expectation.fulfill()
        }

        await viewModel.fetchLatestCurrencies()
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Test successful currency conversion
    /// Tests that currency conversion is successful.
    func test_getCurrencies_SuccessfullyConvertsCurrency() async {
        let expectation = expectation(description: "Should convert currency successfully")

        mockConvertCurrencyUseCase.mockConversionResult = 85.0
        mockConvertCurrencyUseCase.rates = [
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85)
        ]

        viewModel.convertedAmountHandler = { convertedAmount in
            XCTAssertEqual(convertedAmount, 85.0)
            expectation.fulfill()
        }

        await viewModel.doConvertProcess(fromCurrency: "USD", toCurrency: "EUR", amount: 100)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Test error handling when conversion fails
    /// Tests that an error is returned when currency conversion fails.
    func test_getCurrencies_ReturnsError_WhenConversionFails() async {
        let expectation = expectation(description: "Error should be received during conversion")

        mockConvertCurrencyUseCase.shouldThrowError = true

        viewModel.errorHandler = { error in
            XCTAssertEqual(error, ConverterViewModelError.unableToConvert(fromCurrency: "USD", toCurrency: "EUR").localizedDescription)
            expectation.fulfill()
        }

        await viewModel.doConvertProcess(fromCurrency: "USD", toCurrency: "EUR", amount: 100)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Test fetching rates when they are empty
    /// Tests that fetching rates occurs before conversion when rates are empty.
    func test_getCurrencies_FetchesRates_WhenRatesAreEmpty() async {
        let expectation = expectation(description: "Should fetch rates before conversion")

        mockConvertCurrencyUseCase.rates = [] // No rates available
        mockGetCurrenciesUseCase.mockRates = [
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85)
        ]
        mockConvertCurrencyUseCase.mockConversionResult = 85.0

        viewModel.convertedAmountHandler = { convertedAmount in
            XCTAssertEqual(convertedAmount, 85.0)
            expectation.fulfill()
        }

        await viewModel.doConvertProcess(fromCurrency: "USD", toCurrency: "EUR", amount: 100)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Test clearing conversion results when amount is zero
    /// Tests that conversion results are cleared when the amount is zero.
    func test_getCurrencies_ClearsResults_WhenAmountIsZero() {
        let expectation = expectation(description: "Should clear conversion results when amount is 0")

        viewModel.convertedResultsHandler = { results in
            XCTAssertTrue(results.isEmpty, "When amount is 0, conversion results should be empty")
            expectation.fulfill()
        }

        viewModel.updateConversionResults(amountText: "0")

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Test updating conversion results when amount is positive
    /// Tests that conversion results are correctly updated when the amount is positive.
    func test_getCurrencies_UpdatesResults_WhenAmountIsPositive() {
        let expectation = expectation(description: "Should update conversion results correctly")

        mockConvertCurrencyUseCase.rates = [
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "JPY", rate: 110.0)
        ]

        viewModel.convertedResultsHandler = { results in
            XCTAssertEqual(results.count, 3, "Should have 3 conversion results")
            expectation.fulfill()
        }

        viewModel.currencyList = ["USD", "EUR", "JPY"]
        viewModel.setSelectedCurrency("USD")
        viewModel.updateConversionResults(amountText: "100")

        wait(for: [expectation], timeout: 1.0)
    }
}
