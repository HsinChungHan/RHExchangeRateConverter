//
//  Rates.swift
//  PaypayChallenge
//
//  Created by Chung Han Hsin on 2025/2/15.
//

import Foundation

struct RatesDTO: Codable, Equatable {
    let rates: [String: Float]
    
    var domainModels: [Rate] {
        rates.map { .init(currency: $0.key, rate: $0.value) }
    }
}
