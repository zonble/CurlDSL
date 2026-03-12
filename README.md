# CurlDSL

2019 © Weizhong Yang a.k.a zonble

[![Actions Status](https://github.com/zonble/CurlDSL/workflows/Build/badge.svg)](https://github.com/zonble/CurlDSL/actions)

CurlDSL converts cURL commands into `URLRequest` objects. This Swift package makes it easier to build HTTP clients in your iOS, macOS, or tvOS apps, especially when working with web API endpoints that provide cURL examples.

CurlDSL does not embed the cURL library into your project, nor is it a Swift code generator. Instead, it acts as a simple interpreter that parses and executes your cURL commands at runtime.

This project was inspired by [cURL as DSL](https://github.com/shibukawa/curl_as_dsl) by [Yoshiki Shibukawa](https://github.com/shibukawa).

Currently, CurlDSL only supports HTTP and HTTPS.

## Requirements

- Swift 5.9 or above
- iOS 13 or above
- macOS 10.15 or above
- tvOS 13 or above

## Installation

You can install this package via the [Swift Package Manager](https://swift.org/package-manager/).

## Usage

The primary object you will interact with is `CURL`. Simply pass your cURL command to its initializer. For example:

``` swift
try CURL("curl -X GET https://httpbin.org/json")
```

You can use it to construct `URLRequest` objects:

``` swift
let request = try? CURL("curl -X GET https://httpbin.org/json").buildRequest()
```

Or just execute the data task directly:

``` swift
try CURL("https://httpbin.org/json").run { data, response, error in
    // Do what you like...
}
```

### Multiline cURL Commands

CurlDSL supports multiline cURL commands that use line continuation characters (`\`). This is particularly useful when copying commands directly from documentation or API tools:

``` swift
let multilineCurl = """
curl -X POST \\
https://api.example.com/oauth/token \\
-F client_id=12345 \\
-F client_secret=secret \\
-F grant_type=authorization_code
"""

let request = try? CURL(multilineCurl).buildRequest()
```

The library automatically handles line continuation characters by removing them and joining the lines correctly.

## Supported Options

CurlDSL does not support all cURL options. The currently supported options include:

``` text
   -d, --data=DATA                         HTTP POST data (H)
   -F, --form=KEY=VALUE                    Specify HTTP multipart POST data (H)
       --form-string=KEY=VALUE             Specify HTTP multipart POST data (H)
   -H, --header=LINE                       Pass custom header LINE to server (H)
   -e, --referer=                          Referer URL (H)
   -X, --request=COMMAND                   Specify request command to use
       --url=URL                           URL to work with
   -u, --user=USER[:PASSWORD]              Server user and password
   -A, --user-agent=STRING                 User-Agent to send to server (H)
```

## Built-in Response Handlers

This package includes several built-in response handlers:

- `JsonDictionaryHandler`: Decodes fetched JSON data into a dictionary.
- `CodableHandler`: Decodes fetched JSON data into `Codable` objects.
- `DataHandler`: Simply returns raw data.

## License

This package is released under the MIT License.

Pull requests are welcome.

Enjoy!
