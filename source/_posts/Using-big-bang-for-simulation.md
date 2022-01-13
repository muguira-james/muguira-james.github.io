---
title: Using-big-bang-for-simulation
date: 2022-01-09 12:48:37
tags:
  - Racket
categories:
  - Programming
  - big-bang
---


This post will explain how to use Racket's simulation facilities: big-bang.

<!-- more -->

# Introduction

The Racket programming language provides a simple to use facility for creating games and simulations. It is called big-bang. This facility provides easy to use methods to display a changing scene, capture mouse and key board inputs, start and stop the game or simulation, and handle the sequencing of time in your game.

Big-bang builds upon the lower-level capabilities of Racket's graphics subsystem. Big-bang enables you to create both 2 and 3D worlds. This post will focus on 2D.  To use Big-bang you will need to learn about handling images.  This post will show some of the simplest ways to bring images into your world.

Big-bang provides several types of graphical presentations.  You can create movies with the "animate" and "run-movie" commands. These commands open worlds that just loop and show you a changing scene. You can also make interactive worlds (i.e. a game) that can be manipulated with the keyboard or mouse. Big-bang can be used to create simple worlds or games, but it can also create complex simulations of interacting worlds (think multi-user dungeon or MUD). We will create a simple game.

## Big-bang and WorldState

Big-bang operates by showing you the visualization state of the world at each time tick. You change the world state by using the keyboard or mouse or by writing programs that change the world state. So, big-bang just operates as a loop that shows you the state of the world on each time tick.

### What is WorldState?

Big-bang is really just a Racket function that manages this thing called "WorldState". It provides sub-commands to draw WorldState, capture keyboard or mouse activiy, and handle activity that happens on the tick. Please consult the docs on [big-bang][https://docs.racket-lang.org/teachpack/2htdpuniverse.html?q=big-bang] because it can do a lot.

The critical thing to understand is that big-bang and all of its sub-functions manage WorldState. For example, as a simulation is running, if you press the "up arrow" key then the handler function for "up arrow" has to change WorldState somehow and return the new WorldState. Big-bang will take that new WorldState and set the current WorldState to what was returned. If you investigate the documentation, all the big-bang functions that start with "on-X" work this way.

## Our 1st look

Let's write a simple world to see how big-bang works. To get started, we can write a simple simulation that just shows a bird flying across the screen.  This first attempt will have the bird fly off the screen. We can provide a way to stop this simulation from the keyboard. First, study the documentation for big-bang and see what functions we will use.

From the big-bang docs we see the following functions:

* to-draw - create a scene to show WorldState
* on-key - capture a key board key press, we can use the 'q' key to stop the simulation
* on-tick - change and return the new WorldState.

We will use those 3 functions. Big-bang always starts with a "state-expr", that is a function that creates and returns the initial state of the world. In our case, we can return the initial location of the bird. For simplicity, the bird can start near the left side of the screen and fly to the right. We'll deal with up and down in a minute.

To make managing the WorldState easy, we can use a structure for the vertical and horizontal position of the bird. Using a structure will make it easy to update the position of the bird as the simulation runs. Each clock tick will advance the bird by changing the vertical and horizontal location.

### our plan:

* Bring in an image, size it and scale it and display it
* Create the bird position structure
* Write a handler for the tick
* Write a handler for the key board, this will stop the simulation for now
* Write the big-bang statement and test

#### Bring in the image and scale it
To Bring in an image from disk, we will use the bitmap function to read a image from disk. The image will be too large, so we'll scale it down to size. Finally, we'll define a variable to hold the scaled image so we can refer to it from the simulation.

Here is my first try 

![flying crane, but too big](/images/flying-crane/flying-crane-screenshot-1.png)

Ok, we have the crane, but it is too large. We can use the image scale/xy function to make it smaller. The scale/xy function takes a scaling factor for x and y to change the size of the image.  I'll try to reduce it by 3/4 in each dimension. We will also save the image to a variable named crane. 

![flying crane, just right](/images/flying-crane/flying-crane-screenshot-3.png)

Ultimately, we want to draw our crane into a scene, let's get that out of the way. We will use place-image for that task, it takes an image, the x & y position, and the scene to draw into. One thing you must get used to will be how the computer hardware has defined the coordinate system of our scene. On graph paper, you learned to define the point (0,0) in the lower-left side of the scene.  Increasing y goes up the page and increasing x goes to the right. Computer hardware defines the point (0,0) in the upper left. That means as the x or horizontal dimension increases to goes to the right (just like graph paper), but the increasing y dimension goes down the page.

The code to this point looks like:

```

#lang racket

(require 2htdp/universe 2htdp/image)

(define WIDTH 600)
(define HEIGHT 400)

(define crane (scale/xy 0.25 0.25 (bitmap "flying-crane.png")))

;
; place the bird image near the upper left corner of the scene
(place-image crane 80 80 (empty-scene WIDTH HEIGHT))

```

#### Create the bird structure

To this point we have brought the bird image in, scaled it to size and drawn it in a empty scene. Now, we tackle the WorldState position structure for the position of the bird. It looks like this:

```
; define where the image is in the x and y dimensions
(struct bird-posn (x y))

```

Pretty simple. you will see that the tick handling code creates and returns a new structure on each call. 

Now, let's turn the "place-image" code into the big-bang to-draw handler function. The "to-draw" function of big-bang takes one parameter: a render expression. That render expression receives the current WorldState from big-bang as it is called. We must use the input WorldState, figure out where the image will be drawn and draw our image on our scene.

```
;
; note the current worldstate is handed to us in 'w'
(define (render w)
    (place-image crane 
        ; get the current x position from 'w'
        (bird-posn-x w) 
        ; get the current y position from 'w'
        (bird-posn-y w) 
        ; place-image draws into this empty scene of size (WIDTH, HEIGHT)
        (empty-scene WIDTH HEIGHT)))

```

To create animation, we'll place the bird image on an empty scene each time render is called. We could easily make is look like the bird was flying over trees or grass by rendering those on to the scene first.

#### The tick handler

We know we are going to use big-bang to call to-draw. The to-draw function is going to call the render function we just defined. But how is the world going to change? That is the job of the tick handler, handle-tick. Since the name of the big-bang function is "on-" something, we know we must create a new world state and return it from handle-tick. That is why we used a structure. The handle-tick function looks like:

```
(define (tick-handler w)
    (bird-posn (+ 10 (bird-posn-w w)) (bird-posn-y y)))

```

#### The key board handler

The key board handler is waiting for a 'q' key to stop the action. Big-bang uses a function called 'stop-with' to bring the animation to a close. 

```
(define (handle-key w key)
    (cond 
        [(key=? key "q") (stop-with w)])
        [else w])

```

#### Big-bang initialization

The last thing to do is it write the big-bang statement. In this case we will create a function called start...

```
#lang racket
(require 2htdp/universe 2htdp/image)

;
; set a width and height for the scene
(define WIDTH 600)
(define HEIGHT 400)

;
; bring the bird image in from disk
(define crane (scale/xy 0.25 0.25 (bitmap "flying-crane.png")))

;
; our world state structure
(struct bird-posn (x y))

;
; the render function for drawing
(define (render w)
  (place-image crane (bird-posn-x w) (bird-posn-y w) (empty-scene WIDTH HEIGHT)))

;
; the tick handler to move the bird
(define (handle-tick w)
  (bird-posn (+ 10 (bird-posn-x w)) (bird-posn-y w)))

;
; the key board handler, waiting for a "q" key to stop the action
(define (handle-key w key)
  (cond
    [(key=? key "q") (stop-with w)]
    [else w]))

;
; start the anaimation. Initially, the bird will be located on x=80, y=80
(define (start)
  (big-bang
    (bird-posn 80 80) ; this is our initial WorldState structure!
    (to-draw render)
    (on-tick handle-tick)
    (on-key handle-key)))

```

Big-bang will repeatedly call our handle-tick code, which advances the bird image 10 pixels to the right. If we press a 'q' key the animation will stop.

# Conclusion

Racket-lang provides an easy-to-use function to create games and movies. Here, we used it to simulate a bird image moving across the screen from left to right. The bird image just flys off the right side of the screen and keeps going until we call stop by pressing the 'q' key. Big-bang can do a lot. I encourage you to read the documentation.

Next article, we'll add to the simple crane.rkt program to bring in more keyboard inputs and to make the image bounce off the edges of the scene (vs. fly off).

thank you for reading!
