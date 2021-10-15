---
title: Why are containers important
tags:
  - Containers
categories:
  - Containers
date: 2017-11-28 13:27:12
---



Explain micro-services and containers
<!-- more -->
Why all of the hype surrounding containers as a means to deliver valuable services to an enterprise customer? Reading the technologies news to date, you often stumble upon an article dealing with containers. This article will break down what containers are and why senior managers and CIO’s need to have a high-level understanding of their benefits.

For years now technology companies have been selling systems that solve technology problems like relational data models, enterprise service bus systems, service oriented architecture and a long list of technology building blocks. These technology building blocks produce a disconnect between the service the organization Is striving to deliver and the components used to organize the data boundaries and data integration for the service.

Traditional enterprise systems organize data boundaries at the edge of the legacy system. A relational database forces the business analyst to apply a specific set of data boundaries to the organizational data, the relational model. Data integration was between relational models. As an example, each department within the organization maintained a relational model of their data. The business analyst created processes to transform one relational model into another as a customer generated purchase transactions.

Modern systems design liberally applies modularization to data boundaries and the integration points needed to deliver services. A service would be composed of modules that span departments within the organization. Data is not bounded at the department level, but at a finer grained transaction level.  Each customer transaction is broken down into sub-transactions. Each department contributes sub-transaction processing modules, which combine to deliver the service. Each module defines an event interface and a set of events it outputs.

Containers are a way to organize data boundaries and integrate across organizational department boundaries. Containers package the modules that each department contributes to the data integration aspects of each customer transaction. The individual container is composed of libraries and business logic to maintain the state of the transaction. From an enterprise operations point of view, the container brings a lot of value. 

·     It isolates systems and enhances security,

·     All software dependencies have to be resolved inside the container for enterprise software to run correctly,

·     It encourages the application / system architect to create modular software,

·     It encourages organizational departs to work together around data boundaries.

One large advantage of containers over Virtual Machines (VMs) is that the container is lighter and uses far less system resources that a VM. The VM is composed of a complete operating system and application software. The container is composed of only the application software ( see Figure 1). Moving the operating system software outside of the container allows the container to be managed as a resource by an orchestration system, such as Kubernetes or Amazon ECS. Where the container runs, how many are run, when it runs all become an orchestration problem.


![ContainerVsVM.png](/images/ContainerVsVM.png)

Figure 1. Container verses VM

Our Service

Let’s consider an enterprise service that delivers the day’s current news organized in different ways: as groups of news articles on a specific topic, news articles grouped by geographic region, by country, by business or other organization, and news articles organized as meta-topics (groups of the above combined). The service is composed of news trawlers, which gather and analyze news and a data base to store the final products.

In our case, the trawler will be placed into a container. The data base could also be placed in a container. This article will only consider the trawler software. The trawler is composed of components that handle gathering the raw news articles and natural language processing components that extract things like topic, summary, region, person, place or organization information. These components all send organized output to the database.

Containerizing the trawler presents several design problems that need to be solved:

·     the trawler’s development components each have dependencies such as libraries and frameworks that have to be included,

·     the trawler has a set of configuration parameters that need to be organized and maintained, and

·     the trawler uses a database connection.

For the trawler to be able to run correctly, all sub-components, such as libraries and frameworks have to be added to the container. Most container systems, such as Docker and rkt, provide a language that can configure a container. As a concrete example, our news trawler, which is written in python, depends on: Beautiful Soup, feedparser, and Spacey among others. To configure a container, these components all need to be installed in the container. The trawler also maintains a run-time configuration for such things as news sources to gather articles from, the level of debug logging to generate, and the access information for the database. To interoperate with container orchestration systems, such as Kubernetes or Amazon ECS, our trawler needs to be written so it can gather these configuration settings from the run-time environment setup by the orchestration system.  Container orchestration systems configure and maintain networks to connect service components together. This means that our news trawler should use the network environment created by the orchestration system to find database access information (see Figure 2).


![CreatingANewsGraph.png](/images/CreatingANewsGraph.png)

Figure 2. Container composition and environment.



Conclusion



Legacy systems used building blocks such as relational database systems and enterprise service bus systems to organize and maintain state within a department. This design paradigm encouraged the business analyst to organize enterprise data models along department boundaries. It also encouraged the analyst to create inefficient processes that transform information as it crossed differing department data models. Containers shift the data and integration boundaries toward finer grained transactions. Each department within the organization contributes components to the transaction model to process and integrate data to provide the service. This article considers the choices a systems designer would make to move an existing application service component into a container. It exposes the container as a component in a larger enterprise level resource orchestration system. The orchestration system maintains a run-time environment. Containerizing enterprise services is a process of breaking the business processes down into smaller transactions that cross departments. Then identifying component processing that each department needs to contribute. The containerized services also need to conform to the environmental constraints of the orchestration system. This article provided a first look into the engineering path leading to cloud capable systems.