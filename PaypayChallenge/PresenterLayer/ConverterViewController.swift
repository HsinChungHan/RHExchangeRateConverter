//
//  ConverterViewController.swift
//  PaypayChallenge
//
//  Created by Chung Han Hsin on 2025/2/16.
//

import UIKit
import SnapKit

class ConverterViewController: UIViewController {

    private let viewModel: ConverterViewModel

    // MARK: - UI Components
    lazy var amountTextField = makeAmountTextField()
    lazy var currencyPicker = makeCurrencyPicker()
    lazy var conversionCollectionView = makeConversionCollectionView()
    lazy var activityIndicator = makeActivityIndicator()

    private var conversionResults: [(String, Float)] = []

    init(viewModel: ConverterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        Task { await viewModel.fetchLatestCurrencies() }
    }

    // MARK: - Actions
    @objc private func amountTextFieldDidChange() {
        viewModel.updateConversionResults(amountText: amountTextField.text ?? "")
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedCurrency = viewModel.currencyList[row]
        viewModel.setSelectedCurrency(selectedCurrency)
        amountTextFieldDidChange() // Recalculate conversion when currency is changed
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        amountTextField.resignFirstResponder() // Hide keyboard when scrolling
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Private Helpers
extension ConverterViewController {
    private func setupBindings() {
        // Update UI when conversion results are updated
        viewModel.convertedResultsHandler = { [weak self] results in
            DispatchQueue.main.async {
                self?.conversionResults = results
                self?.conversionCollectionView.reloadData()
            }
        }

        // Update UI when a single currency conversion is triggered
        viewModel.convertedAmountHandler = { [weak self] convertedAmount in
            DispatchQueue.main.async {
                self?.conversionResults = [(self?.viewModel.selectedCurrency ?? "USD", convertedAmount)]
                self?.conversionCollectionView.reloadData()
            }
        }

        // Error handling
        viewModel.errorHandler = { [weak self] error in
            DispatchQueue.main.async { self?.showErrorAlert(message: error) }
        }

        // Handle loading state
        viewModel.isLoadingHandler = { [weak self] isLoading in
            DispatchQueue.main.async {
                isLoading ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
            }
        }
        
        // Reload picker view when currency list is updated
        viewModel.currencyListUpdatedHandler = { [weak self] selectedCurrencyIndex in
            DispatchQueue.main.async {
                self?.currencyPicker.reloadAllComponents()  // Reload picker view
                self?.currencyPicker.selectRow(selectedCurrencyIndex, inComponent: 0, animated: false)  // Set default currency
            }
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(amountTextField)
        view.addSubview(currencyPicker)
        view.addSubview(conversionCollectionView)
        view.addSubview(activityIndicator)

        amountTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        currencyPicker.snp.makeConstraints { make in
            make.top.equalTo(amountTextField.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(150)
            make.height.equalTo(100)
        }

        conversionCollectionView.snp.makeConstraints { make in
            make.top.equalTo(currencyPicker.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview().inset(20)
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        currencyPicker.delegate = self
        currencyPicker.dataSource = self
        conversionCollectionView.delegate = self
        conversionCollectionView.dataSource = self

        amountTextField.addTarget(self, action: #selector(amountTextFieldDidChange), for: .editingChanged)
    }
}


// MARK: - UIPickerView Delegate & DataSource
extension ConverterViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.currencyList.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel.currencyList[row]
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension ConverterViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return conversionResults.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ConversionCell", for: indexPath) as! ConversionCell
        let result = conversionResults[indexPath.row]
        cell.configure(currency: result.0, amount: result.1)
        return cell
    }
}

// MARK: - Factory methods
extension ConverterViewController {
    private func makeAmountTextField() -> UITextField {
        let textField = UITextField()
        textField.placeholder = "Enter amount"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        textField.textAlignment = .center
        return textField
    }

    private func makeCurrencyPicker() -> UIPickerView {
        return UIPickerView()
    }

    private func makeConversionCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 100, height: 100)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ConversionCell.self, forCellWithReuseIdentifier: "ConversionCell")
        return collectionView
    }

    private func makeActivityIndicator() -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }
}
