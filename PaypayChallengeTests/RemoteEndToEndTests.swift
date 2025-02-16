//
//  EndToEndTests.swift
//  PaypayChallengeTests
//
//  Created by Chung Han Hsin on 2025/2/15.
//

import XCTest
@testable import PaypayChallenge
@testable import RHNetworkAPI

final class PaypayChallengeTests: XCTestCase {
    func test_get_latest_currencies() async throws {
        let networkFactory = RHNetworkAPIImplementationFactory()
        let domainURL = URL(string: "https://openexchangerates.org/api/")!
        let client = networkFactory.makeNonCacheAndNoneUploadProgressClient(with: domainURL)
        let remoteCurrenciesRepository = RemoteCurrenciesRepository(client: client)

        let result = await remoteCurrenciesRepository.getCurrencies()
        
        switch result {
        case .success(let rates):
            XCTAssertNotNil(rates, "Should get rates successfully")
            print("rates: \(rates)")
        case .failure:
            XCTFail("API request failed")
        }
    }
}
