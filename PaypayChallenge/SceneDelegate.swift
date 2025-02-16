//
//  SceneDelegate.swift
//  PaypayChallenge
//
//  Created by Chung Han Hsin on 2025/2/15.
//

import UIKit
import RHNetworkAPI
import RHCacheStoreAPI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
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

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: rootViewController) // 包裝在 NavigationController 中
        self.window = window
        window.makeKeyAndVisible()
    }
}

