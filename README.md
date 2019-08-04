# CurlDSL

CurlDSL converts cURL commands into `URLRequest` objects. The Swift package
helps you to build HTTP clients in your iOS/macOS/tvOS easier, once you have a
cURL command example for a Web API endpoint.

CurlDSL is not a Swift code generator, but it parses and interprets your cURL
command at run time.

## Requirement

- Swift 5 or above
- iOS 13 or above
- macOS 10.15 or above
- tvOS 13 or above

## Installation

You can install the package via Swift Package Manager.

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

## Supported Options

We do not support all of options of cURL. The supported options are as the
following list.

``` text
   -d, --data=DATA                         HTTP POST data (H)
   -F, --form=KEY=VALUE                    Specify HTTP multipart POST data (H)
       --form-string=KEY=VALUE             Specify HTTP multipart POST data (H)
   -G, --get                               Send the -d data with a HTTP GET (H)
   -H, --header=LINE                       Pass custom header LINE to server (H)
   -e, --referer=                          Referer URL (H)
   -X, --request=COMMAND                   Specify request command to use
       --url=URL                           URL to work with
   -u, --user=USER[:PASSWORD]              Server user and password
   -A, --user-agent=STRING                 User-Agent to send to server (H)
```

Pull requests are welcome.

Enjoy!
