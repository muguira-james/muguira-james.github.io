---
title: Create a REST service with Spring
tags:
  - REST
  - Java
categories:
  - Programming
date: 2018-10-14 13:27:12
---


Create  REST service using Spring Boot and our Graph ADT
<!-- more -->
# Introduction

We’ve been working with a Graph abstract data type (ADT).  We’ve shown how to: 

+ define the ADT in Java
+ Create unit tests, in JUnit, to demonstrate that our implementation basically functions correctly,
+ Define higher-level tests, using Cucumber and JUint, related to our overall needs (business needs),

In this article, we’ll examine how to place the ADT behind a REST service.  Defining a web service used to be an exercise in writing boilerplate before Pivotal Software defined Spring Boot. Spring Boot handles the entire boiler plating and wiring of the components together into a service.  Spring Boot envisions our ADT as a Java Bean.  It uses several additional libraries to make it easy to convert Java objects into the language of the web, JSON.

A Java Bean is a component.  It defines a standard interface with “getter/setter” access to private properties.  It is meant to be a reusable component.  In our case, we have several beans we use to realize the Graph: 

+ A Vertex, 
+ An Edge,
+ A Graph.  

Our original specification of a Vertex uses 2 constructors: create a new Vertex with default state (name=””, and id=0) or supply a name and id.  The Edge requires you to supply 2 completed Vertex.  Finally, the Graph can be constructed without any supplied parameters.  These 3 beans need to be converted into JSON if we are going to expose them to a consumer.  Spring boot uses the Jackson library to handle the conversion.  Out of the box, Jackson assumes that you have used the “getVariable” and “setVariable” convention throughout your software.  Close inspection reveals we did not do that originally.  To make our job easy, let’s redefine Vertex:

```

public class Vertex {
	private String _name;
	private int _strength;
	private ArrayList<String> _carries = new ArrayList<String>();
	private int _ID;
	
	public String getName() { return _name; }
	public ArrayList<String> getCarriedStuff() { return _carries; }
	public int getId() { return _ID; }
	public int getStrength() { return _strength; }
	
	public void setName(String n) { _name = n; }
	public void addToStuffCarried(String thing) { _carries.add(thing); }
	public void setID(int id) { _ID = id; }
	public void setStrength(int s) { _strength = s; }
	
	public void setVertex(String name, int id) { _name = name; _ID = id; }
	
	public Vertex(String nm, int initialID) { _ID = initialID; _name = nm; }
	public Vertex() { _ID = 0; _name = ""; }
}

```

Because Edge uses public instance variables we don’t have any modifications.   The Graph definition is abstract.  However, the definition of GraphAdjList required one simple modification: adding a method to return the graph so Jackson can serialize it in JSON.  We also defined an easier way to add Edges to the Graph by creating an Edge calling addEdge(Edge e).

With these changes in place we can define the Spring Boot components we need.  First, we define the overall Application class and add the Spring Boot annotations required to wire it to the Spring Framework.

```

package BackRiverContainer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ContainerApplication {

    public static void main(String[] args) {
        SpringApplication.run(ContainerApplication.class, args);
    }

}

```

Then we define the controller class.  The Spring framework uses several annotations to wire your classes.  The “RestController” annotation marks each method in the class as returning a response object or something that can be serialized in JSON.  The HTTP protocol defines that each method handles a request and a response.  Returning a response object (vs. a view) allows for further processing in the Spring framework.  

```

package BackRiverContainer;

import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import org.springframework.web.bind.annotation.GetMapping;

import org.springframework.web.bind.annotation.CrossOrigin;

import grandview.Edge;
import grandview.Vertex;
import grandview.GraphAdjList;

@RestController
public class GraphController {
	 private static final String template = "%s!";
	    private final AtomicInteger counter = new AtomicInteger();

	   @CrossOrigin(origins = "http://localhost:3000")
	    @GetMapping("/AddVertex")
	    public String AddVertex(@RequestParam(value="VertexName", 					defaultValue="Jim") String name) {
	    	
	    	Vertex v = new Vertex();
	    	v.setName(name);
	    	adjListMap.addVertex(v);
	    	
	    	return v.getName();
	    }
	    
	    @CrossOrigin(origins = "http://localhost:3000")
	    @GetMapping("/AddEdge")
	    public String AddEdge(@RequestParam String vertexName1, 				@RequestParam String vertexName2) {
	    	
	
	        Vertex v = new Vertex();
	    	v.setName(vertexName1);
	    	
	    	Vertex w = new Vertex();
	    	w.setName(vertexName2);
	    	
	    	adjListMap.addEdge(v, w);
	    	
	    	return "Edge Added";
	    }
	    
	    @CrossOrigin(origins = "http://localhost:3000")
	    @GetMapping("/getGraph")
	    public GraphAdjList getGraph() {
	    	return adjListMap;
	    }
	    
}

```

Notice there is a “GetMapping” annotation and a “CrossOrigin” annotation on each method.  The “GetMapping” annotation exposes the method name as an end point (i.e. http://localhost:port/AddVertex).  The “CrossOrigin” annotation enables “cross origin resource sharing” or CORS.  I’ve handled CORS at the method level (see: http://spring.io/guides/gs/rest-service-cors/ for details on further approaches).  This code does a poor job of handling error.  Error handling in REST is beyond this article.

To test these end points we construct a url in the browser.  For example, let’s add a few vertices and edges and retrieve the resulting graph:

```

http://localhost:8080/AddVertex?vertexName=Jasper

http://localhost:8080/AddVertex?vertexName=Tom
http://localhost:8080/AddVertex?vertexName=Charlie
http://localhost:8080/AddVertex?vertexName=Emma
http://localhost:8080/AddVertex?vertexName=Olivia
http://localhost:8080/AddVertex?vertexName=Ben

http://localhost:8080/AddEdge?vertexName1=Jasper&vertexName2=Tom

http://localhost:8080/AddEdge?vertexName1=Tom&vertexName2=Charlie
http://localhost:8080/AddEdge?vertexName1=Tom&vertexName2=Olivia
http://localhost:8080/AddEdge?vertexName1=Tom&vertexName2=Ben

And the result is:

	
numVertices	6
numEdges	4
graph	
Olivia	[]
Jasper	
0	
beginning	
name	"Jasper"
id	0
strength	0
carriedStuff	[]
end	
name	"Tom"
id	0
strength	0
carriedStuff	[]
Tom	
0	
beginning	
name	"Tom"
id	0
strength	0
carriedStuff	[]
end	
name	"Charlie"
id	0
strength	0
carriedStuff	[]
1	
beginning	
name	"Tom"
id	0
strength	0
carriedStuff	[]
end	
name	"Olivia"
id	0
strength	0
carriedStuff	[]
2	
beginning	
name	"Tom"
id	0
strength	0
carriedStuff	[]
end	
name	"Ben"
id	0
strength	0
carriedStuff	[]
Charlie	[]
Ben	[]
Emma	[]


```

To see the connections, you have to find each “beginning / end” pair for each Edge.  Not the easiest output to parse! However, the graph is connected and again, there is no error handling.

## Conclusion

Spring Boot really does make creating REST services easy.  This article has covered some of the more useful Spring Boot annotations and shown how to make simple java beans for realizing the REST service components.  There is a lot more that can be done in this space and I would encourage you to consult the excellent Spring Boot guides (see http://spring.io/guides ).
