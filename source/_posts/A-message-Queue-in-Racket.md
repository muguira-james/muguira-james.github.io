---
title: Using Racket to define a message queue - part 1
date: 2021-10-13 10:26:28
tags:
  - Racket
categories:
  - Programming
  - message queue
---


This post is the first in a series describing the creation of a message queue 
<!-- more -->
# A Message queue in Racket

This post will explore creating a message queuing application in the Racket programming language.  Racket is a dialect of scheme.  Racket is very well documented on Racket.org. 

This is not a tutorial on Racket, the environment, or the language. This post will build up the infrastructure for our message queuing application in several sections. A message queue defines a system that can store messages to specific topics and allow you retrieve these messages in order. The internal data structures used by the messaging system are a hash-table of topics and inside of each hash-table item, a queue to hold the messages for that topic.  The interface to the message queue will provide an API 

* to add / delete messages from a topic
* check the number of messages in a topic queue
* get a list of the current topics known to the system at that moment
* remove topics from the system
* remove all the items from a specific topic.

The message queue system presents a simple web application interface that utilizes HTTP as an interface and JSON as the low-level data communication language. We will build out the system in sections expanding the capability of our application and demonstrate how to test and verify the code. The final installment will demonstrate how package the system in a container for deployment.

## Table contents:
* The infrastructure
* Dispatching
* The start of the API
* Conclusion

## The web application shell

To start, let’s define a very simple web application using Racket and its supporting HTTP libraries and understand how it works.

```
#lang racket

; bring in the required support code to handle socket and HTTP
(require web-server/servlet

         web-server/servlet-env)
 
; This replies to http get requests with a simple message
(define (my-app req)

  (response/xexpr

   `(html (head (title "Hello world!"))
          (body (p "Hey out there!")))))
 
; start the server and use ‘my-app’ when we get a http  request
(serve/servlet my-app)


```
The Racket language defines several packages that aid us in creating a web application.  While there are easier ways to start using Racket in a web context, we are going use packages that allows us configuration possibilities later. The sample code just presented loads two packages: the “web-server/servlet” and “web-server/servlet-env” packages.  These packages create an abstraction of a web server.  In this simple case, the server creates something called a servlet, which is a bit of code that replies to a browser request. Our first servlet changes the title of the page to “Hello World”. It also prints the message: “Hey out there”.

## Moving the code structure toward an API

If we run this in the “DrRacket” environment, the default browser opens with the page displayed. 

This behavior will not suit us as we create messaging API. Let’s move closer to the infrastructure we need for the API. If you look at the URL in the browser, you will see it says: http://localhost:8000/servlets/standalone.rkt.  

Let’s take advantage of Racket’s flexibility. Start by changing the default port the web server is running on. We can change it by adding the scheme symbol: #:port to the last line. This way we have a way to set the port at run-time later when we package the system for deployment. Then, let’s change the URL from: “servlets/standalone.rkt” to “hello”. Last, we don’t want to open a browser each time we start the server. Making all these changes results in the following server start line:

```
(serve/servlet my-app 
      #:port 8000 
      #:servlet-path  “/hello” 
      #:launch-browser #f)

```
That’s better for the messaging API we’ll develop later in this article.

# Dispatching

In general, a web server is a piece of code that accepts requests and dispatches each request out to handler code for processing.  The handler code might take the incoming payload from the caller and place it in a queue. It might even query a queue and return the queried contents to the caller.  Our message queuing system will allow you to organize messages into different topics. Each topic will have a queue to save the messages. Another example of a handler might to be create a list of topics currently known to the system.

Let’s establish some architecture for our message queue.
 
 ![MQ-ARCH.png](/images/MQ-Architecture-1.png)

The system has a front door, which handles processing HTTP requests and returning HTTP responses. There is a middle layer that handles management of the topic hash-table and specific messages under each topic. The message queue is designed to be a component running on a server. We don’t have a graphical front end, but we will need to write a few short programs to drive our API for testing. We’ll get to these later.

For our purpose, let’s define a method that will reply with a simple “hello” string. This string will be used later to determine is the message queue is healthy.  The format of the output string will be “hello <date-time>”.  The date and time can be checked by the caller to determine if there is any lag.  By convention, we’ll assume that we only accept and reply using ASCII characters.  Later, this program will make use of JSON and using ASCII now will simplify our efforts.

# Starting the API code

With our architecture in place, we can start to design our dispatch and API handlers. The front door component of our architecture presents the API to the caller.  The caller is a web app, such as a node JS, python, or Java application. The caller forms a HTTP GET / PUT request and sends it to the front door. It is the front door’s job to validate the request and dispatch it to the correct handler. The handler manipulates the topic hash and hands it results back to the caller.  
The architecture defines a simple language to interact with the message queue.  As a BNF:

* Message: User_command || Admin_command

* User_command: ENQUEUE || DEQUEUE || TOPIC_DATA || QUEUE_DRAIN
* ENQUEUE: TOPIC_NAME PAYLOAD, a HTTP POST method call, returns status of “OK” or “Fail”
* DEQUEUUE: TOPIC_NAME, a HTTP POST method call, returns the first item on the queue.
* QUEUE_DRAIN: TOPIC_NAME, a HTTP POST method call, returns the number of items removed

* Admin_command: TOPIC_LIST || TOPIC_COUNT || TOPIC_DRAIN
* TOPIC_LIST: TOPIC_NAME, a HTTP POST method call, returns a JSON list of topics currently in the system
* TOPIC_COUNT: TOPIC_NAME, a HTTP POST method call, returns integer count of items in the named topic
* TOPIC_DRAIN: TOPIC_NAME, a HTTP POST method call, returns the number of removed items in the topic 

* TOPIC_NAME: ASCII string naming a topic, if the topic is not present it is created
* PAYLOAD: ASCII JSON string

The caller forms a message that contains a topic, and a payload which will be placed in the queue on that topic.  For example, we might want to make a to-do topic and place items we want to accomplish today on our to-do topic. The front door would present an “enqueue” API call that accepts a bit of JSON.  In JSON notation, a request to add an item to our to-do list might look like:

```
{
	topic: “To-Do”,
	payload: “study for our CS mid-term”
}

```
The architecture of the front door should be simple. We receive a URL from the lower-level HTTP libraries and use dispatch to select and handle the specifics of the request. Before we create that code let’s attack sending responses back to the caller. We want our response to be in a standard form so a program-based caller can process it. HTTP responses are all formatted in a standard way:

* A return code, which can be either: 200, 300, 400 or 500,
* A return message, such as “OK”,
* A time stamp,
* The type of the response, for example “TEXT/HTML-MIME_TYPE” or “APPLICATION-JSON”
* Additional headers if needed,
* The content of the response in 8-bit bytes

The Racket code we will use looks like this;

```
(define (http-response content)  
  (response/full
    200                  		; HTTP response code.
    #"OK"                		; HTTP response message.
    (current-seconds)    		; Timestamp.
    TEXT/HTML-MIME-TYPE  	    ; MIME type for content.
    '()                     	; Additional HTTP headers.
    (list                		; Content (in bytes) to send to the browser.
      (string->bytes/utf-8 content))))

```
The routine takes the content as input and outputs a string as 8-bit ASCII. Later we will extend this to catch and trap errors. That extension will require us changing the response code and response message in case of problems. We will also extend this response code to write a log file.

Now that we have a stand way to form responses let’s address a simple deployment aspect. The first API call we will create will help us monitor the API. It is very simple, for any call to the “monitoring” API, the handler will create a string that consists of the world “hello” and the date and time. It looks like this:

```
(define (monitoring request)
  ; just say something useful
  (http-response "Hello: (today/utc))"))

```
The date and time are supplied by the (require gregor) package reference.  To use this in the DrRacket editor you need to use the package manager and load in gregor-lib. With the library loaded, the monitoring API will utilize the http-response method we just wrote to create a simple message for output.

## Conclusion

We have started on our journey to use Racket to create a message queue component.  The article has created a simple web application and an architecture for the message queue.  The application presents a simple monitoring API endpoint that responses with a "Hello" message when called. We’ve also created a standard way to format responses to the caller that we can use from each API endpoint we define.

The next article will define an enqueue and a dequeue API call and redefine the architecture to handling testing of our end-points.

