# CurlDSL

CurlDSL converts curl commands into `URLRequest` objects. The Swift package
helps you to build HTTP clients in your iOS/macOS/tvOS easier, once you have a
curl command example for a Web API endpoint.

## Requirement

- Swift 5
- iOS 13
- macOS 10.15
- tvOS 13

## Installation

You can install the package via Swift Package Manager.

## Usage

There is only one important object, `CURL`. You can just pass your curl command
to it. For example:

``` swift
try CURL("curl -X GET https://httpbin.org/json")
```

You can use it to build `URLRequest` objects.

``` swift
let request = try? CURL("curl -X GET https://httpbin.org/json").buildRequest()
```

Or jsut run the data task:

``` swift
try CURL("https://httpbin.org/json").run { data, response, error in 
    /// Do what you like...
}
```

