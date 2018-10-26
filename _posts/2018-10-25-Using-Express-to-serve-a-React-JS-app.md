---
layout: post
title:  "Using Express to serve a ReactJS app"
date:   2018-10-09 13:27:12 -0400
published: true
categories: ['Programming']
tags: ['Node', 'Express', 'React']
---
Use node Express to serve a ReactJS app

# Introduction

This article will describe how to setup node express to serve a ReactJS app.  The article has several parts: 

+ Getting Node working on your computer
+ Working your way through Express and understanding the elements we will use
+ Using npm to generate a production version of a working ReactJS app

There are many tutorials on the web that describe the process of creating a ReactJS app.  There are also numerous articles that walk through creating apps with Express. The main contrbution here will be demonstrating how to go from development to production with an existing ReactJS app.  The production version of the ReactJS app will be served by Express.

## Setup Node

I advise you use Mozilla's great material to install Node [Mozilla MDM](https://developer.mozilla.org/en-US/docs/Learn/Server-side/Express_Nodejs).  I also advise you to follow the instructions for obtaining Node from the Node website.  You could use the package manager for your distribution or Brew for the Mac.  However, getting your code directly from the source is best.  Once nodeJS is installed installing Express is simply: "npm install express -g"

This article will build a couple of versions of the server. I'll do this to show how simple it is to use Express. The first version will just start a server and serve the ReactJS app as a static page.  We'll then add features to that version: very simple routing and a very simple DB.

## First server

Using node + Express can be very simple.  Consider this 4 line program:

{% highlight ruby %}
var express = require('express')
var app = express()

app.get('/', (request, response) => {
    response.send("hello World")
})

app.listen(3000, () => {
    console.log(' app listening on port 3000')
})
{% endhighlight %}

The first 2 lines pull in express (after you install it with npm install express -g) and create a variable to hold the reference.  The statement "app.get" sets up a route or a way to translate the url into something the server can return to the caller.  In this case, we simply return "hello world" as a string.  Express handles all setting of the headers.  We'll do more with that in a bit. The last statement ("app.listen") starts the server and waits on input from localhost port 3000.  If you point your server to localhost:3000 you should get "hello world" back.

At this point we could create complex html pages and serve them by adding more modules to Express.  But the article goal is to serve a ReactJS app.  How to do that?

ReactJS created from the create-react-app command provides a number of "canned" scripts.  For example, we can start the app and show it in the default browser (npm start), we start the Jest test fixture (npm test) and we can have the built-in webpack bundle together our app in a build directory.  This bundled app will have the javascript code joined into a single file (or maybe 2 files, depending on your setup).  It will have all of the paths setup to run from a static path and the package.json file adjusted to run from a relative url.  Thus, the app is bundled together as a static uri resource.

The first thing we need to do is to tell Express how to serve static content, such as index.html files and images.  When you work with Express you have the ability to extend it by adding "middle-ware" that helps with adding functionality.  We are going to take advantage of a middle-ware that let's Express serve static information.  It is a single line that we add right before we setup our route:

+ app.use(express.static('public'))

In Express, adding middle-ware happens "in order" and BEFORE you add routes and start the server.  In our case we will add a middle-ware to handle static content.  We'll point to the "public" directory and store all of our ReactJS bundled software there. The server now looks like:

{% highlight ruby %}
var express = require('express')
var app = express()

app.use(express.static('public'))

app.get('/', (request, response) => {
    response.send("hello World")
})

app.listen(3000, () => {
    console.log(' app listening on port 3000')
})
{% endhighlight %}

After we copy all of our bundled ReactJS app, from the build directoyr into "public" our directoy structure for the project looks like this:

{% highlight ruby %}
asset-manifest.json	favicon.ico		index.html		manifest.json		service-worker.js	static

public//static:
css	js	media

public//static/css:
main.65027555.css	main.65027555.css.map

public//static/js:
main.c70caac9.js	main.c70caac9.js.map

public//static/media:
Hole1.813cb29b.png	...

{% endhighlight %}

Inspecting this you can see: a css, js and media directories under public. The "npm build" command gathered up all of the javascript, our source and the modules under node_modules and put them into the "public/static/js" dir. Since the ReactJS app has several image files they are saved into "public/static/media". If we run the server and point our browser at localhost:9000/index.html we see the following:

[our React App](/assets/ProdReact.png)
 
## Our Second Server

Talk about CORS
db setup - in memory
Add Fetch to ReactJS

## Third Server

Add MongoDB and mongoose
Maybe add express view Jade/pug
