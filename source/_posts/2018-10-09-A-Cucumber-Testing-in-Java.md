---
title: Cucumber Testing in Java
tags:
  - Cucumber
  - Java
categories:
  - Programming
date: 2018-10-09 13:27:12
---


Use Cucumber + JUint and Behavior Driven Development
<!-- more -->
## Introduction

Let’s continue with our testing exercise.  The last post described how to add unit test cases to a java class.  It used the various tools and annotations available in JUnit 5.0 to validate the behavior of the java class at a very low level.  This project is going to change it up and work with higher-level test concepts. We are going to be working in Behavior Driven Development (BDD) and creating Feature Files in the Gherkin testing language.


The sample code for this article can be found on: ( [link to github]( https://github.com/muguira-james/GraphsTesting_Java ))


Most of the projects I work on are oriented toward creating software to help a business accomplish some task.  Stakeholders and business analysts interact to solidify the business need and the proper behavior for the new system. These needs are captured and slowly transformed into a specification that engineers can use to create software. In an agile paradigm, these behavior specifications are captured in use cases, which are translated into user stories.  The business analyst and development team translate these user stories into features and finally, into working software.

A software creation method called BDD uses feature files (written in Gherkin) to bridge the gap from business need specification to software development need specification. Feature files have a particular format: 

+ Feature – Name of the Feature (or business case)
+ Scenario – description of the feature
+ Given – specify the initial conditions
+ When – specify some action or interaction with the feature
+ Then – specify the result of the action or interaction.

So, the feature file is a mapping of business use cases down to testable software modules.  The business analyst is the bridge between the stakeholders and the developers.  They work with the stakeholders to capture business use cases, translating those to features.  Then, they work with the developers to translate features into tests.

The rest of the article will describe how to work with Eclipse and JUnit to incorporate BDD into the development process. 

## Our Scenario

Using the graph from our previous article, let’s build a story and then a business case that we can use for BDD.  In Figure 1, we see the graph that describes the relationships between 5 characters.  These characters are gathered together to go on a quest for treasure. From the figure, we see that Tom is a central character.  Tom is a very skilled thief and always carries a sack.  Charlie and Emma are both powerful mages.  Olivia is also a mage.  Ben is a human and is currently carrying food.  Finally, Jasper is a swordsman.
![GraphOfPeople.png](/images/GraphOfPeople.png)

## Some Business Rules

For a graph representation, we want to capture relationships between our characters.  We would also like to show these relationships.  In our low-level testing, we examined how to verify the correct working of our graph software by testing the operation of adding vertices, adding edges between vertices and asking for a list of neighbors of any vertex.  At a higher level, we are specifying use cases like in figure 2.

![Use_Case.png](/images/Use_Case.png)

From our use case diagram, we have 4 cases or features we want the system to implement: 

+ Create a character, 
+ Add character to a graph, 
+ Add an edge or relationship between two characters
+ Show the graph.  

Let’s take each of the top 3 items and state them in Gherkin Feature file format.  Show the graph is just a print to the console.

# Create a character

The first test is creating a character.  A character has a name, a relative strength and is carrying something.  The feature file looks like the following:

```

Feature: Create a character
Create a character, by filling in a Graph Vertex

Scenario: Create a character
Given: A Name, a strength and something to carry
When: Add the  name, strength and carried item to a vertex
Then: Test to see if the vertex is initialized properly

```

The first line of the feature file has to say “Feature:”.  We describe the feature and provide a Scenario.  Following those, we provide the Given, When and Then clauses.  These last 3 (Given, When Then) form the basis of the test for this feature.  

# Add a character to the graph

The feature file is similar:

```

Feature: Add a character to the Graph
Take the vertex containing the character and add it to the graph

Scenario: add vertex
Given: a filled in Vertex
When: I add it to the Graph
Then: the graph number of Vertex count should increase

```

# Add an edge or relationship between two characters

The Feature file:

```

Feature: Add an edge
Connect to characters

Scenario: fill in an Edge 
Given: 2 filled in Vertex, and a complete Edge
When: I add them to the Graph
Then: the Graph should reflect the new relationship

```

Although I have not told you how to organize this material in the project yet, if you were to run the project at this point it would do nothing.  The Feature file indicates the tests that we want to run.  It does not define the actual tests.  The last step would be to code the actual tests. The tests are organized as steps (the given step, the when step, the then step).  In this case, we’ll lump all of the tests for each Feature into a single file.  The CreateCharacter step definition file would look like this:

```

public class StepDefs_createCharacter {
	
	private String name;
	private int strength;
	private List<String> carried = new ArrayList<String>();
	
	private Vertex v;

	@Given("^A Name, a strength and something to carry$")
	public void A_Name_A_Strength_and_something_to_Carry() throws Exception {
		System.out.println("given: A Name, a strength and something to carry");
		
		name = "Jasper";
		strength = 11;
		carried.add("sword");
	}
	
	@When("^Add the  name, strength and carried item to a vertex$")
	public void Add_the_name_strength_and_carried_item_to_a_vertex() throws Exception {
		System.out.println("when: Add the  name, strength and carried item to a vertex");
		
		v = new Vertex(name, 0);
		v.setStrength(11);
		v.addToStuffCarried("sword");
	}
	
	@Then("^Test to see if the vertex is initialized properly$")
	public void Test_to_see_if_the_vertex_is_initialized_properly() throws Exception {
		System.out.println("given: Test to see if the vertex is initialized properly");
		
		
		String n = v.name();
		int strength = v.strength();
		ArrayList<String> items = v.getCarriedStuff();
		
		assertEquals("Japser", n);
		assertEquals(11, strength);
		assertEquals("sword", items.get(0));
		
		
	}
	
}

```
The “step definition” carries out the actual test.  I sets up the variables: name and strength. It then creates a Vertex with the data.  Finally, this step definition checks to see that the Vertex is organized correctly.  Each of the other step definition files are similar in structure. 

# Project Structure

In order to run the system with all of the tests you need to devise a structure.  You can use Eclipse to facilitate this.  I will choose Gradle since it aligns with the Continuous Integration and Continuous Deployment (CI/CD) used by most project teams.  Figure 3 gives you an idea of how to structure the project.  The main idea is to create 3 parts: a resource directory to contain the feature file; and 2 test packages to contain the TestRunner that corresponds to the feature specification and step definitions. 

![ProjectStructure](/images/ProjectStructure.png)

Let’s examine the feature specification for TestRunner_createCharacter.  The test runner is a part of JUnit.  I created one TestRunner for each Feature file definition in the resource directory.  Each TestRunner is tied to its Feature definition by the annotation “@CucumberOptions”.  Furthermore, the TestRunner is tied to the step definition in the same annotation.

```

package testRunners;

import org.junit.runner.RunWith;
import cucumber.api.CucumberOptions;
import cucumber.api.PendingException;
import cucumber.api.junit.Cucumber;

@RunWith(Cucumber.class)
@CucumberOptions(features="resources/features", glue="src/test/java/stepDefinitions")
public class TestRunner_createCharacter {

}

```

This project was created as a gradle project in Eclipse.  Once this infrastructure is in place you can use the “Gradle Tasks” tab in Console output area to run the all the tests, just double click on the word “test” (see figure 3).  If you want to run a single test right click on the specific test runner file in the Package Explorer and select “Run As->Gradle Test”.

![GradleTasksTab.png](/images/GradleTasksTab.png)

After the task has run you should see the following (see figure 4)

![SuccessfulGradleRun.png](/images/SuccessfulGradleRun.png)

## Conclusion

This article introduced you to BDD.  We modeled the business problem as a UML use case, and then transformed that diagram into a BDD Feature File in the Gherkin language.  We demonstrated a possible way to organize the project so that gradle could automatically compile and run the tests.

.

