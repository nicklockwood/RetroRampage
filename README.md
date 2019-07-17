## Retro Rampage

*[English](https://github.com/nicklockwood/RetroRampage) ∙ [简体中文](https://github.com/nicklockwood/RetroRampage/tree/translations/zh-Hans)*

![Screenshot](Tutorial/Images/SortedSprites.png)

### 关于

Retro Rampage 是一系列的教程，可以让你学习到如何从零开始，用Swift语言制作一个类似《德军总部3D》游戏。 这个游戏可以运行在iPhone和iPad上，但引擎的部分可以在任何可运行Swift代码的平台运行。

《德军总部3D》这种基于网格的2.5D游戏，和当今的射击游戏相比，已经发生了很大变化。但我们在本教程中仍将它为范例，原因如下：

* 构建一个类《德军总部3D》的3D引擎，无需了解太多深奥的数学或GPU、着色器知识。

* 基于2D网格来创建和显示地图是很简单的，可以避免引入复杂的3D模型和动画工具。

* Tile网格是研究一些技术的绝佳原型，包括程序化地图生成、寻路和视线计算等，这些都可以应用到更加复杂的游戏中。

### 背景

1993年，我在一个朋友家中，用一台老旧的386 PC（Mac版本直到很多年后才发布）游玩了《德军总部3D》。自那之后，我就迷上了*第一人称射击游戏*。

作为一个有抱负的程序员，我想把看到的东西亲手创造出来。但在当时，仅靠中学数学知识和对BASIC语言的一点点了解，想要重新创造出一个当代PC上的顶尖3D游戏，是我根本无法企及的美梦。

20多年后的今天， 有一些事情已经发生了改变：

* 苹果给了我们（当然，卖给我们）iPhone —— 一台比DOS时代的桌面PC强劲数百倍的移动计算机。

* Chris Lattner给了我们Swift —— 一门简单，但是却非常强大的语言，可以用来编写应用或游戏。

* 约翰·卡马克 给了我们《德军总部3D》的源代码，并且其背后的魔法已被彻底揭开了面纱。

我想，现在就是最佳的时间了，开始实践那个让我在1/4个世纪里一直念念不忘的想法：创造一个FPS游戏！

### 教程

下面的一系列章节是被设计为按顺序学习的，并且每一个步骤的代码都基于前一个构建。如果你决定跳过一些，可在[此处](https://github.com/nicklockwood/RetroRampage/releases)获取每个步骤的代码。

这些教程在编写时假定你已经对Xcode有所了解，并且知道如何创建一个iOS项目并向其中添加文件。教程没有对Swift知识有要求，因此如果你只使用过Objective-C或类C语言，都是没问题的。

[Part 1 - 关注点分离](Tutorial/Part1.md)

不像大多数的应用，游戏是（或者说应该）高度独立于任何给定平台的。Swift已经被适配到了很多苹果生态系统之外的平台上，包括Android、Ubuntu、Windows，甚至树莓派。在第一个章节中，我们将看到如何配置我们的项目，最小化对iOS的依赖。同时为编写一个完全可移植的游戏引擎打下坚实的基础。

[Part 2 - 地图和动作](Tutorial/Part2.md)

如果不看名字的话，《德军总部3D》其实是一个投影到了3D空间中的2D游戏。这个游戏运行的机制和俯视角的2D射击游戏其实没什么两样，我们将会证明这一点：从2D俯视视角游戏为基础，逐步构建一个第一人称3D游戏。

[Part 3 - 光线投射](Tutorial/Part3.md)

在具备硬件加速功能的3D图形卡出现之前，我们这代的一些伟大程序员就已经开始制作令人惊叹的3D游戏——仅仅只依靠孱弱的16位处理器。我们将跟随他们的足迹，借助一门古老的游戏图形技巧——*光线投射*，把我们的游戏带到第三个纬度。

[Part 4 - 纹理映射](Tutorial/Part4.md)

在这一章节中，我们将使用*纹理映射*技术来修饰裸露的墙壁和地板。纹理映射是使用2D图片对3D对象进行绘图或*wall-papering*的过程，有助于为无特征的表面提供具备复杂细节的外观。

[Part 5 - 精灵(Sprites)](Tutorial/Part5.md)

是时候引入一些其他的角色，来让我们的角色联动起来了。我们将使用*精灵*技术——一种在当年很流行的技术，借助它，可以在当年那个没法实时渲染出带纹理的多边形模型的日子里，仍能给3D游戏添加引人入胜的内容。

未完待续

### 致谢

感谢 [Nat Brown](https://github.com/natbro) 和 [PJ Cook](https://github.com/pjcook) 在本教程的第一版草稿编写中提出的宝贵建议。

同样感谢 [Lode Vandevenne](https://github.com/lvandeve) 和 [Fabien Sanglard](https://github.com/fabiensanglard/), 我从未和他们真正说过话，但是他们关于光线投射和德军总部引擎的出色解释，是本教程的基础和灵感。

### 延伸阅读

如果你已经完成了这个教程，并且渴望学习更多的相关知识，这里提供了一些可能会对你有用的资源：

* [Lode's Raycasting Tutorial](https://lodev.org/cgtutor/raycasting.html#Introduction) - A great tutorial on ray casting, implemented in C++.
* [Game Engine Black Book: Wolfenstein 3D](https://www.amazon.co.uk/gp/product/1727646703/ref=as_li_tl?ie=UTF8&camp=1634&creative=6738&creativeASIN=1727646703&linkCode=as2&tag=charcoaldesig-21&linkId=aab5d43499c96f7417b7aa0a7b3e587d) - Fabien Sanglard's excellent book about the Wolfenstein 3D game engine.
* [Swiftenstein](https://github.com/nicklockwood/Swiftenstein) - A more complete but less polished implementation of the ideas covered in this tutorial.
* [Handmade Hero](https://handmadehero.org) - A video series in which games industry veteran [Casey Muratori](https://github.com/cmuratori) builds a game from scratch in C.

### 赞助

我刚开始编写这个教程的时候，以为只会花上几天时间。差不多两个月后，伴随着无望的尽头，我才发现我有些天真了。所以，如果你觉得这篇教程有意思的话，欢迎我喝一杯咖啡。

[![Donate via PayPal](https://www.paypalobjects.com/en_GB/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=CR6YX6DLRNJTY&source=url)