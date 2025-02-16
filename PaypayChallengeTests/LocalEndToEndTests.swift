//
//  LocalEndToEndTests.swift
//  PaypayChallengeTests
//
//  Created by Chung Han Hsin on 2025/2/16.
//


import XCTest
@testable import PaypayChallenge
@testable import RHCacheStoreAPI
@testable import RHCacheStore

// Mock store for testing
actor MockStore: RHActorCacheStoreAPIProtocol {
    private var storage: [String: Any] = [:]
    
    func insert(with key: String, json: Any) async throws {
        storage[key] = json
    }

    func retrieve(with key: String) async -> RetriveCacheResult {
        if let value = storage[key] {
            return .found(value)
        }
        return .empty
    }
    
    func delete(with id: String) async throws {}
    func saveCache() async throws {}
    func loadCache() async throws {}
}

final class StoreCurrenciesRepositoryTests: XCTestCase {
    var repository: StoreCurrenciesRepository!
    var mockStore: MockStore!

    override func setUp() async throws {
        mockStore = MockStore()
        repository = StoreCurrenciesRepository(store: mockStore)
    }

    override func tearDown() async throws {
        repository = nil
        mockStore = nil
    }
    
    // MARK: - Test saving and retrieving last fetch time
    /// Tests that `saveLastFetchTime` correctly stores the timestamp and `getLastFetchTime` retrieves it.
    func test_saveAndGetLastFetchTime() async throws {
        let testTime: TimeInterval = 1707993600 // Example Unix timestamp

        // Save timestamp
        try await repository.saveLastFetchTime(timeStamp: testTime)

        // Retrieve timestamp
        let fetchedTime = try await repository.getLastFetchTime()
        
        // Assert the retrieved value matches the saved timestamp
        XCTAssertEqual(fetchedTime, testTime, "Fetched timestamp should match saved timestamp")
    }

    // MARK: - Test saving and retrieving currency exchange rates
    /// Tests that `saveCurrencies` correctly stores the exchange rates and `getCurrencies` retrieves them.
    func test_saveAndGetCurrencies() async throws {
        let rates = RatesDTO(rates: ["USD": 1.0])

        // Save exchange rates
        try await repository.saveCurrencies(rates)

        // Retrieve exchange rates
        let fetchedRates = try await repository.getCurrencies()

        // Assert the retrieved rates match the saved rates
        XCTAssertEqual(fetchedRates.rates, rates.rates)
    }

    // MARK: - Test retrieving last fetch time when data does not exist
    /// Tests that `getLastFetchTime` returns the smallest possible timestamp when no data is found.
    func test_getLastFetchTime_Empty() async throws {
        let lastFetchTime = try await repository.getLastFetchTime()
        XCTAssertEqual(lastFetchTime, TimeInterval.leastNormalMagnitude)
    }

    // MARK: - Test retrieving exchange rates when data does not exist
    /// Tests that `getCurrencies` throws an error when no exchange rate data is found.
    func test_getCurrencies_Empty() async throws {
        do {
            _ = try await repository.getCurrencies()
            XCTFail("Expected failure but got success")
        } catch let error as StoreCurrenciesRepositoryError {
            XCTAssertEqual(error, .CannotFindCurrencies)
        }
    }
}
