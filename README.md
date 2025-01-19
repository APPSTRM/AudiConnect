<div align=center>

# AudiConnect 

[![Build](https://github.com/APPSTRM/AudiConnect/actions/workflows/build.yml/badge.svg)](https://github.com/APPSTRM/AudiConnect/actions/workflows/build.yml)

</div>

This is an unofficial Swift Package for integrating Audi Connect Services. This package has been assembled using the [audiconnectpy](https://github.com/cyr-ius/audiconnectpy) package as basis. Credits to [@cyr-ius](https://github.com/cyr-ius) for the creation and maintenance of the python package.

You will require a My Audi account to be able to make use of this library.

## Is the API official?

Absolutely not. These endpoints are a result of reverse engineering Audi's web and mobile applications.


## Requirements

### Swift

Porsche Connect requires Swift 6.0 or higher. It uses the new async/await concurrency language features introduced in Swift 5.5.

### Supported Platforms

Currently the library supports the following platforms:

* **macOS** (Version 13+)
* **iOS** (Version 16+)

## Examples/Supported APIs

### Get Vehicles 

```swift
let audiConnect = AudiConnect(username: "username", password: "password", country: "GB", model: .standard)
let vehicles = try await audiConnect.getVehicles()
```

### Get Vehicle Information

```swift
let audiConnect = AudiConnect(username: "username", password: "password", country: "GB", model: .standard)
let vehicleInformation = try await audiConnect.getVehicleInformation(vin: "vehicle vin")
```

### Get Vehicle Status

```swift
let audiConnect = AudiConnect(username: "username", password: "password", country: "GB", model: .standard)
let vehicleStatus = try await audiConnect.getVehicleStatus(vin: "vehicle vin")
```

Note: Not all properties are currently being decoded, additions to the library are welcomed to add support for these.

## Still to be added

- Further APIs, vehicle control, feature parity with the python equivalent
- Refreshing tokens as required (currently tokens will expire and require re-authentication)

Contributions are very welcome, this library is certainly a minimal implementation built for certain requirements. 
