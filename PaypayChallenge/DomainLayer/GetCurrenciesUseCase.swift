//
//  GetCurrenciesUseCase.swift
//  PaypayChallenge
//
//  Created by Chung Han Hsin on 2025/2/16.
//

import Foundation

/// **Error Types for GetCurrenciesUseCase**
enum GetCurrenciesUseCaseError: Error {
    case FailedToGetCurrencies
    case FailedToSaveCurrencies
    case FailedToSaveCurrentTimeStamp
}

/// **Protocol for fetching currency rates**
protocol GetCurrenciesUseCaseProtocol {
    func getLatestCurrencies() async throws -> [Rate]
    func getSortedCurrencyList() async throws -> [String]  // allow ViewModel to retrieve a sorted currency list
}

/// **Use Case responsible for fetching and managing currency exchange rates**
class GetCurrenciesUseCase: GetCurrenciesUseCaseProtocol {
    let remoteRepository: RemoteCurrenciesRepositoryProtocol
    let storeRepository: StoreCurrenciesRepositoryProtocol
    private var latestRates: [Rate] = []

    init(remoteRepository: RemoteCurrenciesRepositoryProtocol, storeRepository: StoreCurrenciesRepositoryProtocol) {
        self.remoteRepository = remoteRepository
        self.storeRepository = storeRepository
    }

    // MARK: - Fetch Latest Exchange Rates
    func getLatestCurrencies() async throws -> [Rate] {
        let currentTimeStamp = Date().timeIntervalSince1970

        do {
            let lastFetchTime = try await storeRepository.getLastFetchTime()
            if isFetchNeeded(lastFetchTime: lastFetchTime, currentTimeStamp: currentTimeStamp) {
                let rates = try await fetchFromRemoteAndUpdateStore(currentTimeStamp: currentTimeStamp)
                latestRates = rates
                return rates
            } else {
                let rates = try await fetchFromLocal()
                latestRates = rates
                return rates
            }
        } catch {
            throw GetCurrenciesUseCaseError.FailedToGetCurrencies
        }
    }

    // MARK: - Retrieve Sorted Currency List
    /// Provides an alphabetically sorted list of currency codes
    func getSortedCurrencyList() async throws -> [String] {
        if latestRates.isEmpty {
            latestRates = try await getLatestCurrencies() // Ensures data is up to date
        }
        return latestRates.map { $0.currency }.sorted()
    }
}

// MARK: - Private Helper Methods
extension GetCurrenciesUseCase {
    
    // MARK: - Check if Fetching is Needed
    /// Determines if a new currency fetch is required based on the last fetch time
    private func isFetchNeeded(lastFetchTime: TimeInterval, currentTimeStamp: TimeInterval) -> Bool {
        return (currentTimeStamp - lastFetchTime) > 1800 // Refresh if more than 30 minutes (1800 seconds) have passed
    }

    // MARK: - Fetch from Remote and Update Local Storage
    /// Retrieves exchange rates from the remote API and updates local storage
    private func fetchFromRemoteAndUpdateStore(currentTimeStamp: TimeInterval) async throws -> [Rate] {
        let getCurrenciesResult = await remoteRepository.getCurrencies()

        switch getCurrenciesResult {
        case .success(let ratesDTO):
            do {
                try await storeRepository.saveLastFetchTime(timeStamp: currentTimeStamp)
                try await storeRepository.saveCurrencies(ratesDTO)
                return ratesDTO.domainModels
            } catch {
                throw GetCurrenciesUseCaseError.FailedToSaveCurrencies
            }

        case .failure:
            throw GetCurrenciesUseCaseError.FailedToGetCurrencies
        }
    }

    // MARK: - Fetch from Local Storage
    /// Retrieves exchange rates from local storage if available
    private func fetchFromLocal() async throws -> [Rate] {
        do {
            let ratesDTO = try await storeRepository.getCurrencies()
            return ratesDTO.domainModels
        } catch {
            throw GetCurrenciesUseCaseError.FailedToGetCurrencies
        }
    }
}
