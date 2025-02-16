# iOS Currency Converter




## Summary

This iOS application demonstrates a production-ready currency converter implementing Clean Architecture with MVVM pattern. It features real-time currency conversion using Open Exchange Rates API, offline support through local caching, and comprehensive unit testing. The project showcases modern iOS development practices including:

- Clean Architecture with clear separation of concerns
- Async/await for concurrent operations
- Actor-based thread-safe storage
- Comprehensive error handling
- Extensive unit and integration testing
- Protocol-oriented design
- SOLID principles implementation
## Demo Video
<div align="center">

[🎥 Demo Video](https://github.com/user-attachments/assets/e0377895-6a21-4336-be1d-8334889036a0)

</div>
## Features

- Real-time currency conversion
- Offline mode support
- Automatic rate updates
- Support for all major world currencies
- Clean and intuitive UI




## Dependencies

- SnapKit: UI layout
- RHNetworkAPI: Network operations
- RHCacheStoreAPI: Local data persistence

4. Build and run the project in Xcode

## High Level Design

View the project's architecture UML diagram [here](https://drive.google.com/file/d/1FGVZyZtkKEIaoSBAPlK3JT1ezQgKrGJs/view?usp=sharing).

This diagram illustrates the overall architecture and component interactions in the application, demonstrating the Clean Architecture implementation and data flow.

## Architecture

The project follows Clean Architecture principles with MVVM pattern:

### Data Layer
- `RemoteCurrenciesRepository`: Manages API interactions
- `StoreCurrenciesRepository`: Handles local data persistence
- Data models: `RatesDTO`

### Domain Layer
- `GetCurrenciesUseCase`: Currency data retrieval
- `ConvertCurrencyUseCase`: Currency conversion logic
- Domain models: `Rate`

### Presentation Layer
- `ConverterViewModel`: UI state management
- `ConverterViewController`: UI rendering

## Testing

The project includes comprehensive unit tests and end-to-end tests:

### Unit Tests
- `ConvertCurrencyUseCaseTests`: 82.9% coverage
- `GetCurrenciesUseCaseTests`: 81.0% coverage
- `ConverterViewModelTests`: 90.3% coverage

### Code Coverage Details
```
Overall Coverage:              78.8%
SceneDelegate.swift          100.0%
AppDelegate.swift            100.0%
RatesDTO.swift               100.0%
RemoteCurrenciesRepository    96.2%
ConverterViewModel            90.3%
GetCurrenciesUseCase         81.0%
ConverterViewController       75.7%
StoreCurrenciesRepository     84.6%
ConvertCurrencyUseCase       82.9%
```

### End-to-End Tests
- `LocalEndToEndTests`
- `RemoteEndToEndTests`

Run tests using:
```bash
⌘ + U
```

## Key Features Implementation

### Currency Conversion
```swift
func convert(_ fromCurrency: String, toCurrency: String, withAmount amount: Float) throws -> Float
```
Handles both direct and indirect currency conversions.

### Offline Support
```swift
func getCurrencies() async throws -> RatesDTO
```
Manages local data persistence with 30-minute refresh policy.

### Rate Updates
```swift
func getLatestCurrencies() async throws -> [Rate]
```
Implements automatic rate updates with rate limiting.

## Usage Example

```swift
// Initialize the converter
let viewModel = ConverterViewModel(
    getCurrenciesUseCase: getCurrenciesUseCase,
    convertCurrencyUseCase: convertCurrencyUseCase
)

// Convert currency
await viewModel.doConvertProcess(
    fromCurrency: "USD",
    toCurrency: "EUR",
    amount: 100.0
)
```

## Error Handling

The app implements comprehensive error handling:

```swift
enum ConverterViewModelError: Error {
    case unableToConvert(fromCurrency: String, toCurrency: String)
    case failedToFetchRates
    case unknownError
}
```

## Technical Details

### Rate Limiting
- API calls are limited to once per 30 minutes
- Local cache is used between updates

### Offline Mode
- All conversion rates are cached locally
- Automatic fallback to cached data when offline

### Thread Safety
- Uses Swift actors for thread-safe storage
- Implements async/await for concurrent operations

## Project Structure

```
CurrencyConverter/
├── Data/
│   ├── Repositories/
│   └── Models/
├── Domain/
│   ├── UseCases/
│   └── Entities/
├── Presentation/
│   ├── ViewModels/
│   └── Views/
└── Tests/
    ├── UseCaseTests/
    ├── ViewModelTests/
    └── EndToEndTests/
```
