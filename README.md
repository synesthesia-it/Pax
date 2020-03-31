# Pax
iOS Drawer/SideMenu/HamburgerMenu

![gif](images/pax.gif)

## Key features

- Left and/or right menu with both pan gesture and open/close animations
- Custom transition for central (main) view controller during animations and interactions
- Compatible with storyboards and xibs
- Custom widths for side menus
- Single file design: integrate with package managers or simply drag and drop in your project

## Default Usage

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
