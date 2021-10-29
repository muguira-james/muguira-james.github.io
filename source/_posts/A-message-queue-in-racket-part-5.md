---
title: A-message-queue-in-racket-part-5
date: 2021-10-25 12:31:45
tags:
  - Racket
categories:
  - Programming
  - message queue
---

The 5th article in the series, testing
<!-- more -->

# Table of Contents

* Code organization, racket require and provide
* Test cases
* Github Actions
* Conclusion

# Introduction

Up to this point we have created a working message queue.  It uses Racket's http stack and presents a simple to use http POST API to add / delete messages in topics. It also has an administrative API to explore and manipulate the topic list and data stored in queues under specific topics.

The system is architected as a front-door that defines the http interface. The middleware defines the logic to handle manipulating the hash table. Last, we implement a Racket hash table to organize the message queue.

This article will expand on that base by adding testing. We use the Racket rackunit test suite.

# Preliminaries

Last article, we spilt the code into 2 files, front-door.rkt and middleware.rkt. The front-door code handles http interfacing. We are not going to test that functionality with rackunit.

We will use rackunit to test the middleware functionality. The rackunit test suite provides a rich set of verbs to evaluate the state of the system. Rackunit provides:

* a basic capability to check if variables or statement evaluate properly
* a test-case verb to group tests together
* a test-suite verb to group test around a theme.

I recommend you consult the Racket documentation for further [details](https://docs.racket-lang.org/rackunit/). We are going to keep our tests simple. We'll evaluate the functionality of each method in the middleware.rkt file, developing tests and evaluating edge cases. This set of tests will be very simple, really just a demonstration. Rackunit has as much capability as any competing test framework I have used.

The test file we'll use is called test-middleware.rkt. As I said before, it will contain tests for each method in the middleware module. To use rackunit, we have to first 'require' it in. We then require in any Racket support libraries. Finally we require in the middleware.rkt module. Requiring "middleware.rkt" will bring in all of the definitions and variables that are exposed through a "provide" statement.

```
#lang racket

(require rackunit)

(require web-server/servlet) 
(require web-server/servlet-env)
(require json)
(require data/queue)

(require "middleware.rkt")


```

Now we can create our first test. Contains-topic inspects the topic-hash to see if a specific topic-name exists.

```
(test-case "middleware: contains-topic"
           ; setup by adding a topic 'key and an element 'aaa
           (add-data-to-topic 'key 'aaa)
           (check-equal? (contains-topic 'key) #t "should contain the test topic")
           (check-equal? (contains-topic 'foo) #f "should not contain 'foo' topic")
           (check-equal? (hash-count topic-hash) 1 "should only be a single topic")
           ; clean up before next test
           (hash-remove! topic-hash 'key)
           )
```

We first, add a topic named 'key and add some data 'aaa. Then we evaluate different rackunit check-equal clauses to determine if the topic hash is setup correctly.  In this case, we ask:

* is there only 1 topic name
* there should not be a 'foo topic, we did not add that
* the topic-hash should only have a single topic

Finally, if each of these test cases pass, we clean up the topic-hash to get it ready for the next test.  It is a best practice to leave your data structures in a known state at the end of each test. Don't string tests together, unless you are using rackunit verbs like "test-suite".

next we test add-data-to-topic. There is a lot to test here...

```
(test-case "middleware: add-data-to-topic"
           ; first, should be nothing in the topic hash
           (check-equal? (hash-count  topic-hash) 0 "should be empty")

           ; add a single topic and 1 item
           (add-data-to-topic 'key 'aaa)
           (check-equal? (hash-count topic-hash) 1 "should only be a single topic")
           (check-equal? (queue-length (hash-ref topic-hash 'key)) 1 "should only be a  single item in the queue")

           ; add a 2nd item to the test topic
           (add-data-to-topic 'key 'bbb)
           (check-equal? (hash-count topic-hash) 1 "should be a single topic")
           (check-equal? (queue-length (hash-ref topic-hash 'key)) 2 "should only be a  single item in the queue")

           (add-data-to-topic 'key2 'zzz)
           (check-equal? (hash-count topic-hash) 2 "should be 2 topics now")
           (check-equal? (queue-length (hash-ref topic-hash 'key)) 2 "should only be 2 items in the 'key queue")
           (check-equal? (queue-length (hash-ref topic-hash 'key2)) 1 "should only be 1 item in the 'key2 queue")

           (add-data-to-topic 'key2 "go man go")
           (check-equal? (queue-length (hash-ref topic-hash 'key2)) 2 "should be 2 items in the 'key2 queue")

           (add-data-to-topic 'key2 "[ 'foo 'bar ]")
           (check-equal? (queue-length (hash-ref topic-hash 'key2)) 3 "should be 2 items in the 'key2 queue")
           (check-equal? (dequeue! (hash-ref topic-hash 'key2)) 'zzz "should be the first string zzz")

           
           (hash-remove! topic-hash 'key)
           (hash-remove! topic-hash 'key2)
           )
```

First, make sure the topic-hash is clear. Then, add a key and data and test to make sure there is only 1 key and 1 piece of data. Going on, add a 2nd data item and test. Then add a 2nd key + data and evaluate the topic-hash state to make sure it is correct. Finally, clean up the topic-hash, to prepare for the next test.

The method to test remove-data-from-topic. The topic-hash should have the input topic present and there should be data in the queue associated with the topic. Here is the original remove code:

```
(define (remove-data-from-topic topic-name)
  (if (contains-topic topic-name)
      (begin
        (let* ([datam (dequeue! (get-queue-for-topic topic-name))])
          ;(displayln (format "::->~v" datam)
          datam))
      (begin
        (let* ([rtn (format "did not find topic ~v~%" topic-name)])
          (display rtn)
          rtn))))
```

It may not be obvious, but this code does not work correctly. The code says: "if there is a topic by this name, dequeue the first thing on the queue and return it". The tests we will run follow:

```
(test-case "middleware: remove-data-from-topic"
           ; first, should be nothing in the topic hash
           (check-equal? (hash-count  topic-hash) 0 "should be empty")

           ; add a single topic and 1 item
           (add-data-to-topic 'key 'aaa)
           (check-equal? (hash-count topic-hash) 1 "should only be a single topic")
           (check-equal? (queue-length (hash-ref topic-hash 'key)) 1 "should only be a  single item in the queue")

           ; ... now remove stuff

           (check-equal? (remove-data-from-topic 'key) 'aaa  "remove only item in the  queue")

           ; now remove another item - this should fail.
           ;(check-equal? (remove-data-from-topic 'key) "{ \"error\": \"no data in queue 'key\" }\n" "should be nothing in the queue")
           )
```

When we run the tests, we can use 'DrRacket' or run from the command line. If we run from the command line, we see the following:

```
$ raco test: "test-middleware.rkt"
raco test: "test-middleware.rkt"
--------------------
middleware: remove-data-from-topic
ERROR
name:       check-equal?
location:   test-middleware.rkt:63:11

dequeue!: expected argument of type <non-empty queue>; given: #<queue>
1/3 test failures

```
The test output shows that we had an error.  The Racket system found an empty queue and stopped the tests. If we look at the code we see that we did not test to see if the queue was empty, we just try to dequeue the next item.

To fix this, let's test the queue first before we try to pop something off it. We can use "queue-empty?". If the queue is empty, no point in trying to pop an item off, just return the error string.

```
(define (remove-data-from-topic topic-name)
  ; do we have this topic?
  (if (contains-topic topic-name)
      ; is there something in the queue?
      (if (queue-empty? (get-queue-for-topic topic-name))
          ; no return an error
          (let* ([rtn (format "{ \"error\": \"no data in queue ~v\" }~%" topic-name)])
            (displayln rtn)
            rtn)
          ; yes, build a valid return  json
          (format  "{ \"topic-name\": ~s \"payload\": ~v }" topic-name (dequeue! (get-queue-for-topic topic-name)))

          )
      (begin
        (let* ([rtn (format "{ \"error\": \"did not find topic ~v~%" topic-name)])
          (display rtn)
          rtn))))

```

Ok, found and fixed that bug. Now, let's examine geet-queue-for-topic. If it SHOULD return a valid queue if the topic is present. But the way it is coded, if the topic is not present, we generate an error.


```
(define (get-queue-for-topic topic-name)
  ; just return the queue for this topic,
  ;  somebody  else has to check to see if the topic-name exists
      (hash-ref topic-hash topic-name))
```

Not good! Since we always test the returned queue to see if it is empty let's always return a valid queue. New code:

```
(define (get-queue-for-topic topic-name)
  ; just return the queue for this topic,
  ;  somebody  else has to check to see if the topic-name exists
  (if (contains-topic topic-name)
      (hash-ref topic-hash topic-name)
      (make-queue)))
```
# Testing on checkin

Finally, let's setup our git repo so that the tests run each time we check our code it. Github provides "actions", which can do a number of things for us.  For example: run tests, package our code for deployment to containers, or reformat code according to test standards.

The Github action code is stored in a special directory in the repo called ".github/workflows". We place a file there that provides instructions for github actions to follow. In our case, we'll use:

* A standard github action ubuntu worker node,
* Install Racket on the worker
* Run raco test test-middleware.rkt

Here is the action code;

```
name: Makefile CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    
 
      
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y racket
        raco test test-middleware.rkt
```

A break down of the statements in the file follows:

* name: Makefile CI -  I choose this because it was very close to what I needed
* on: ... - push or pull requests, run the action
* jobs: - this is the action steps
* build: runs-on - tells git to grab a ubuntu-latest worker
* steps: there are 3
* uses: actions/checkout@2 is a git check out step from the market place
* name: & run: update the ubuntu container, install racket and run our tests

If something fails, you receive an email complaining about the failure. This is great for working in teams of people. Each checkin will notify everybody of the code status and alert people for problems. 


# Conclusion

Testing your code is very important. As we saw here, the code worked for the easy path cases. It failed and would have had strange behavior if we had not caught the remove-data-from-topic bug or the get-queue-for-topic bug. Racket's testing framework rackunit is very robust and provides a lot more capability than we used here. But these tests demonstrate how to get started.