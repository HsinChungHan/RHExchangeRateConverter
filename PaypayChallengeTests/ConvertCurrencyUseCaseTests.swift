//
//  ConvertCurrencyUseCaseTests.swift
//  PaypayChallengeTests
//
//  Created by Chung Han Hsin on 2025/2/16.
//

import XCTest

// MARK: - Mock Store Repository
/// A mock implementation of `StoreCurrenciesRepositoryProtocol` for testing.
class MockStoreRepository: StoreCurrenciesRepositoryProtocol {
    var lastFetchTime: TimeInterval?
    var storedRates: RatesDTO?
    var shouldThrowError = false

    func saveLastFetchTime(timeStamp: TimeInterval) async throws {
        if shouldThrowError { throw GetCurrenciesUseCaseError.FailedToSaveCurrentTimeStamp }
        lastFetchTime = timeStamp
    }

    func getLastFetchTime() async throws -> TimeInterval {
        if shouldThrowError { throw GetCurrenciesUseCaseError.FailedToGetCurrencies }
        guard let time = lastFetchTime else { throw GetCurrenciesUseCaseError.FailedToGetCurrencies }
        return time
    }

    func saveCurrencies(_ rates: RatesDTO) async throws {
        if shouldThrowError { throw GetCurrenciesUseCaseError.FailedToSaveCurrencies }
        storedRates = rates
    }

    func getCurrencies() async throws -> RatesDTO {
        if shouldThrowError { throw GetCurrenciesUseCaseError.FailedToGetCurrencies }
        guard let rates = storedRates else { throw GetCurrenciesUseCaseError.FailedToGetCurrencies }
        return rates
    }
}

// MARK: - ConvertCurrencyUseCaseTests
final class ConvertCurrencyUseCaseTests: XCTestCase {
    var useCase: ConvertCurrencyUseCase!

    override func setUp() {
        super.setUp()
        useCase = ConvertCurrencyUseCase()
    }

    override func tearDown() {
        useCase = nil
        super.tearDown()
    }

    // MARK: - Test conversion when a direct rate exists
    /// Tests that conversion works correctly when a direct rate is available.
    func test_convert_ReturnsConvertedAmount_WhenDirectRateExists() throws {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "JPY", rate: 110.0)
        ])

        let convertedAmount = try useCase.convert("USD", toCurrency: "EUR", withAmount: 100)

        XCTAssertEqual(convertedAmount, 85.0, accuracy: 0.001, "USD -> EUR should be converted to 85.0")
    }

    // MARK: - Test conversion using an intermediary currency
    /// Tests that conversion works via an intermediary currency when no direct rate exists.
    func test_convert_UsesMediatorCurrency_WhenDirectRateNotAvailable() throws {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "JPY", rate: 110.0),
            Rate(currency: "GBP", rate: 0.75)
        ])

        // GBP → JPY has no direct rate but can be converted via USD
        let convertedAmount = try useCase.convert("GBP", toCurrency: "JPY", withAmount: 100)

        let expectedAmount: Float = (100 / 0.75) * 110.0 // GBP → USD → JPY
        XCTAssertEqual(convertedAmount, expectedAmount, accuracy: 0.001, "GBP -> USD -> JPY conversion incorrect")
    }

    // MARK: - Test conversion when multiple mediators exist
    /// Tests that the first available intermediary currency is used when multiple options exist.
    func test_convert_UsesFirstMediatorCurrency_WhenMultipleMediatorsAvailable() throws {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "JPY", rate: 110.0),
            Rate(currency: "GBP", rate: 0.75),
            Rate(currency: "AUD", rate: 1.4)
        ])

        // GBP → JPY has no direct rate but can be converted via USD or AUD, should prefer USD
        let convertedAmount = try useCase.convert("GBP", toCurrency: "JPY", withAmount: 100)

        let expectedAmount: Float = (100 / 0.75) * 110.0 // GBP → USD → JPY
        XCTAssertEqual(convertedAmount, expectedAmount, accuracy: 0.001, "GBP -> USD -> JPY conversion incorrect")
    }

    // MARK: - Test error when no valid conversion path exists
    /// Tests that an error is thrown when there is no valid conversion path.
    func test_convert_ThrowsError_WhenNoValidConversionPathExists() {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85)
        ])

        XCTAssertThrowsError(try useCase.convert("JPY", toCurrency: "GBP", withAmount: 100)) { error in
            XCTAssertEqual(error as? ConvertCurrencyUseCaseError, ConvertCurrencyUseCaseError.unableToConvert(fromCurrency: "JPY", toCurrency: "GBP"))
        }
    }

    // MARK: - Test same currency conversion
    /// Tests that conversion returns the same amount when both currencies are identical.
    func test_convert_ReturnsSameAmount_WhenCurrenciesAreIdentical() throws {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85)
        ])

        let convertedAmount = try useCase.convert("EUR", toCurrency: "EUR", withAmount: 100)

        XCTAssertEqual(convertedAmount, 100.0, "Same currency conversion should return the same amount")
    }

    // MARK: - Test convertToAllCurrencies
    /// Tests that `convertToAllCurrencies` correctly converts all available currencies.
    func test_convertToAllCurrencies_ConvertsCorrectly() {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "JPY", rate: 110.0)
        ])

        let results = useCase.convertToAllCurrencies(fromCurrency: "USD", amount: 100)

        XCTAssertEqual(results.count, 3, "Should have 3 conversion results")

        XCTAssertEqual(Double(results.first(where: { $0.0 == "EUR" })?.1 ?? 0), 85.0, accuracy: 0.001, "USD -> EUR conversion incorrect")

        XCTAssertEqual(Double(results.first(where: { $0.0 == "JPY" })?.1 ?? 0), 11000.0, accuracy: 0.001, "USD -> JPY conversion incorrect")
    }

    // MARK: - Test empty results when amount is zero
    /// Tests that `convertToAllCurrencies` returns an empty array when the amount is zero.
    func test_convertToAllCurrencies_ReturnsEmpty_WhenAmountIsZero() {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "JPY", rate: 110.0)
        ])

        let results = useCase.convertToAllCurrencies(fromCurrency: "USD", amount: 0)

        XCTAssertTrue(results.isEmpty, "When amount = 0, should return an empty array")
    }
}
