# NetWatch
A small Swift package that enables network requests logging.

## Installation
The package can be simply dragged-and-dropped into the `NewsBlur` project in Xcode.

### Instantiation
In `NewsBlurAppDelegate` import the package using:
```
@import NetWatch;
```

In `application:didFinishLaunchingWithOptions:` add call to `configure` static method. Example: 
```
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [NetWatch configure];
    ...

    return YES;
}
```
