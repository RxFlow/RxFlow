# RxFlow
RxFlow is a simple, fluent, reactive and minimalistic HTTP Library. The most common HTTP verbs are supported `(GET, PUT, POST, DELETE, OPTIONS, HEAD, PATCH)`. If you want, it's easy to set default headers and use a custom `NSURLSession` for all requests.

## Components
- `RxFlow` - Factory class for creating `Target` instances. Accepts default headers and custom `NSURLSession`if needed.
- `Target`- Builder class for creating a request. This class makes it easy to set headers, request parameters, request payload and response parser as needed. All HTTP methods use a sensible default parser if no parser is set. The returned request is an `Observable`.

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
### POST request with default UTF8StringParser response parser
```swift
let payload = // payload as NSData
RxFlow().target("some_url").post(payload).subscribeNext { result, headers in
    // result as a String
}
```
### POST request with custom response parser
```swift
let payload = // payload as NSData
let workoutParser: (NSData) -> (Workout) = // 
RxFlow().target("some_url")
        .post(payload, parser: workoutParser)
        .subscribeNext { workout, headers in
            // handle workout and headers
        }
```



