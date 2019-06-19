# DadKit

The complete [documentation](https://nathanhosselton.github.io/DadKit/) for the public APIs of the `DadKit` framework which backs the [Raid Dad](https://raiddad.com) iOS app.

## Carthage

```ruby
github "nathanhosselton/DadKit" ~> 0.8
```

Update and build with carthage then add the frameworks to the Xcode project.

## Configuring Project

`import DadKit` and ensure `Bungie.key`, `Bungie.appId`, and `Bungie.appVersion` are set before executing any requests.

#  Making Requests

DadKit uses [PromiseKit](https://promisekit.org) to return a `Promise` from each API request instead of taking a completion handler. For instance:

```swift
import PromiseKit
import DadKit

firstly {
    Bungie.searchForClan(named: "Meow Pew Pew")
}.then { clan in
    Bungie.getMembers(in: clan)
}.done { members in
    //e.g. display the members in a list
}.catch { error in
    //handle or display any error that may occur throughout the chain
}
```
