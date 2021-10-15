---
title: Creating a basic React map app with Leaflet
tags:
  - Java
categories:
  - Programming
date: 2018-09-22 16:27:12
---



Use OpenStreetMap, Leaflet and ReactJS
<!-- more -->

Use OpenStreetMap, Leaflet and ReactJS

Google and Bing are not the only way to create beautiful map applications!  This post will employ OpenStreetMap and Leaflet in a React based application.  The advantage of this approach is NO license issues.  Granted Google is very liberal about the number of map loads (something around 100,000) before they start charging. But why worry?  The full source code for the project can be found on github ( [link to github]( https://github.com/muguira-james/toysoldiergolf
)

# Introduction to OpenStreetMap and Leaflet

OpenStreetMap is an open source project supported by a global community.  Anybody can contribute.  From the OpenStreetMap site: 

OpenStreetMap emphasizes local knowledge. Contributors use aerial imagery, GPS devices, and low-tech field maps to verify that OSM is accurate and up to date.

One of the great things about OpenStreetMap is that the content is free to use, just so long as you give them credit.

Leaflet is a javascript library used to create interactive maps.  It is small, fast and very easy to learn and use. Using Leaflet in a browser is as easy as including the following code is a <script> tag:

```

// create a map with an initial location
var map = L.map('map').setView([51.505, -0.09], 13);

// maps are organized as tiles.  This brings in tiles around the initial location
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {

    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> 
contributors'}).addTo(map);

```

I am assuming you will have included a reference to the leaflet libraries earlier in your html code.  We’ll examine how to do this latter in this post.  Let’s break the above snippet down so we understand it.  The first think to notice is the line “var map = “.  That tells leaflet to create a map object and to position the map over the point: latitude = 51.05, longitude=-0.09.  That point is very close to Hyde park, London.  The ‘13’ is the zoom factor.  A larger number zooms closer in showing more detail and smaller numbers zoom out showing greater amounts of land.

Map images are drawn from satellite imagery.  The cartographer or map creator breaks the satellite image down into small squares or tiles and stores them in a database. The next lines in the code snippet tells Leaflet where to gather the tiles from and adds these tiles into the map object we created on the first line.

# React and Creating a React Application

This post is focused on creating a React app so let’s talk about how to get started with React! I will use nodejs (I have version 9.X on my mac) and create-react-app to start the project.  Use npm to install create-react-app (npm install -g create-react-app). The sample project is called “toy soldier golf”.  It shows you images of toy soldiers located around the various holes on a golf course.  This initial post just shows the golf course image and statically positions the toy soldiers. Later installations of the post will include graphql to dynamically bring in the soldier location data and incorporate subscriptions to update their location.  First, let’s create our project:


```

create-react-app toysoldiergolf
cd toysoldiergolf
npm install
npm start

```

The last command in the above code block will start a development server and open a tab in your browser.  You should have the following showing in your browser.

![create-react-app-initial.png](/images/create-react-app-initial.png)

Now, we can edit the source and build what we want.  If you list the directory contents you will see 2 directories: public and src.  Public/ contains the index.html file for the application and src/ contains the App.js file.  Let’s look at the index.html file first.  In the following I’ve removed all of the comments AND I’ve added a couple of key items we will need.



```
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="theme-color" content="#000000">

    <link rel="manifest" href="%PUBLIC_URL%/manifest.json">
    <link rel="shortcut icon" href="%PUBLIC_URL%/favicon.ico">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.3/dist/leaflet.css"
   integrity="sha512-Rksm5RenBEKSKFjgI3a41vrjkw4EVPlJ3+OiI65vTjIdo9brlAacEuKOiQ5OFh7cOI1bkDwLqdLw3Zg0cRJAAQ=="
   crossorigin=""/>
     <!-- Make sure you put this AFTER Leaflet's CSS -->
 <script src="https://unpkg.com/leaflet@1.3.3/dist/leaflet.js"
 integrity="sha512-tAGcCfR4Sc5ZP5ZoVz0quoZDYX5aCtEm/eu1KhSLj2c9eFrylXZknQYmxUssFaVJKvvc0dJQixhGjG2yXWiV9Q=="
 crossorigin=""></script>

    <title>React App</title>
    <style>
      .leaflet-container {
          height: 600px;
          width: 600px;
      }
  </style>
  </head>
  <body>
    <noscript>
      You need to enable JavaScript to run this app.
    </noscript>
    <div id="root"></div>
 
  </body>
</html>

```

The original file generated from create-react-app contains: 2 “Link” tags. I’ve added a third one that brings in the Leaflet library CSS file (lines 10-16).  At the time of writing this article, Leaflet was version 1.3.3.  The next item added is the Leaflet source.  The last item added is a little further down, under the html Title tag.  We added a style tag (lines 19-23) to set the size of the Leaflet container on the page.  Experiment with these numbers (height: 600px, width: 600px)!!

Now, let’s consider the file src/App.js in the following snippet: 

```

import React, { Component } from 'react';
import ShowMap from './ShowMap'

var golfCourse = require('./indy.json')

class App extends Component {
  render() {
    return (
      <div>
        <ShowMap golfCourse={golfCourse} />
      </div>
    );
  }
}

export default App;

```

With the changes to App.js, you now have the basic framework. 

# Where next?

Let’s step back and consider what we are trying to do. We want to show a golf course and place images near some of the holes on a golf course. We would like the program to be driven from data files (and later a dynamic graphql based feed). The first data file we need is a golf course.  I will structure the golf course data file using the GeoJSON specification.  GeoJSON creates a javascript object with an array of “Features” that include detailed information in properties about each feature. Also, notice the section called ‘initialRegion”.  When we render the map, we’ll use the data in this section to position the map over the golf course.  So, the first 2 holes on the course would be described like this:

```

{
	“type”: “Feature”,
	“properties”: {
		“FlagLocation: {
			"latitude": 39.79634856773296,
          			"longitude": -86.2293832770481
        		},
		“number”: 1,
	},
	“type”: “Feature”,
	“properties”: {
		"FlagLocation": {
          			"latitude": 39.80071624700618,
          			"longitude": -86.22896065955706
       	 	},
		“number”: 2,
	}
…

	  "initialRegion": {
    		"latitude": 39.79519990082653,
    		"longitude": -86.22999179295153,
    		"latitudeDelta": 0.0005,
    		"longitudeDelta": 0.0020
  	},
}

```

I clicked the green on each hole on google maps to get the latitude and longitude entries. 

Once the golf course has been specified we can start to modify the arc/App.js file.  Instead of placing all the code in one file I’ll use React’s composition powers to structure the project.  Let’s make a src/ShowMap.js component to hold the map rendering logic.  In a later version of this project you will see why I move map rendering out of App. ShowMap will handle getting the map tiles, setup and map rendering.  We will use the entries in the golf course file we just worked through to guide map rendering.

Leaflet and React are two separate libraries and they don’t play together very nicely.  Leaflet wants to control everything to do with the map.  When you work with just Leaflet you use event listeners to have it change appearance due to external stimulus.  We only view the map, so this is not a problem for us.  To make this project even easier, we’ll use a npm package called ‘react-leaflet’.  The designers of the package have encapsulated leaflet interaction with React.  In this instance, we are going to use the Map component, providing it with enough details to get the map on the screen.

```

import React from 'react'

import { Map, TileLayer, Marker, Popup } from 'react-leaflet';
import L from 'leaflet'

class ShowMap extends React.Component {

  // create a location object out of a { Latitude, Longitude }
  createMarkerLocation = (f) => {
    let floc = []
    floc.push(f.latitude)
    floc.push(f.longitude)
    return floc
  }

  render = () => {
    let pos = this.createMarkerLocation(course.initialRegion);
    return (
      <Map
        center={pos}
        zoom={16}>
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution="&copy; <a href=&quot;http://osm.org/copyright&quot;>OpenStreetMap</a> contributors"
        />
      </Map>
    )
  }
}

export default ShowMap;

```

Let’s examine that code block. We import the Map, Tile and Marker components from react-leaflet.  The react-leaflet component needs a “center” and a “zoom” factor.  I hard coded the “zoom” factor for now (line 21).  The “center” object is an array of [ latitude, longitude ] (line 20).  The TileLayer requires a url pointing to the OpenStreetMap tile set.  See the OpenStreetMap docs to understand what you can do with that url.

Restarting the app with yarn start (or saving the files if you left things running) should produce the following screen:

![indy.png](/images/indy.png)

# But wait, where do those red flags and toy soldiers come from?

Ok, that is the final screen!  Let’s get that going. The first thing we need is to draw a marker at each red flag.  To do that we will loop over the course file that was passed in as a prop to ShowMap.  

As a bit of debugging, try placing the following as the first statement inside the render() function: console.log(“props->”, this.props).  In the browser console you will see that App passed the course file definition down to ShowMap.  We will use a javascript map function to loop over that course file and create a marker for each flag.  Change the render function to the following:

```

  // render the current state of the app
  render = () => {
    console.log("p->", this.props)
    let course = this.props.golfCourse
    // convert the prop initialRegion into a Leaflet position
    let pos = this.createMarkerLocation(course.initialRegion);

    // reset the playerDrawing map
    playerDrawingUtils.mapLocationClear()

    return (
      <Map
        center={pos}
        zoom={16}>
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution="&copy; <a href=&quot;http://osm.org/copyright&quot;>OpenStreetMap</a> contributors"
        />
          {
            course.Features.map((f, n) => {
              return this.createMarker(f.properties.number, f.properties.FlagLocation)
            })
          }
      </Map>
    )
  }

```


Note that we added a map over the course file in lines 19-23.  The definition for createMarker is found on the accompanying [github]( https://github.com/muguira-james/toysoldiergolf
)

Now let’s get the soldiers showing.  First, let’s make a simple array to hold the soldier locations.

```


// as you can see from this structure the players are on hole {1, 2, 3, 4}
const players = [
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

```

Inspecting the array, we are providing the soldier name, their ID, the hole they are on and the location on the hole (tee, fairway or green). This block is included in to ShowMap between the inport statements and the definition of the ShowMap component.  We can now create a map over the soldier array and use Leaflet capabilities to create and show markers on the map.

```

{
            players.map((p, n) => {
              let name = p.FirstName + " " + p.LastName
              let plyr = this.createPlayer(n+1, name, p.Hole, p.HoleLocation, course)
              return plyr
            })
          }

```
  
There are a few functions not shown to save space.  A leaflet marker needs a position (an array of [latitude, longitude]) and an icon.  We are also providing the soldier name to the leaflet popup so when you click on a soldier their name pops up.  The images for the soldiers are arranged as a dictionary and indexed by number.  The same scheme is used for the flags.

# Conclusion

This article has walked through just enough information to show a map in a React app.  The project used ReactJS, Leaflet and a node component called react-leaflet.  The map is a simple base map.  There are MANY more maps available from the OpenStreetMap collection.  The next article in this series will explore more of the OpenStreetMap collection.  But, the main focus of the next article is to bring GraphQL in to make the toysoldier player positions dynamic.

I hope you found this useful, thank you!
  
  

