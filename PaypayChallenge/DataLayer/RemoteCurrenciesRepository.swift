//
//  RemoteCurrenciesRepository.swift
//  PaypayChallenge
//
//  Created by Chung Han Hsin on 2025/2/15.
//

import Foundation
import RHNetworkAPI

enum RemoteCurrenciesRepositoryError: Error {
    case FailedToGetLatestCurrencies
}

protocol RemoteCurrenciesRepositoryProtocol {
    func getCurrencies() async -> Result<RatesDTO, RemoteCurrenciesRepositoryError>
}

class RemoteCurrenciesRepository: RemoteCurrenciesRepositoryProtocol {
    let appID = "0d7ba7c95d104608b51a89488ad10c36"
    let client: RHNetworkAPIProtocol
    init(client: RHNetworkAPIProtocol) {
        self.client = client
    }

    func getCurrencies() async -> Result<RatesDTO, RemoteCurrenciesRepositoryError> {
        let path = "latest.json"
        let queryItems = [URLQueryItem(name: "app_id", value: appID)]

        return await withCheckedContinuation { continuation in
            client.get(path: path, queryItems: queryItems) { result in
                switch result {
                case let .success(data, _):
                    do {
                        let dto = try JSONDecoder().decode(RatesDTO.self, from: data)
                        continuation.resume(returning: .success(dto))
                    } catch {
                        continuation.resume(returning: .failure(.FailedToGetLatestCurrencies))
                    }
                case .failure:
                    continuation.resume(returning: .failure(.FailedToGetLatestCurrencies))
                }
            }
        }
    }
}
