An example of how to consume a REST service and test the page with Jest

# Introduction

In a previous article we created a graph REST service.  This article will continue with that effort and show how to use ReactJS to consume the graph.  We will also show how to use Jest to do unit testing on a React application.

The REST service backend used our Graph ADT.  A graph is composed of verticies and edges.  Our example had a team of 6 people going on a qwest.  The following diagram shows our team:

![GraphOfPeople.png](/assets/GraphOfPeople.png)

Each person in the team had a name, a strength attribute and they were carrying something. In our team there are 6 vertex components, one for each team member. The relationships between the team members are shown by arrows.  These arrows are called edges.  An example of an edge is the relationship between Jasper and Tom.  Jasper is the beginning vertex in the edge and Tom is the end vertex.  The java code for a vertex looks like this (without getters and setters):

{% highlight ruby %}

public class Vertex {
	private String _name;
	private int _strength;
	private ArrayList<String> _carries = new ArrayList<String>();
	private int _ID;
	
	... (getters/setters removed)

	public Vertex(String nm, int initialID) { _ID = initialID; _name = nm; }
	public Vertex() { _ID = 0; _name = ""; }
}

{% endhighlight %}

The code for an edge looks like this:

{% highlight ruby %}


public class Edge {
	public Vertex beginning;
	public Vertex end;
	
	public Edge(Vertex v, Vertex w) { beginning = v; end = w; }	
	
    ...
}

{% endhightlight %}

The thing to notice from the above data structures for this article is how the graph represents information stored in it.  Calling the REST service would give us a graph, which is a set of Vertex objects and a set of Edge objects.

## React app

We'll use create-react-app to create a framework for our consumer.  We'll replace the generated code with our components.  Before we code the components we should decide on and define the tests.  This way we know what we are trying to achieve and the list of tests keeps on track.  The create-react-app command has testing included into the generated output. Taking a look at the directory listing of our client you see 3 App* files: App.js, App.css and App.test.js. We'll focus on App.test.js first.

One way of testing a React app is to use Jest.  Jest defines a test framework with test setup, running the test and tear down. We are going to do a very simple set of tests that examine if we can start the app and render parts of the graph.

+ does the app render without failing. This has 2 cases: if the server is running and if not
+ does the app render a graph.  This is a check to make sure that specific class names are renderd to the page
+ does the app render an adjacency list

At a high level, the above handles testing.  The other aspect of the application we have to worry about is connecting to a server and getting data.  For this article we'll use javascript's fetch function to retrieve the data.  The retrieved data will be placed in the application state, which drives React's render mechanism. At a high-level the app flow is:

+ mount & get data -> render

We are going to take advantage of React's lifecycle methods.  When the app mounts or creates itself and attaches to the DOM, we'll use fetch to get our data.  One thing to note is that React is very fast. A simple app like this can easily and render before the data is ready. Let's see that in action.  Here is a definition of our app that does not handle thing properly.

{% highlight ruby linenos %}

class App extends Component {
  constructor(props) {
    super(props)
    this.state = { graph: null, }
  }

  // use javascript fetch to get the graph from the server
  componentDidMount() {
    let url = 'http://localhost:8080/getQwestTest'

    // just fetch, no error handling here!
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
{% endhighlight %}



