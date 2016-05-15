[![Build Status](http://img.shields.io/travis/onekiloparsec/KPCSplitPanes.svg?style=flat)](https://travis-ci.org/onekiloparsec/KPCSplitPanes)
![Version](https://img.shields.io/cocoapods/v/KPCSplitPanes.svg?style=flat)
![License](https://img.shields.io/cocoapods/l/KPCSplitPanes.svg?style=flat)
![Platform](https://img.shields.io/cocoapods/p/KPCSplitPanes.svg?style=flat)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)


KPCSplitPanes
==============

A set of classes, among which a subclass of NSSplitView, that splits when you're intented to make panes.
Horizontal and vertical panes can be combined.

![Demo JumpBar](http://www.onekilopars.ec/s/KPCSplitPanesDemo.gif)


Installation
------------

Using [Carthage](https://github.com/Carthage/Carthage): add `github "onekiloparsec/KPCSplitPanes"` to your `Cartfile` and then run `carthage update`.

Using [CocoaPods](http://cocoapods.org/): `pod 'KPCSplitPanes'`


Usage
-----

KPCSplitPanes is a lot a work in progress right now. A demo is here to show how to use it. Basically, install
a `NSSplitView` in your xib/storyboard, declare it as a `PressureSplitView`, build a dedicated delegate, and assign
it to the split view.

The choice between horizontal and vertical split can be toggled by pressing `Alt` key.
 
**It is mandatory for the container view to not use AutoLayout.**
 
What is currently not perfect/working
* The automatic adjustment isn't working in all cases
* The position of the divider isn't always right
* The window can be resized whatever the split view constraints
* I'm sure there is something else...


Author
------

[Cédric Foellmi](https://github.com/onekiloparsec) ([@onekiloparsec](https://twitter.com/onekiloparsec))


LICENSE & NOTES
---------------

KPCSplitPanes is licensed under the MIT license and hosted on GitHub at https://github.com/onekiloparsec/KPCSplitPanes/
Fork the project and feel free to send pull requests with your changes!
