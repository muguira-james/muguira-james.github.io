---
title: JUnit Testing in java
tags:
  - Java
categories:
  - Programming
date: 2018-10-06 13:27:12
---



Using JUint 5 and JDK 8
<!-- more -->
# Introduction

This post will examine testing in the java programming language.  We’ll use an implementation of a graph abstract data type to motivate testing at the unit and behavior levels using java.  A graph is a type of Abstract Data Type (ADT) that allows you to capture and reason about the relationships between objects in your problem.  There are several open source projects that implement a graph as their core data structure, for example: the Neo4J database and the open source Cassandra database.

The sample code for this article can be found on: ( [link to github]( https://github.com/muguira-james/GraphsTesting_Java ))

# Tool set

Since this post is going to explore java, let’s state the tool set we’ll use: 

Java 1.8 – openjdk

Eclipse – any recent version

JUnit – 5.0.

# What is a Graph?

![GraphOfPeople.png](/images/GraphOfPeople.png)

A graph is composed of nodes, also called vertices and edges.  A node contains information about characters in our game. In this case, a node contains information like the character name, their relative strength, what they are carrying, etc.  In our diagram: the oval with the name Jasper is a node.  Jasper is carrying a sword.  Another node is Emma.  She is carrying a wand.  You will notice that the nodes also have edges or arrows connecting them.  These edges represent relationships between the characters.

# Implementation

How could we represent these nodes and edges in a graph ADT? Let’s first start with defining a java class for the overall graph and then we can create specialized extensions.  We’ll use a Java abstract class and define the interface that we want the specializations to implement.

```

package grandview;

import java.util.List;

// an abstract Graph type.
//
// To keep it simple, I’ll allow node and edge labels to be defined with integers.
public abstract class Graph {
	private int numVertices;
	private int numEdges;

	public Graph() {
		numVertices = 0;
		numEdges = 0;
	}
	
	public int getNumVertices() {
		return numVertices;
	}
	
	public int getNumEdges() {
		return numEdges;
	}

	public void addVertex() {
		
		implementAddVertex();
		numVertices++ ;
	}
	
	public void addEdge(int v, int w) {
		implementAddEdge(v, w);
		numEdges++;
	}
	
	public abstract void implementAddVertex();
	public abstract void implementAddEdge(int v, int w);
	
	public abstract List<Integer> getNeighbors(int v);
}

```

The Graph object contains methods for getNumVertices(), getNumEdges(), addVertex() and a constructor.  Graph object implementors must define the abstract methods: implementAddVertex(), implementAddEdge() and getNeighbors().

To get this going in Eclipse, define a new Java package (in my case called Grandview), and inside of that define a new class called Graph.  There are 2 ways we can implement the relationships in a graph, we can implement the relationships as an adjacency matrix or we can implement then as adjacency lists.  Since this post will cover testing let’s use adjacency lists as our implementation.

For the case of the node labeled Tom: the adjacency list would contain the node id (‘1’) and a list of each node that Tom has a relationship with (Charlie, node 3, Olivia, node 5, and Ben, node 4).  Notice that I’m only listing relationships that are “out bound” from Tom.

![adjacencyList.png](/images/AdjacencyList.png)

The following code implements a concrete instance of a Graph object called GraphAdjList.

```

package grandview;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class GraphAdjList extends Graph {

	private Map<Integer, ArrayList<Integer>> adjListMap = 
			new HashMap<Integer, ArrayList<Integer>>();
	
	@Override
	public void implementAddVertex() {
		// add a new vertex (or node) to the graph
		int v = getNumVertices();
		ArrayList<Integer> neighbors = new ArrayList<Integer>();

		adjListMap.put(v, neighbors);

	}

	@Override
	public void implementAddEdge(int v, int w) {
		// add edge w to node v
		(adjListMap.get(v)).add(w);
	}
	
	@Override
	public List<Integer> getNeighbors(int v) {
		// show the neighbors of the given node
		
		return adjListMap.get(v);
	}
		
	public void showGraph() {
		System.out.println("-----------------------");
		for (int j=0; j<adjListMap.size(); j++) {
			
			System.out.format("Vertex num = %d\n", j);
			
			for (Integer it: adjListMap.get(j)) {
				System.out.format("\tconnected to: %d\n", it);
			}
			
		}
		System.out.println("-----------------------");
	}

}

```

You should see the 3 “@Override” statements in the above code.  These are the methods we are required to implement when we extend Graph. 

# Testing

Now, we can explore testing using JUnit.  Using Eclipse, select the file GraphAdjList.java and create a new JUnit  Test Case.  Notice that Eclipse will automatically name the file: GraphAdjListTest.java.  Using the defaults we see that Eclipse provided us with a “@Test” method we can fill in. 

```

package grandview;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import org.junit.jupiter.api.Test;

class GraphAdjListTest {

	@Test
	void test() {
	}	

}


```

How do we test our code?  One of the nice things about JUnit is that we can define as many different tests as we need.  JUnit provides many more methods that could be used to define a testing framework.  For our example we are only going to use the most basic elements.

# Handling an Edge case

Let’s first see if we can create a new GraphAdjList, add a new vertex and then create the relationship between Jasper and Tom.  For simplicity we’ll just deal with the node IDs.  So we’ll make a node 0 (Jasper) and a node 1 (Tom) and connect them.

Before we implement the JUnit code to do the test, let’s write out what we are doing in prose. We want to:

+ Create a GraphAdjList

+ Add a new vertex

+ Add the relationship between Jasper and Tom

+ Check to see if the graph represents this relationship.

```

	@Test
	void testBasicRelationship() {
		GraphAdjList adjList = new GraphAdjList();
		adjList.addVertex();
		
		int numVerts = adjList.getNumVertices();
		System.out.format("number of vertices: %d\n", numVerts);
		
		adjList.addEdge(0, 1);
		// 1st, check to see if we have the right number of vertices
		assertEquals(1, numVerts);

		// check to see if the right nodes are 
		// represented on each end of the edge
		List<Integer> lst = adjList.getNeighbors(0);
		int a = lst.get(0);
		
		assertEquals(1, a);
		// print out our graph
		adjList.showGraph();
		
	}

```

Let’s explore what is going on. First, on line 3 and 4 we create a new GraphAdjList and add a vertex to it. On line 9-18 we add the relationship between Jasper, node 0 and Tom, node 1.  Last, we explore the graph to make sure the Jasper to Tom relationship is linked up correctly and print the graph.  To run this test in Eclipse, select your project in the Package Explorer, right click and select ”Run As->JUnit Test”

The above test used one of the JUnit test tools: assertEquals.  If you consult the documentation you will see there are many more JUnit tools available. The test we just created tested to see if the following methods on GraphAdjList worked correctly: the constructor, addVertex, addEdge and getNeighbors.  However, not all of the possible cases for each of these calls are tested.  For example, what if we tried to:

+ add a node with a negative ID?

+ add an edge with a negative ID?

Let’s try and add a node with a negative ID.  Here is the test case:

```

	@Test
	void testNegativeNeighbor() {
		GraphAdjList al = new GraphAdjList();
		al.addVertex();
		
		// do edge cases:
		// can I add a vertex with a negative index?
		al.addEdge(0, 1);
		al.addVertex();
		
		al.addEdge(-1, 2);
		al.showGraph();
		
	}

```

When we run this code block in eclipse we get errors.  Again, select your project in the Package Explorer, right click and use “Run As->JUnit Test”.  The JUnit tab opens and shows you “red” and a stack trace:

![GraphError.png](/images/GraphError.png)

You can use the stack trace to find what line in the code died.  In this case the test failed on line 52 (GraphAdjListTest.java), but more importantly, the graph code died on line 25 (GraphAdjList.java).  That line is trying to add an edge between node id == -1 and node id == 2.  The HashMap does not let us do this.
Now, we can refactor the code to handle this case correctly.  First, we need to udate Graph.java to test for illegal arguments and throw exceptions.  Then we can refactor GraphAdjList.java to do the test and throw the exceptions.

In Graph.java, the addEdge method now looks like this: 

public void addEdge(int v, int w) throws IllegalArgumentException { … }

In GraphAdjList.java, the implementAddEdge now looks like this:

```

	@Override
	public void implementAddEdge(int v, int w) throws IllegalArgumentException {
		// add edge w to node v
		if (v < 0) {
			throw new IllegalArgumentException("vertex id must be > 0");
		}
		if (w < 0) {
			throw new IllegalArgumentException("neighbor vertex id must be > 0");
		}
		(adjListMap.get(v)).add(w);
	}

```

# Conclusion

Generating unit level test cases is a great way to enable collaboration with in a team.  Modern frameworks for writing code, such as Eclipse, automatically enable running test cases.  Test cases also can provide a way to share information about what a piece of code was meant to do.  This post has only touched on the most simple of JUnit tools.  However, we demonstrated an unhandled edge case and how to refactor the code base to take that edge case into consideration.
