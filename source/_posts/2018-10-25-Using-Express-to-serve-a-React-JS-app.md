---
title: Using Express to serve a React app
tags:
  - Node
  - Express
  - React
  - MongoDB
categories:
  - Programming
date: 2018-10-26 13:27:12
---


Use node Express to serve a React app
<!-- more -->
# Introduction

This article will describe how to setup node express to serve a React app.  We will reuse the React app created for the article [Creating a basic React map with Leaflet](https://github.com/muguira-james/toysoldiergolf).  The code for this article is [here](https://github.com/muguira-james/React-Express). The article has several parts: 

+ Getting a simple express server working on your computer
+ Enhancing the React App to fetch data from a server

There are many tutorials on the web that describe the process of creating a React app.  There are also numerous articles that walk through creating apps with Express. The main contribution here will be demonstrating how to go from development to production with an existing React app.  The production version of the React app will be served by Express.

## Setup Node and Express

I advise you use Mozilla's great material to install Node [Mozilla MDM](https://developer.mozilla.org/en-US/docs/Learn/Server-side/Express_Nodejs).  I also advise you to follow the instructions for obtaining Node from the Node website.  You could use the package manager for your distribution or Brew for the Mac.  However, getting your code directly from the source is best.  Once nodeJS is installed installing Express is simply: "npm install express -g"

This article will build a couple of versions of the server. I'll do this to show how simple it is to use Express. The first version will just start a server and serve the React app as a static page.  We'll then add features to that version: very simple routing and a very simple DB.

## First server

Using node + Express can be very simple.  Make a directory called simple_express and use "cd simple_express; npm init". Then add this 4-line program as simple_press.js:

```
var express = require('express')
var app = express()
var port = 9000

app.get('/', (request, response) => {
    response.send("hello World")
})

app.listen(port, () => {
    console.log(`app listening on port ${port}`)
})
```

The first 2 lines pull in express (after you install it with npm install express -g) and create a variable to hold the reference.  The statement "app.get" sets up a route or a way to translate the url into something the server can return to the caller.  In this case, the browser url would be "http://localhost:9000/" and the server would return "hello world" as a string.  Express handles all setting of the headers.  We'll do more with that in a bit. The last statement ("app.listen") starts the server and waits on input from localhost port 9000.  If you point your server to localhost:9000 you should get "hello world" back.

At this point we could create complex html pages and serve them by adding more modules to Express.  But the article goal is to serve a React app.  How to do that?

A React app created from the create-react-app command provides a number of "canned" scripts.  For example, we can start the app and show it in the default browser (npm start), we start the Jest test fixture (npm test) and we can have the built-in webpack bundle together our app in a build directory.  This bundled app will have the javascript code joined into a single file (or maybe 2 files, depending on your setup - we do a directory listing down below).  It will have all of the paths setup to run from a static path and the package.json file adjusted to run from a relative url.  Thus, the app is bundled together as a static uri resource.

This article will reuse the React app we wrote to use Leaflet in React [React + Leaflet](https://muguira-james.github.io/A-creating-basic-React-app-with-a-leaflet-map/). Issuing “npm start” from the command line can run the code.  It opens port 3000 on localhost.  Fro the browser point of view, the React app is just static content.  It is html and javascript and images.  So, we want Express to treat the React app as static content when a client requests the React App. However, the React app is setup to run from the create-react-app infrastructure.  We need to convert it to a static format for serving from our Express server.  To accomplish this we use "npm run build".  That command will create a build dir and add all of the required content.  We can copy the contents of the build dir to our Express server "public".  We are going to run the build step manually, but you might want to look into Jenkins to handle it automatically.

### Setup Express for serving static content

The first thing we need to do is to tell Express how to serve static content, such as index.html files and images.  When you work with Express you have the ability to extend it by adding "middle-ware" that helps with adding functionality.  We are going to take advantage of a middle-ware that let's Express serve static information.  It is a single line that we add right before we setup our route:

+ app.use(express.static('public'))

In Express, adding middle-ware happens "in order" and BEFORE you add routes and start the server.  In our case we will add a middle-ware to handle static content.  We'll point to the "public" directory and store all of our React bundled software there. The server now looks like:

```
var express = require('express')
var app = express()

app.use(express.static('public'))

app.get('/', (request, response) => {
    response.send("hello World")
})

app.listen(3000, () => {
    console.log(' app listening on port 3000')
})
```

After we copy all of our bundled React app, from the build directory into the Express "public" directoy, our structure for the project looks like this:

```
asset-manifest.json	favicon.ico		index.html		manifest.json		service-worker.js	static

public//static:
css	js	media

public//static/css:
main.65027555.css	main.65027555.css.map

public//static/js:
main.c70caac9.js	main.c70caac9.js.map

public//static/media:
Hole1.813cb29b.png	...

```

Inspecting this you can see: a css, js and media directories under public. The "npm build" command gathered up all of the javascript, our source and the modules under node_modules and put them into the "public/static/js" dir. Since the React app has several image files they are saved into "public/static/media". If we run the server and point our browser at localhost:9000/index.html we see the following:

![ProdReact.png](/images/ProdReact.png)
 
## Our Second Server

We have created enough infrastructure to serve a static React app.  Express is using the static middle-ware to serve our React App. But, the data for the React app is defined in the React program.  Now, let's define it in the server and have the React App fetch it.

The first change is to define the server API in our server for the React app.  We can take the data out of the React app and place it in the server.  This will form a simple in-memory db.  Then we define the API using Express routes.  

### Cross Origin Support (CORS)

If you look at the code for the server you will see 2 new items: CORS support and the data for the list players.  If you study the urls and ports in our application you will notice that we were careful to serve the React App from localhost on port 9000.  We were also careful to have the React App request data from localhost port 9000.  We defined a new API for the React App to get the data from: /api/players.  These definitions do not violate Cross Origin Resource Support, or CORS, rules.  

A lot happens behind the scenes when a browser asks for a web page.  When a browser first asks for a web page it sends a small message to the server called a "pre-flight message".  The web server checks this message, specifically the headers, to see if the requesting host and ports match its own.  If they do, the web server sends back a positive acknowledgement to the requesting client and the browser continuous to load the requested page.  If not the web server checks to see if it has had CORS enabled.  If this is true, it will send back a positive acknowledgement anyway to let the browser proceed.  If CORS is not enabled the server sends back a negative acknowledgement and the browser reports the error in the console.

We can test this out in our current setup.  Here is the full server code so far

```javascript=
var express = require('express')
var cors = require('cors')
var app = express()

var port = 9000

// as you can see from this structure the players are on hole {1, 2, 3, 4}
const players = {
    graph: [
    {FirstName: "Joan", LastName: "Jet", ID: 1, Hole: 1, HoleLocation: "TEE"},
    {FirstName: "Ruth", LastName: "Crist", ID: 2, Hole: 1, HoleLocation: "TEE"},
    {FirstName: "Beth", LastName: "Flick", ID: 3, Hole: 1, HoleLocation: "TEE"},
    {FirstName: "Julie", LastName: "Ant", ID: 4, Hole: 1, HoleLocation: "FWY"},
    {FirstName: "Ginny", LastName: "Grey", ID: 5, Hole: 1, HoleLocation: "FWY"},
    {FirstName: "Paula", LastName: "Lamb", ID: 6, Hole: 1, HoleLocation: "GRN"},
    {FirstName: "Ingid", LastName: "Jones", ID: 7, Hole: 2, HoleLocation: "TEE"},
    {FirstName: "Kelly", LastName: "Smith", ID: 8, Hole: 2, HoleLocation: "FWY"},
    {FirstName: "Eilean", LastName: "Rams", ID: 9, Hole: 2, HoleLocation: "GRN"},
    {FirstName: "Barb", LastName: "Sharp", ID: 10, Hole: 4, HoleLocation: "FWY"},
    {FirstName: "Carol", LastName: "Adams", ID: 11, Hole: 4, HoleLocation: "FWY"},
    {FirstName: "Faith", LastName: "Hope", ID: 12, Hole: 4, HoleLocation: "GRN"}
  ]
}

app.use(cors())

app.use(express.static('public'))

app.get('/api/players', (request, response) => {
    // console.log("players...", JSON.stringify(players))
    response.setHeader('Content-Type', 'application/json');
    response.send(JSON.stringify(players))
})

app.listen(9000, () => {
    console.log(`app listening on port ${port}`)
})
```

Notice lines: 2, 25.  Line 2 brings in the CORS support and line 25 enables the middle-ware.  If you comment out line 25 and run the React App from its original directory with npm start, you should see a failure message on the browser console log.  The reason for the failure is that the React app is being served from a server running on localhost port 3000 (by default from create-react-app) and our Express server is running on localhost port 9000.  That is a cross origin violation.  Now uncomment line 25 in the Express server and restart it.  If you refresh the "React App" tab in your browser, you should see the map.

If you consider lines 7-23 of the Express server you will see the in-memory database.  These player definitions are served to callers on line 33 of the Express server.

What does the React App look like?  The original app had the data defined in the code.  We changed that to use javascript fetch in a React lifecycle method.  React's componentDidMount lifcycle method is called after the component mounts (or, is initialized and attached to the browser DOM). In our new overide of componentDidMount, we fetch our data and place it in state.

```
import React from 'react';

import ShowMap from './ShowMap'

var golfCourse = require('./indy.json')

export default class SimpleExample extends React.Component {

  constructor(props) {
    super(props)
    this.state = {
      playerList: null,
    }
  }
  // // use javascript fetch to get the graph from the server
  componentDidMount() {
    let url = 'http://localhost:9000/api/players'

    // just fetch, no error handling here!
    // when the fetch completes, put the graph in "state"
    fetch(url)
      .then(resp => { return resp.json() })
      .then((resp) => {
        this.setState({ playerList: resp.graph })
      })

  }

  render() {
    if (this.state.playerList !== null) {
      return (
        <ShowMap golfCourse={golfCourse} listOfPlayers={this.state.playerList} />
      );
    } else {
      return null
    }

  }
}
```

# Conclusion

We reused a React app and showed how to create an Express server to serve both the React app and content.  Very little changed in the React.  We:

+ Moved the data used to draw the toy soldiers out of the app and into our Express server
+ We used javascript fetch to get data from the server
+ We used npm run build to set the React app up as static content

On the server side, we:

+ Created a very simple server and set it up to serve static content using the built-in middle-ware "static".
+ Created a 'public' directory and copied the React app build into it
+ Created an api ("/api/players") to serve data to the React app.

Express is very flexible.  It has a broad eco-system with many supported middle-ware definitions.  These can be used to create a very wide varity of web serve instances.
