//
//  StoreCurrenciesRepository.swift
//  PaypayChallenge
//
//  Created by Chung Han Hsin on 2025/2/15.
//

import Foundation
import RHCacheStoreAPI

/// Errors related to the storage of currency exchange data
enum StoreCurrenciesRepositoryError: Error {
    // Errors related to last fetch time
    case FailedSaveLastFetchTime
    case FailedGetLastFetchTime
    
    // Errors related to currency data
    case FailedSaveCurrencies
    case FailedGetCurrencies
    case CannotFindCurrencies
}

/// Protocol for storing and retrieving currency exchange data
protocol StoreCurrenciesRepositoryProtocol {
    func saveLastFetchTime(timeStamp: TimeInterval) async throws
    func getLastFetchTime() async throws -> TimeInterval
    func saveCurrencies(_ rates: RatesDTO) async throws
    func getCurrencies() async throws -> RatesDTO
}

class StoreCurrenciesRepository: StoreCurrenciesRepositoryProtocol {
    private let store: RHActorCacheStoreAPIProtocol
    private let lastFetchTimeKey = "last_fetch_time"
    private let currenciesKey = "currencies"

    init(store: RHActorCacheStoreAPIProtocol) {
        self.store = store
    }

    // MARK: - Save Last Fetch Time
    /// Saves the last fetch timestamp to the storage
    func saveLastFetchTime(timeStamp: TimeInterval) async throws {
        do {
            try await store.insert(with: lastFetchTimeKey, json: "\(timeStamp)")
        } catch {
            throw StoreCurrenciesRepositoryError.FailedSaveLastFetchTime
        }
    }

    // MARK: - Retrieve Last Fetch Time
    /// Retrieves the last fetch timestamp from the storage
    func getLastFetchTime() async throws -> TimeInterval {
        let result = await store.retrieve(with: lastFetchTimeKey)
        switch result {
        case .empty:
            return TimeInterval.leastNormalMagnitude // Returns the smallest possible timestamp to force an update
        case let .found(json):
            guard let timeString = json as? String, let time = Double(timeString) else {
                throw StoreCurrenciesRepositoryError.FailedGetLastFetchTime
            }
            return time
        case .failure:
            throw StoreCurrenciesRepositoryError.FailedGetLastFetchTime
        }
    }

    // MARK: - Save Currency Data
    /// Saves currency exchange data to the storage
    func saveCurrencies(_ rates: RatesDTO) async throws {
        do {
            let jsonData = try JSONEncoder().encode(rates)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw StoreCurrenciesRepositoryError.FailedSaveCurrencies
            }
            try await store.insert(with: currenciesKey, json: jsonString)
        } catch {
            throw StoreCurrenciesRepositoryError.FailedSaveCurrencies
        }
    }

    // MARK: - Retrieve Currency Data
    /// Retrieves currency exchange data from the storage
    func getCurrencies() async throws -> RatesDTO {
        let result = await store.retrieve(with: currenciesKey)
        
        switch result {
        case .empty:
            throw StoreCurrenciesRepositoryError.CannotFindCurrencies
        case let .found(json):
            return try await parseRates(from: json)
        case .failure:
            throw StoreCurrenciesRepositoryError.FailedGetCurrencies
        }
    }
}

// MARK: - Private Helpers
extension StoreCurrenciesRepository {
    
    // MARK: - Parse Currency Data
    /// Parses the retrieved currency exchange data into `RatesDTO`
    private func parseRates(from json: Any) async throws -> RatesDTO {
        let jsonData: Data
        
        if let jsonString = json as? String {
            guard let data = jsonString.data(using: .utf8) else {
                throw StoreCurrenciesRepositoryError.FailedGetCurrencies
            }
            jsonData = data
        } else if let jsonDict = json as? [String: Any] {
            jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
        } else {
            throw StoreCurrenciesRepositoryError.FailedGetCurrencies
        }

        return try JSONDecoder().decode(RatesDTO.self, from: jsonData)
    }
}
