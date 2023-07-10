# ChefTime
<img src="GitAssets/ChefTime_Banner_01.svg" alt="drawing" width="650"/>

ChefTime is the cookbook app for the enthusiast. 
- `Build your cookbook`: Create and manage recipes and folders with ease.
- `Real-time sharing`: Share your recipes and folders with other users and recieve updates in realtime.
- `Effortless navigation`: Enjoy an intuitive user interface for easy app exploration.
- `Powerful search`: Find recipes and folders quickly with a robust search feature.
- `Offline capabilities`: Access the full app functionality even without an internet connection.
- `Data persistence`: Your offline changes are saved and synchronized once you're back online.

Please note that ChefTime is currently in development.

# About
ChefTime is built entirely in SwiftUI and powered by a few incredibly powerful libraries:
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) 
- [Swift-Tagged](https://github.com/pointfreeco/swift-tagged)
- [Swift-URL-Routing](https://github.com/pointfreeco/swift-url-routing)
- [CoreData](https://developer.apple.com/documentation/coredata)

These libraries unleash a wizard-like app development experience and the ability to create user experiences that were extremely difficult to engineer or even impossible. The following are brief overviews of the significance of each library.

# The Composable Architecture (TCA)
TCA is a state-management library for SwiftUI with an opionated philosophy on managing state. TCA describes an app as one big feature composed of many other features, which themeselves, may be composed of many other features. TCA then describes a feature as a UI delivering a UX, or in other words, a view reflecting state that is somehow mutated, through the UI or internally. 

Thus we are left with the core of TCA, which describes how one should state manage a feature, which is quintessentially architected by a trinity of units:
1. `View`: Describes the UI of a feature, which may display some state of a feature, which is read-only, but may send actions to a Store which then runs a Reducer to mutate that state.
2. `Store`: Describes the runtime object of a feature, which provides observable read-only state but may mutate that state by recieving actions which are executed by a reducer that operates on its current state and the recieved action.
3. `Reducer`: Describes all buisiness logic of a feature, as a function of taking a mutable state (value type) and an action (enum), and executing logic corresponding to that specific action. At the completion of the given action, an effect must be returned, such as no effect at all, another action, or an asynchronous stream of actions, which are fed to the store to be scheduled and executed. Reducers can even run other reducers on its own state (composition), and even recieving actions from those reducers to perform even more logic (similar to a callback)

**(PUT CODE HERE TO DEMO TCA)**

This is barely scratching the surface, but at essence what TCA does. The results are a sublime developement experience for writing apps with a host of amazing benefits:
- `State and Mutation - Single Source of Truth`: All state and its mutation (business logic) for a feature reside in a reducer, meaning view code with zero buisiness logic, thus testable logic, and easy to find mutation with enumerated actions that desribe a UI action or state mutation, and state value type semantics **(PUT CODE HERE>)**
- `Effects - Automated Async Lifecycle Management`: Perform asynchronous logic while TCA manages asynchronous contexts, lifecycles, cancellability, child feature logic, for the lifetime of the feature, meaning you don't have to get your hands dirty with managing complex edge-case asynchronous lifecycles for your feature **(PUT CODE HERE>)**
- `Dependencies - No Compromise`: Inject global dependencies across any layer of your app easily and with the ability to handle live, preview, and test versions, meaning dependencies don't control you but you control them 
- `Composition - Light Speed Development`: Compose features with reducer builders and operators with SwiftUI like syntax to glue features together in as little as one line of code. **(PUT CODE HERE)**
- `Testing - Exhaustive and Amazing Async Testing`: Test all state mutation, forced by default to exhaustively describe the mutation of state overtime. Simply send an action to the store, describe the new state, recieve any possible actions sent back into the system and describe that new state, until no new actions are triggered and all effects have completed. **(PUT CODE HERE>)**

# Tagged
Tagged is a simple library used in this application to wrap the Identifiable id property to elicit type safe ids. The id of a recipe should be a separate type than the id of an about section, or settings. This simple wrapper has been instrumental in preventing small bugs such as that.

# Swift-URL-Routing
WIP

# Persistence 
WIP

# Inspiration
This app was heavily inspired by [PointFree](https://www.pointfree.co) and Apple's Notes app. 

PointFree is an incredible video series exploring functional programming and SwiftUI, and has perhaps been my biggest teacher and what keeps me super excited about development. 

Apple's Notes app is probably my favorite and most useful app, that I actually use every single day. I love the app and wanted to create something similar, but fine-tuned to be a cookbook.

# Contact
TBD

