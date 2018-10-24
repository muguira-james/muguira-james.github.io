---
layout: post
title:  "React UI construction and testing with Storyboook"
date:   2018-10-24 13:27:12 -0400
published: true
categories: ['Programming']
tags: ['React', 'Javascript']
---

Creating and testing a UI should be visual.

# Introduction

In a previous article, I wrote about employing Jest and BDD to test a UI.  Jest is a powerful tool with a lot of primitives to structure UI testing.  However, it is not very intuitive.  Let alone trying to use behavior driven development to develop the UI.

This caused me to search around in the React eco-system looking for a better tool.  I wanted to be able to see what I was building and develop the tests as I go.  Storybook is a very nice tool. It is NOT a visual construction framework.  It IS a visual way to structure tests. Let's take the React app we wrote for the Graph ADT and rebuild it using Storybook.

## Setup

Storybook is very easy to setup.  I will recommend 2 sites: the Storybook 

+ ![ storybookjs.org ]( https://storybook.js.org/ ) for how to install it; and 
+ ![ learn storybook ]( https://www.learnstorybook.com/react/en/get-started/ ) as a good tutorial.  

This article will build on the "learn Storybook" material to build our graph adt consumer.  The original graph consumer and visualizer was very simple: it shows the graph as text with relationships show as indentions. This post will expand that a little to demo more of Storybook's features.  I am not going too deeply into what Storybook can do.  

Our previous article started by describing the Vertex and Edge data structures.  Vertex are used to hold information about entities in our system.  Things like the name, strength of a player and a list of what they were carrying.  Edges represent the relationships between the players.  In our example, relationships were one directional. The previous article then described the tests.  This is where this article will differ.  Let's use Storybook to build the UI from the bottom up.

## Testing the Adjacency List

The lowest level aspect of the UI is to display a single relationsip, a graph Edge.  A Graph Edge is an Object with a beginning and an end vertex.  A vertex is composed of a name, a strength (we'll not worry about the list of carried items for now).  Let's start by displaying the "end" of the relationship, the name.  In the Storybook UI, this would look like: 

![ShowAdjacent default view](/assets/ShowAdjacent_default.png)

Not too interesting, just the name "Tom".  The Storybook interface contains several components: on the left is a nav panel showing each of the "stories" in your project, on the right is a visual of the UI in test and in the lower right is the log.  In Storybook, you code stories for each test of your UI. Our first story is to simply show the UI.  Storybook setup specifies that you create a __stories__ sub dir under your src dir.  I'm going to follow the Jest convention and name my story files like this: "ShowAdjacent.stories.js" and place them in the same dir as the file under test.  This implies we have to change Storybook's default config a little.  When we loaded storybook into our environment (with npm i @storybook/cli and then ran getstorybook) it created a directory called .storybook.  This dir contains a config file.  Here is mine after I changed it:

{% highlight ruby %}
import { configure } from '@storybook/react';

const req = require.context('../src', true, /.stories.js$/);

function loadStories() {
  req.keys().forEach(filename => req(filename));
}

configure(loadStories, module);
{% endhighlight %}

The second line tells storybook to look in my src dir for files that fit the pattern "*.stories.js" and use those. My first stories file (ShowAdjacent.stories.js) looks like this:

{% highlight ruby %}

import React from 'react';
import { storiesOf } from '@storybook/react';

import ShowAdjacent from './ShowAdjacent';

export const adjacentList = [
    {
        beginning: { name: "Jasper",  id: 0 },
        end: { name: 'Tom', id: 1 }
    }
]

storiesOf('ShowAdjacent test', module)
  .add('default', () => <ShowAdjacent adjacentList={adjacentList} />)
  

{% endhighlight %}

Storybook story files follow a pattern: they import needed files, define data types and then define the stories (tests).  In this case, we defined an adjacent list that has a valid beginning ("Jasper") and end ("Tom") vertex.  The "stories" section of the file defines the test: we called it "ShowAdjacent test" and used the .add primitive to define a test called default.  The default test just calls the ShowAdjacent React component and hands it props.  The next test that comes to mind is what happens if the adjacent list is malformed? Let's build an adjacent list missing the name for the end of the relationship.

{% highlight ruby %}

import React from 'react';
import { storiesOf } from '@storybook/react';

import ShowAdjacent from './ShowAdjacent';

export const adjacentList = [
    {
        beginning: { name: "Jasper",  id: 0 },
        end: { name: 'Tom', id: 1 }
    }
]
export const empty_name = [
    {
        beginning: { name: "",  id: 0 },
        end: { name: "", id: 1 }
    }
]

storiesOf('ShowAdjacent test', module)
  .add('default', () => <ShowAdjacent adjacentList={adjacentList} />)
  .add('undef name', () => <ShowAdjacent adjacentList={undef_name} />)

{% endhighlight %}

In this case, the app should not crash, yet it does! The problem is that the ShowAdjacent component does not handle the case of badly formed adjacency lists. We'll have to refactor the code. The refactor is straight forward, we check to see if there is a name before we try and return the list item. Another test we should try here is to make sure the app gracefully handles no adjacency list. I'll just show the data and the story case:

{% highlight ruby %}

export const empty_adjacentList = []

export const empty_name = [
    {
        beginning: { name: "",  id: 0 },
        end: { name: "", id: 1 }
    }
]

export const undef_name = [
    {
        beginning: { name: "",  id: 0 },
        end: { id: 1 }
    }
]

storiesOf('ShowAdjacent test', module)
  .add('default', () => <ShowAdjacent adjacentList={adjacentList} />)
  .add('undef name', () => <ShowAdjacent adjacentList={undef_name} />)
  .add('no data', () => <ShowAdjacent adjacentList={empty_adjacentList} />)

{% endhighlight %}

# Testing the Graph

We have created and run some stories for testing the Adjacency list.  Let's test the next component up, the graph.  The graph stories file follows the same pattern: import the files you need, setup some data, define the tests.  In our case, we'll run 4 tests: 

+ a default graph
+ an empty graph
+ an adjacency list with several entries
+ a graph with several vertex entries





