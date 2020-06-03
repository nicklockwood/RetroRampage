Create a new Target for the tvOS app.

• File > New > Target
• tvOS > Application > Single View App

Name it "RampageTV", use Storyboard Interface to be consistent with the existing project.

The first issue is that all the Assets (images and sounds) are in the original iOS app. So let's create a new Folder in the project so that we can move the "shared resources" into it.

Select the blue project file in the file explorer, then: File > New > Group and call it "Shared".
 
Now you can drag the Assets.xcassets and Sounds folder to the "Shared" folder.
Rename the Assets.xcassets to "SharedAssets.xcassets".

In the Rampage folder, create a new Assets.xcassets file, alt click it so you get both asset catalogues side by side, then drag the "AppIcon" from the SharedAssets to the Assets catalogue. This is because the AppIcon is only relevant to iOS apps, not tvOS apps. You could have just right clicked inside the Assets catalogue and created a new set of app icons, but your choice.
Select the SharedAssets catalogue again, open the menu on the right hand side of the screen and go to the first tab in order to find the list of Targets that the file is a member of. Put a checkmark next to "Rampage" and "RampageTV" so that the catalogue will be compiled into both projects.

Expand the Sounds folder, select all the files inside and do the same to add them all to both project targets.

Compile both projects to make sure they work correctly.

In the build settings for the "Engine" and "Renderer" targets, select "Other..." for the Support Platforms option, then manually add "appletvos" and "appletvsimulator" lines below "iphoneos" and "iphonesimulator". This will allow the same frameworks to be used for both iOS and tvOS.

In the RampageTV folder, delete the file ViewController.swift

Move the following files from "Rampage" into "Shared":
UIImage+Bitmap, SoundManager, GameControllerManager, GameControllerManager+Input, Levels.json, ViewController

Make sure all those files are in both the "Rampage" and "RampageTV" targets.

Navigate to the RampageTV target settings. Find the "Signing & Capabilities", add the "Game Controllers" capability and enable support for "Extended controllers". Micro gamepads suck so I won't be implementing that.

Filling every pixel of a 4K TV is too slow for the software renderer, so you need to cap the bitmap size. In "ViewController.swift" find 

```swift
let width = Int(imageView.bounds.width), height = Int(imageView.bounds.height)
```

and replace it with

```swift
let maxHeight = 480
let height = min(maxHeight, Int(imageView.bounds.height))
let aspectRatio = imageView.bounds.width / imageView.bounds.height
let width = Int(CGFloat(height) * aspectRatio)
```
