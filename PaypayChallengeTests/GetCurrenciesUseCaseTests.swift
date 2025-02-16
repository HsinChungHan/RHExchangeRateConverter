//
//  GetCurrenciesUseCaseTests.swift
//  PaypayChallenge
//
//  Created by Chung Han Hsin on 2025/2/16.
//

import XCTest

// MARK: - Mock Remote Repository
/// A mock implementation of `RemoteCurrenciesRepositoryProtocol` for testing.
class MockRemoteRepository: RemoteCurrenciesRepositoryProtocol {
    var ratesResponse: Result<RatesDTO, RemoteCurrenciesRepositoryError> = .failure(.FailedToGetLatestCurrencies)

    func getCurrencies() async -> Result<RatesDTO, RemoteCurrenciesRepositoryError> {
        return ratesResponse
    }
}

final class GetCurrenciesUseCaseTests: XCTestCase {
    var useCase: GetCurrenciesUseCase!
    var mockRemoteRepository: MockRemoteRepository!
    var mockStoreRepository: MockStoreRepository!

    override func setUp() async throws {
        mockRemoteRepository = MockRemoteRepository()
        mockStoreRepository = MockStoreRepository()
        useCase = GetCurrenciesUseCase(remoteRepository: mockRemoteRepository, storeRepository: mockStoreRepository)
    }

    override func tearDown() async throws {
        useCase = nil
        mockRemoteRepository = nil
        mockStoreRepository = nil
    }

    // MARK: - Test fetching currencies from local storage when refresh is not needed
    /// Tests that currencies are fetched from local storage if the last fetch was within 30 minutes.
    func test_getCurrencies_FromLocal_WhenFetchNotNeeded() async throws {
        let recentFetchTime = Date().timeIntervalSince1970 - 1000 // 16.67 minutes ago (< 30 minutes)
        mockStoreRepository.lastFetchTime = recentFetchTime
        let expectedRates = RatesDTO(rates: ["USD": 1.0])
        mockStoreRepository.storedRates = expectedRates

        let rates = try await useCase.getLatestCurrencies()
        XCTAssertEqual(rates, expectedRates.domainModels, "Should fetch exchange rates from local storage")
    }

    // MARK: - Test fetching currencies from remote when refresh is needed
    /// Tests that currencies are fetched from remote if the last fetch was over 30 minutes ago.
    func test_getCurrencies_FromRemote_WhenFetchNeeded() async throws {
        let oldFetchTime = Date().timeIntervalSince1970 - 4000 // 66.67 minutes ago (> 30 minutes)
        mockStoreRepository.lastFetchTime = oldFetchTime
        let expectedRates = RatesDTO(rates: ["USD": 1.2])
        mockRemoteRepository.ratesResponse = .success(expectedRates)

        let rates = try await useCase.getLatestCurrencies()

        XCTAssertEqual(rates, expectedRates.domainModels, "Should fetch exchange rates from remote")
        XCTAssertEqual(mockStoreRepository.storedRates, expectedRates, "Should store new exchange rate data")
        XCTAssertEqual(mockStoreRepository.lastFetchTime!, Date().timeIntervalSince1970, accuracy: 0.01, "Should update the last fetch time")
    }

    // MARK: - Test error handling when retrieving last fetch time fails
    /// Tests that an error is thrown when `getLastFetchTime` fails.
    func test_getCurrencies_ThrowsError_WhenLastFetchTimeFails() async throws {
        mockStoreRepository.shouldThrowError = true

        do {
            _ = try await useCase.getLatestCurrencies()
            XCTFail("Expected FailedToGetCurrencies error but got success")
        } catch let error as GetCurrenciesUseCaseError {
            XCTAssertEqual(error, .FailedToGetCurrencies)
        }
    }

    // MARK: - Test error handling when remote fetch fails
    /// Tests that an error is thrown when `remoteRepository.getCurrencies` fails.
    func test_getCurrencies_ThrowsError_WhenRemoteFetchFails() async throws {
        let oldFetchTime = Date().timeIntervalSince1970 - 4000
        mockStoreRepository.lastFetchTime = oldFetchTime
        mockRemoteRepository.ratesResponse = .failure(.FailedToGetLatestCurrencies)

        do {
            _ = try await useCase.getLatestCurrencies()
            XCTFail("Expected FailedToGetCurrencies error but got success")
        } catch let error as GetCurrenciesUseCaseError {
            XCTAssertEqual(error, .FailedToGetCurrencies)
        }
    }

    // MARK: - Test error handling when local fetch fails
    /// Tests that an error is thrown when `storeRepository.getCurrencies` fails.
    func test_getCurrencies_ThrowsError_WhenLocalFetchFails() async throws {
        let recentFetchTime = Date().timeIntervalSince1970 - 1000
        mockStoreRepository.lastFetchTime = recentFetchTime
        mockStoreRepository.shouldThrowError = true

        do {
            _ = try await useCase.getLatestCurrencies()
            XCTFail("Expected FailedToGetCurrencies error but got success")
        } catch let error as GetCurrenciesUseCaseError {
            XCTAssertEqual(error, .FailedToGetCurrencies)
        }
    }
}
