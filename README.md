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

let paxController = Pax() //the main controller
let left = storyboard.instantiateViewController(withIdentifier: "left") //the left menu
let right = UIViewController() //the right menu

let center = storyboard.instantiateViewController(withIdentifier: "navigationController") //center controller

left.pax.menuWidth = UIScreen.main.bounds.width * 0.8 //custom widths for both left and right controllers
right.pax.menuWidth = UIScreen.main.bounds.width * 0.6
paxController.leftViewController = left
paxController.rightViewController = right
paxController.setMainViewController(center) //Animatable if needed

```
