# RxFlow
RxFlow is a simple, fluent, reactive and minimalistic HTTP Library

## Usage
### GET request with default [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) parser
```swift
RxFlow().target("some_url").get().subscribeNext{ json, headers in
    // use json response
}
```
### GET request with custom parser
```swift
RxFlow().target("some_url").get { data in
	// parse and return result
}.subscribeNext { result, headers in
    // use parsed result
}
```
### GET request with error handling
```swift
RxFlow().target(getURL)
        .get().subscribe { event in
           switch event {
           case .Next(let result): // handle result
           case .Error(let error): // handle error
           case .Completed: // handle completion
           }
        }
```
### GET request with custom headers and query parameters
```swift
RxFlow().target("some_url")
        .header("auth_token", value:"1001")
        .parameter("sort", value:"desc")
        .get().subscribeNext{ json, headers in
            // use json response
        }
```
### GET request with retries
```swift
RxFLow().target("some_url", retries: 5).subscribeNext { json, headers in 
    // use json response
}
```
### GET request with retries and delay
```swift
RxFLow().target("some_url", retries: 5, delay: 1.0).subscribeNext { json, headers in 
    // use json response
}
```


