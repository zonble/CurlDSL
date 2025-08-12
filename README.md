# CurlDSL

2019 © Weizhong Yang a.k.a zonble

[![Actions Status](https://github.com/zonble/CurlDSL/workflows/Build/badge.svg)](https://github.com/zonble/CurlDSL/actions)

CurlDSL converts cURL commands into `URLRequest` objects. The Swift package
helps you to build HTTP clients in your iOS/macOS/tvOS easier, once you have a
cURL command example for a Web API endpoint.

CurlDSL does not embed cURL library into your project. It is also not a Swift
code generator, but it is a simple interpreter, it parses and interprets your
cURL command at run time.

The project is inspired by [cURL as DSL](https://github.com/shibukawa/curl_as_dsl)
by [Yoshiki Shibukawa](https://github.com/shibukawa).

CurlDSL supports only HTTP and HTTPS right now.

## Requirement

- Swift 5.1 or above
- iOS 13 or above
- macOS 10.15 or above
- tvOS 13 or above

## Installation

You can install the package via [Swift Package Manager](https://swift.org/package-manager/).

## Usage

There is only one important object, `CURL`. You can just pass your cURL command
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

### Multiline cURL Commands

CurlDSL supports multiline cURL commands with line continuation characters (`\`), which is useful when copying commands from documentation or tools:

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

The library automatically handles line continuation characters by removing them and joining the lines properly.

## Supported Options

We do not support all of options of cURL. The supported options are as the
following list.

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

The package has several built-in handlers:

- `JsonDictionaryHandler`: Decodes fetched JSON data into a dictionary.
- `CodableHandler`: Decodes fetched JSON data into Codable objects.
- `DataHandler`: Simply returns raw data.

## License

The package is released under MIT license.

Pull requests are welcome.

Enjoy!
