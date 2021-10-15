---
title: Consuming a REST service with React and testing with Jest
tags:
  - React
  - Jest
date: 2018-10-18 13:27:12
---


An example of how to consume a REST service and test the page with Jest
<!-- more -->

# Introduction

In a previous article we created a graph REST service.  This article will continue with that effort and show how to use ReactJS to consume the graph.  We will also show how to use Jest to do unit testing on a React application.  The code for this article is on ( [github]( https://github.com/muguira-james/GraphsTesting_Java
).  Look inside the "BackRiver" repo for the client directory.

The REST service backend used our Graph ADT.  A graph is composed of vertices and edges.  Our example had a team of 6 people going on a qwest.  The following diagram shows our team:

![GraphOfPeople.png](/images/GraphOfPeople.png)

Each person in the team had a [name, a strength attribute and they were carrying something]. In our team there are 6 vertex components, one for each team member. Arrows show the relationships between the team members.  These arrows are called edges.  An example of an edge is the relationship between Jasper and Tom.  Jasper is the beginning vertex in the edge and Tom is the end vertex.  The java code for a vertex looks like this (without getters and setters):

```

public class Vertex {
	private String _name;
	private int _strength;
	private ArrayList<String> _carries = new ArrayList<String>();
	private int _ID;
	
	... (getters/setters removed)

	public Vertex(String nm, int initialID) { _ID = initialID; _name = nm; }
	public Vertex() { _ID = 0; _name = ""; }
}

```

The code for an edge looks like this:

```


public class Edge {
	public Vertex beginning;
	public Vertex end;
	
	public Edge(Vertex v, Vertex w) { beginning = v; end = w; }	
	
    ...
}

```

A graph is a data structure to hold information and relationships between information.  The nodes, or vertices, hold information and the edges represent the relationships.  Calling the REST service would give us a graph, composed of Vertex objects and a set of Edge objects.

## React app

We'll use create-react-app to create a framework for our consumer.  We'll replace the generated code with our components.  Before we code the components we should decide on and define the tests.  This way we know what we are trying to achieve and the list of tests keeps on track.  The create-react-app command has testing included into the generated output. Taking a look at the directory listing of our client you see 3 App* files: App.js, App.css and App.test.js. We'll focus on App.test.js first.

One way of testing a React app is to use Jest.  Jest defines a test framework with test setup, running the test and tear down. We are going to do a very simple set of tests:

+ Does the app render without failing. This has 2 cases: if the server is running and if not
+ Is the app able to gather data from a server
+ Does the app render a graph.  This is a check to make sure that specific class names are rendered to the page
+ does the app render an adjacency list

At a high level, the above handles basic unit testing.  The other aspect of the application we have to worry about is connecting to a server and getting data.  For this article we'll use javascript's fetch function to retrieve the data.  The retrieved data will be placed in the application state, which drives React's render mechanism. At a high-level the app flow is:

+ mount & get data -> render

We are going to take advantage of React's lifecycle methods to accomplish gathering server data.  When the app mounts or creates itself and attaches to the DOM, we'll use fetch to get our data.  

## Testing with Jest

We have the server we wrote from before and we have a few tests. The create-react-app comes pre-wired with Jest setup.  If you are running the app we issue: "npm start".  If you want to test you issue: "npm test".  This is some setup that should happen.  You have to write a test file, in our case it is called App.test.js.  The Jest framework knows to look for files that end in *.test.js.  That file starts out like any other React program, we import required libraries.  We are also going to use a test tool called enzyme. Here is our setup file: called enzyme.js:

```

import Enzyme, { configure, shallow, mount, render } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';

configure({ adapter: new Adapter() });
export { shallow, mount, render };
export default Enzyme;

```

We import required libraries, configure the right adaptor and export or make several parts of the library visible to our test environment.

### React is fast!

One thing to note is that React is very fast. A simple app like this can easily render before the data is ready. Let's see that in action.  First, turn off the server if you have it running.  Here is a definition of our app that does not handle things properly.  Do an "npm start"

```javascript=

class App extends Component {
  constructor(props) {
    super(props)
    this.state = { graph: null, }
  }

  // use javascript fetch to get the graph from the server
  componentDidMount() {
    let url = 'http://localhost:8080/getQwestTest'

    // just fetch, no error handling here!  We'll never know if the fetch fails
    // when the fetch completes, put the graph in "state"
    fetch(url)
      .then(response => response.json())
      .then((resp) => {
        console.log("g->", resp.graph)
        this.setState({ graph: resp.graph })
      })

  }
  render() {

    // if (this.state.graph === null) {
    //   return (<p>nothing here yet</p>)
    // }
    return (
      <div>
        <ShowGraph graph={this.state.graph} />
      </div>
    );
  }
}

export default App;
```

In this state, before the fetch can complete, React has tried to render the graph.  The app fails because there is no data associated with "this.state.graph".  Once we uncomment lines 23-25 the app does not fail.  But since we did not start the server the app simply displays "nothing here yet". 

This first test shows that the app handles problems gracefully. What does this look like in Jest?  Jest testing is almost another programming language.  We write a file full of tests.  In this case the first test is does the app render without failing.  It looks like:

```


describe("Graph Tests", () => {
  test('renders without crashing', () => {
    const div = document.createElement('div');
    ReactDOM.render(<App />, div);
    ReactDOM.unmountComponentAtNode(div);
  });

```

Jest uses a "Describe() test(), ..., test()" structure.  You describe in a high level way what is tested and then fill in individual tests.  The above code creates a DOM div element and tries to render the app on that div.  If it renders with error the test passes.  The next test is more involved: we define a small graph with a vertex named "Olivia" and a single relationship between Olivia and Tom. The test checks to make sure the output DOM contains a single node of class of graph-vertex.

```

  test('renders a graph vertex', () => {
    const g = { Olivia: [{ beginning: { name: "Olivia", id: 1 }, end: { name: 'Tom', id: 2}}]}
    const wrapper = mount((<ShowGraph graph={g} />));
  
    const t = wrapper.find('.graph-vertex')
    
    expect((t.children()).length).toBe(1)
  });

  ```


The last test is to render an adjacency list.  We create the list, use Jest mount to render the ShowAdjacent component and test to see if we have the proper class name and text.

```

  test('render adjacent', () => {
    let graph = [ { beginning: {name: 'Olivia' }, end: {name: 'Ben'}}, ] 
    
    const wrapper = mount(<ShowAdjacent graph={graph} />)
    
    const t = wrapper.find('.graph-edge')
    expect(wrapper.find('.graph-edge')).toBeDefined()
    expect(t.text()).toBe('Ben')
  })

 ```

If the DOM contains the correct elements after the "mount" the test passes.  

To use Jest, instead of starting your app with "npm start" you use "npm test".  The React app create-react-app included the required functionality into you environment for you.  Your package.json file includes a scripts section with a "test" section that runs "react-scripts test".  Issuing a "npm test" command at the command prompt will generate the following output: 

```
  RUNS  src/App.test.js

Test Suites: 0 of 1 total
Tests:       0 total
Snapshots:   0 total
  console.log src/ShowGraph.js:11
    i-> Olivia

  console.log src/ShowAdjacent.js:6
    t-> { graph: [ { beginning: [Object], end: [Object] } ] }

  console.log src/ShowGraph.js:11
    i-> Olivia

 PASS  src/App.test.jsAdjacent.js:6
  Graph Tests
    ✓ renders without crashing (104ms)
    ✓ renders a graph vertex (33ms)
    ✓ render adjacent (7ms)

Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
Snapshots:   0 total
Time:        2.411s
Ran all test suites.

Watch Usage: Press w to show more.
```

Jest will continue to try tests as you save your work.  Our setup defines a single test suit composed of specific tests.  As you can see, Jest exposes console.log messages and a debug object. This can be useful to determine what is happening during the test and to provide additional documentation.

# Conclusion

Jest has many verbs for creating tests.  This article just described a very basic testing structure. Testing using frameworks like Jest provide a great way to determine if software is functioning properly. Unit tests provide engineers with a means to ensure components work at a basic level.  As components are joined together to form larger systems, integration testing and behavior testing ensure that the software meets business requirements and delivers proper functionality.
