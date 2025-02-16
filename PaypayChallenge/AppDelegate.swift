//
//  AppDelegate.swift
//  PaypayChallenge
//
//  Created by Chung Han Hsin on 2025/2/15.
//

import UIKit
import RHNetworkAPI
import RHCacheStoreAPI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let networkFactory = RHNetworkAPIImplementationFactory()
        let domainURL = URL(string: "https://openexchangerates.org/api/")!
        let client = networkFactory.makeNonCacheAndNoneUploadProgressClient(with: domainURL)
        let storeFactory = RHCacheStoreAPIImplementationFactory()
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("currencies_info.txt")
        let sotre = storeFactory.makeActorCodableStore(with: fileURL)
        let getCurrenciesUseCase = GetCurrenciesUseCase(remoteRepository: RemoteCurrenciesRepository(client: client), storeRepository: StoreCurrenciesRepository(store: sotre))
        let convertCurrencyUseCase = ConvertCurrencyUseCase()
        let viewModel = ConverterViewModel(getCurrenciesUseCase: getCurrenciesUseCase, convertCurrencyUseCase: convertCurrencyUseCase)
        let rootViewController = ConverterViewController(viewModel: viewModel)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: rootViewController)
        window?.makeKeyAndVisible()
        return true
    }
}

