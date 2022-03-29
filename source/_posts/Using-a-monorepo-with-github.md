---
title: Using_a_monorepo_with_github
date: 2022-03-29 13:34:29
tags:
---

Create some examples of github actions around monorepos

<!-- more -->

# Introduction

Recently, a co-worker was struggling with github actions.  They had a monorepo, or a single repository with a front end and back end code in it.  Many organizations would require that you create two repos: one for the front end and one for the backend.

There are a lot of reasons to use monorepos and many for not using them. I'm not going there. This post will show you how to get the builds going and point out a number of pit falls along the way.

# Background

There are MANY explainations of github monorepos on the web. However, they have the same problems: the author shows you a specific solution, which many times is very complex and the author fails to show you how they got to that specific solution. Also, there are a number of places where you have to write the action yaml file in a specific way or it does not achieve what you want.

Github is a very powerful code version system. It is available to everybody and so far Microsoft has maintained a free tier. A few years ago, github added "actions", which effectively make it the center piece of a complete continuous integration and continuous deployment (CI/CD) system. Actions can:

* build your code
* run tests on your code
* package your code for testing, or putting the code into containers / VMs.
* handle deploying your system, for example: to a container registry or production


Actions are independent of the programming language used to write the code. The github community has supplied lots of example actions to solve a multitude of problems. There is even a market place full of ready to use actions to solve simple or complex automation tasks. With Actions, github can completely replace, legacy systems like Jenkins, Travis or CircleCI.

# Our environment

We are going to write 2 simple programs: a backend program (in the bend directory) in node that exposes an API; and a front end (in the fend directory) in ReactJS to consume that API and do some display. Both of these programs are bare bones, they utilize as little as possible of node and React. Their purpose is to provide code we can build and test against.

First, let's examine the directory structure:

```
$ ls -R
LICENSE		README.md	bend		fend

./bend:
db.json			package.json		test
package-lock.json	srvr.js

./bend/test:
test.mjs

./fend:
README.md		package.json		src
package-lock.json	public

./fend/public:
favicon.ico	logo192.png	manifest.json
index.html	logo512.png	robots.txt

./fend/src:
App.css		App.test.js	index.css	setupTests.js
App.js		getList.js	index.js
$

```

At the top level there are 4 files: a license file, a README.md file and the bend and fend directories. The bend directory has source, package files for node and a test directory. The fend directory has a public and src directories.

# Github setup

Let's take a look at the github side. Github actions are designed to execute when "events" take place on the repository. In this case, we'll use a "push" event to trigger our "build & test" activity. Github actions use a yaml file structure to define what the action will do. We are going to take advantage of the "on:" and the "jobs" keywords. The "on:" keyword can be used to define triggers like push, pull_request and others.

Actions are defined by creating a ".github/workflow" subdirectory in the root of your repo.  This subdirectory will define actions for various triggers, events and other github actvity. 

### Pit fall #1 - build and test JUST THE SUBSYSTEM that changed!

Github actions normally expect a repository to contain a single, self contained sub-system. Default actions expect all of the code for building / testing or what have you to exist in the root of our repo. Our build and test codes (i.e. the package.json and package-lock files) to live in the subdirectories. Our .github/workflow codebase and directory structure look like this:

```
ls -a .github/workflows/
bend.yaml fend.yaml

```

In other words, we have a bend.yaml and a fend.yaml file to define what happens in those specific subdirectories. 

In our case, we have 2: our frontend and backend. On a push to a specific directory we need a way to have the actions code watch and drive the correct build and test code. The "on:" keyword provides a "paths:" statement. When we use the "paths:" statement we are telling github to watch for changes along those paths. Here is an example for the backend:

```

on: 
  push:
    branches: 
      - main
    paths:
      - "bend/**"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
      - name: Install Dependencies
        run: |
          cd bend
          npm ci
          npm test

```

Here is the frontend:

```


on: 
  push:
    branches: 
      - main
    paths:
      - "fend/**"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
      - name: Install Dependencies
        run: |
          cd fend
          npm ci
          npm test

```

The snipit says: "on branch main, watch for changes in the bend sub directory". So we define a yaml file for each subdirectory we want to operate on.

The "jobs:" statement for both fend and bend is very similar: setup ubuntu (should use a specific version here, "not LATEST"), do a checkout, do a setup of node, run "npm ci", run test and finish.

The "npm ci" is similar to using "npm install". It sets a couple of environment variables which tell the test runners (mocha and Jest) they are operating in a Ci/CD environment, not the command line. The big difference is that both mocha and Jest know to stop at the end of the test instead of waiting for interactive input.

We can test at this point to see if github ONLY reacts to changes in the subdirectory. 

* 1: change the top level readme.md file. On the github site, the github actions tab should NOT show any activity.
* 2: change the readme.md inside of the bend. The github actions tab to kick off a build of JUST the bend.
* 3: change the readme.md inside the fend. The github actions tab to kick off a build of JUST the fend.

### Pit fall #2 - why do we have that package-lock.json file?

Let's delete the package-lock.json file and see what we get. You can view the results using the actions tab on the github site. To show you the results here, I downloaded the logs from the github actions run, here is a subset found toward the bottom of the log:

```
2022-03-29T19:16:42.4316265Z npm ERR! The `npm ci` command can only install with an existing package-lock.json or
2022-03-29T19:16:42.4318020Z npm ERR! npm-shrinkwrap.json with lockfileVersion >= 1. Run an install with npm@5 or
2022-03-29T19:16:42.4318984Z npm ERR! later to generate a package-lock.json file, then try again.
2022-03-29T19:16:42.4322871Z 
2022-03-29T19:16:42.4326362Z npm ERR! A complete log of this run can be found in:
2022-03-29T19:16:42.4327174Z npm ERR!     /home/runner/.npm/_logs/2022-03-29T19_16_39_403Z-debug-0.log
2022-03-29T19:16:42.4388470Z ##[error]Process completed with exit code 1.
2022-03-29T19:16:42.4458441Z Post job cleanup.

```

Bottom line: the npm ci code was looking for the package-lock file. If you substitute npm install for npm ci, you will not have this problem, but your build will be a little slower. Ok, put the package-lock.json file back by using npm install and check in the new package-lock.json file to gethub.

This wraps up this article.  What follows is and explaination of the front and back ends. There is 1 more pit fall further down I hit as I was creating the tests.

# Conculsion

Monorepos on github are not difficult to work with. The github actions team provides keywords to watch for changes to specific subdirectories and trigger activity. It is simple enough to write separate configuration yaml files to control for activity in each subdirectory.

# Appendix

## The back end

Let's examine the bend. The main service for the bend is in in the srvr.js file. Nothing magic here as you can see:

```

// bring in requires library and services. In this case express and CORS
const express = require('express');
const cors = require('cors');

// establish app as an express server
let app = express();
// suggest a port
let port = 3333;

// hard code the player information for now.
const players = {
    "graph": [
        { "FirstName": "Joan", "LastName": "Jet", "ID": 1, "Hole": 1, "HoleLocation": "TEE" },
        { "FirstName": "Ruth", "LastName": "Crist", "ID": 2, "Hole": 1, "HoleLocation": "TEE" },
        { "FirstName": "Beth", "LastName": "Flick", "ID": 3, "Hole": 1, "HoleLocation": "TEE" },
        { "FirstName": "Julie", "LastName": "Ant", "ID": 4, "Hole": 1, "HoleLocation": "FWY" },
        { "FirstName": "Ginny", "LastName": "Grey", "ID": 5, "Hole": 1, "HoleLocation": "FWY" },
        { "FirstName": "Paula", "LastName": "Lamb", "ID": 6, "Hole": 1, "HoleLocation": "GRN" },
        { "FirstName": "Ing", "LastName": "Jones", "ID": 7, "Hole": 2, "HoleLocation": "TEE" },
        { "FirstName": "Kelly", "LastName": "Smith", "ID": 8, "Hole": 2, "HoleLocation": "FWY" },
        { "FirstName": "Eilean", "LastName": "Rams", "ID": 9, "Hole": 2, "HoleLocation": "GRN" },
        { "FirstName": "Barb", "LastName": "Sharp", "ID": 10, "Hole": 4, "HoleLocation": "FWY" },
        { "FirstName": "Carol", "LastName": "Adams", "ID": 11, "Hole": 4, "HoleLocation": "FWY" },
        { "FirstName": "Faith", "LastName": "Hope", "ID": 12, "Hole": 4, "HoleLocation": "GRN" }
    ]
};

// get cross-origin resource sharing working so the browaser will not complain
app.use(cors());

// our 2 API
// /graph returns the array of players and an http status code
app.get('/graph', (req, resp) => {
    console.log("/graph/players...", players.graph.length);
    resp.setHeader('Content-Type', 'application/json');
    resp.send(JSON.stringify(players.graph));
})

// the top level API 
app.get('/', (request, response) => {
    console.log("/...")
    response.setHeader('Content-Type', 'text/html');
    response.send("<div>Hello there, welcome</div>")
})

// start the server
app.listen(port, () => {
    console.log(`app listening on port ${port}`)
})

// we need this line to expose the "app" to the testing frame work.
module.exports = app;

```

### Pit fall #3 - testing error

This brings us to another pitfall! This is a TESTING pitfall (not a github monorepo pit fall). If you run this code as you see it above and hit "http://localhost:3333/graph" you will receive the array just as you expect.

To create a test for this API, we use mocha and chia. The test code looks like this:

```


import chai from 'chai';
import chaiHttp from 'chai-http';

// import our app so the test code can use it to call the API
//
// Notice that if the srvr.js file does not expose the API calls with 
// a module.export command you get an interesting but to help error!!
import app from '../srvr.js';

chai.use(chaiHttp);
chai.should();

describe( "players", () => {
    describe("GET /graph", () => {
        it("Should get all players", (done) => {
            chai.request(app)
                .get("/graph")
                .end( (err, res) => {
                    res.should.have.status(200);
                    res.body.should.be.an('array');
                    done();
                })
               
        })
    })
}

);


```

Notice line 10!!! The entire srvr.js file is imported and assigned to the variable "app".  If we comment out line 53 in the srvr.js file we get an error! If you DO NOT use a "modules.export = app" the srvr.js code your test runner can not find the /graph API and you get the following error:


```
npm test

> bend@1.0.0 test
> mocha --exit

app listening on port 3333


  players
    GET /graph
      1) Should get all players


  0 passing (6ms)
  1 failing

  1) players
       GET /graph
         Should get all players:
     TypeError: app.address is not a function
      at serverAddress (node_modules/chai-http/lib/request.js:282:18)
      at new Test (node_modules/chai-http/lib/request.js:271:53)
      at Object.obj.<computed> [as get] (node_modules/chai-http/lib/request.js:239:14)
      at Context.<anonymous> (file:///Users/muguira/code/monorepo/bend/test/test.mjs:19:18)
      at processImmediate (node:internal/timers:464:21)
```

Your only hint is that the test code fails at line 19? Line 19 is where the test runner is trying to call the "/graph" API. With the modules.export call added, we should see: 

```
npm test

> bend@1.0.0 test
> mocha --exit

app listening on port 3333


  players
    GET /graph
/graph/players... 12
      ✔ Should get all players


  1 passing (17ms)
```

## The front end

The front end is a simple ReactJS code that uses a react effect hook to call the "/graph" API.

```

import React, { useState, useEffect } from 'react';

// a little styling just to move the displayed array over 20 pixels.
import './App.css';

// getlist contains the fetch call to the API
import { getList } from './getList.js'

function App() {

  const [list, setList] = useState([]);

  useEffect(() => {
    let mounted = true;
    getList().then(items => {
      if (mounted) {
        setList(items);
      }
    })
    return () => mounted = false;
  }, []);

  // console.log("list==== ", list)
  return (
    <div className="wrapper">
      <table>
        <thead>
          <tr>
            <th>Current players</th>
            <th>Hole</th>
            <th>Location</th>
          </tr>
        </thead>

        <tbody>
          {
            list.map((el, indx) => {
              return <tr key={indx}>
                <td>{el.FirstName} {el.LastName}</td>
                <td>{el.Hole} </td>
                <td>{el.HoleLocation}</td>
              </tr>
            })
          }
        </tbody>
      </table>
    </div>
  )
}

export default App;
```

Nothing magic here. 

The getList.js code is equally simple:

```

export function getList() {
    return fetch('http://localhost:3333/graph')
        .then(data => {
            
            return data.json();
            
        })
}
```

The test code, using Jest is equally easy. I used Jest because the default create-react-app code I started with had everything setup.

```
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders Current Players text', () => {
  render(<App />);
  const linkElement = screen.getByText(/Current players/i);
  expect(linkElement).toBeInTheDocument();
});
```

