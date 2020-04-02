# Pax

Pax is a  `UIViewController` managing a central "main" content and one or two "side" menus from either (or both) left and right side of the screen.

It's designed to be single-file, lightweight and easy to use.

![gif](images/pax.gif)

## Key features

- Left and/or right menu with both pan gesture and open/close animations
- Custom transition for central (main) view controller during animations and interactions
- Compatible with storyboards and xibs
- Custom widths for side menus
- Single file design: integrate with package managers or simply drag and drop `Pax.swift` in your project
- Proxy design for `UIViewController` extensions: interact with Pax related features through the `.pax` proxy accessor

## Installation

Pax is available through Cocoapods and Swift Package Manager.

#### Cocoapods

Add this to your Podfile

```ruby
pod 'Pax'
```
and run 
```bash
pod install
```

#### Manual installation

Since it's not unlikely that your project may need some "tweak" to fully match your design needs, we designed Pax to be a "single file library". 
Simply drag the `Pax.swift` in your project and your good to go!

## Usage

`Pax` is a `UIViewController` open subclass.

The stucture is made by: 

- A central `UIViewController` with your main contents, the **main controller**
- A left and/or right `UIViewController` with your side menus, the **left/right controllers**
- A `shadowView` between main and side controllers that fades its opacity between 0 (side menu closed) and max value (<1) when one of the side controllers is open.

Only one side controller can be opened at a time. When a side controller is opened, the whole screen area handles a pan gesture to interact with the controller and close it.

When side controllers are closed, you can open them either by sliding from the side edge of the screen or by calling `.showViewController(at: .left, animated: true)` or  `.showViewController(at: .right, animated: true)` on the pax controller itself.

To retrieve the pax controller instance from any viewController, you can use
```swift
let pax: Pax? = self.pax.controller
```

Usually you don't have to deal with `Pax` controller hierarchy directly.

You can instantiate a `Pax` directly from code: `let paxController = Pax()`

If you want to use it directly in a storyboard, you can subclass it and override it's `viewDidLoad`.

To set the main controller, use

```swift
let mainController = ... //a reference to your view controller
paxController.setMainViewController(mainController, animated: true)
```
The `animated` property set to `true` fades from old to new controller.

To set left or right view controller use

```swift
let leftController = ... //a reference to your left view controller
paxController.setViewController(leftController, at: .left) //or .right
```

Setting a side controller doesn't immediately open it. To show or hide them (from any viewController inside the `Pax` hierarchy), use
```swift
pax.controller?.showViewController(at: .left, animated: true)
pax.controller?.hideViewController(at: .left, animated: true)
```

## Simple example

```swift

let storyboard = UIStoryboard(name: "Main", bundle: nil)
let paxController = Pax()
//A storyboard-instantiated view controller for left side
let left = storyboard.instantiateViewController(withIdentifier: "left")
left.view.backgroundColor = .yellow
//A code-instantiated green view controller for right side
let right = UIViewController()
right.view.backgroundColor = .green
//Main "center" view controller
let center = storyboard.instantiateViewController(withIdentifier: "navigationController")

//CustomWidth for both left and right side menus
left.pax.menuWidth = UIScreen.main.bounds.width * 0.8
right.pax.menuWidth = UIScreen.main.bounds.width * 0.6
paxController.setViewController(left, at: .left)
paxController.setViewController(right, at: .right)
paxController.setMainViewController(center)

```

## Why Pax?

Let's start by saying that, nowadays, a side menu is probably not the best choice to display a navigation menu, as it's been proven through analytics to actually *hide* features from the users of your app.

However, there are cases where the "side" part of the screen is the only logical place for some features (like the 2020 Slack app, just to name a famous one).

We decided to go with our own implementation because we couldn't find any side controller that could clearly fit our needs ("double" menu on both sides, or only on the right side rather than the left one).
We also know that our implementation, probably, won't fit other's needs, and this is why we decided to use a "single file approach": if Pax is close to your needs, but slightly different in some bits, it should be easy to integrate its sources (a single file) in your project and tweak it as you please. It's just ~500 LOC.

We chose the *Pax* name by mistake. On Android, this kind of menus are called *drawers*, and we mistakenly translated it into *wardrobe*. The most famous swedish wardrobe in the world is called Pax, hence the name. Fortunately, those wardrobes comes with two sliding doors, and that kind of sliding movement is quite similar to our menus... :)

