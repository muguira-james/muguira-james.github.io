---
title: A-message-queue-in-racket-part-3
date: 2021-10-22 21:14:10
tags:
  - Racket
categories:
  - Programming
---


This is the third part of the series
<!-- more -->

# Introduction

The first 2 parts of this series introduced the scaffolding and 2 API calls. We are creating a message queuing system, similar to Rabbit MQ or Apache ActiveMQ. The idea is to create a server that can be used to store and retrieve data. The server interface is an API consisting of 2 different layers: a user interface for adding and deleting items from queues assoicated with topics; and an administration interface that returns the number of topics, list of topics, data for a topic and allows us to remove all data for a topic.

At this point we have the scaffolding and 2 API  calls implemented: Hello, which is a monitoring API; and enqueue which is used to add items into the queue for a given topic. This time we will implement; dequeue, which completes the user interface. We will also implement the administrative interface consisting of topic-list, topic-data, topic-count, topic-drain, topic-remove and drain-queue. That is  a lot, let's get going.

First, to set expectations, here is the complete program to date:

```

(require web-server/servlet) 
(require web-server/servlet-env)
(require json)
(require data/queue)

;; a hash is structured as a topic and a queue
(define topic-hash (make-hash))


; Hello - say hello and add the date and time
(define (hello request)
  ; just say nothing useful
  (http-response "<div>welcome to <span style=\"color:blue\">jamQ</span></div>"))

;
; handle adding  a message to a topic
(define (add-data-to-topic key data)
  ;; check to see if key is in the topic-hash and add data to the correct topic
  (if (contains-topic key)
      (enqueue! (hash-ref topic-hash key) data)
      (begin
        (let ([q (make-queue)])
          (enqueue! q data)
          (hash-set! topic-hash key q)))))

;
; helper function to return a byte array
(define (request->jshash request)
  (string->jsexpr (bytes->string/utf-8 (request-post-data/raw request))))

;
; front-door of the enqueue function
(define (enque request)
  ; put something in a queue
  ; input: { topic: "name", payload: "data-type" }
  (let* ([hsh (request->jshash request)]
         [topic-name (hash-ref hsh 'topicname)]
         [payload-data (hash-ref hsh 'payload)])
    (begin         
      (add-data-to-topic topic-name payload-data)
      (displayln
       (format
        "enq: name: ~v: data: ~v hash-size: ~v hash-keys: ~v~%"
        topic-name payload-data (hash-count topic-hash) (hash-keys topic-hash)))
      (let ([rtn (make-hash)])
        (hash-set! rtn 'topic-name topic-name)
        (hash-set! rtn 'data payload-data)
        (hash-set! rtn 'count (hash-count topic-hash))
        (hash-set! rtn 'keys (hash-keys topic-hash))
        (displayln (with-output-to-string (lambda () (write-json  rtn))))
        (http-response (with-output-to-string (lambda  () (write-json rtn))))))))

;
; return a byte array formated like an http response
(define (http-response content)  
  (response/full
    200                  ; HTTP response code.
    #"OK"                ; HTTP response message.
    (current-seconds)    ; Timestamp.
    TEXT/HTML-MIME-TYPE  ; MIME type for content.
    '()                  ; Additional HTTP headers.
    (list                ; Content (in bytes) to send to the browser.
      (string->bytes/utf-8 content))))

;
; look up table for the routing of our API
(define-values (dispatch generate-url)
  ;; URL routing table (URL dispatcher).
  (dispatch-rules
   [("") hello]
   [("hello") hello]  ; check to see if the service is working
   [("enque") #:method "post" enque]
   [("deque") #:method "post" deque]
   [("topic-list") topic-list]
   [("topic-count") topic-count]
   [("topic-data") #:method "post" topic-data]
   [else (error "page not found")]))



(define (request-handler request)
  (dispatch request))

;; Start the server.
(serve/servlet
  request-handler
  #:launch-browser? #f
  #:quit? #f
  ; have to listen on the  right host NOT 127.0.0.1
  #:listen-ip "0.0.0.0"
  #:port 8000
  #:servlet-regexp #rx"")

```
Our first function to implement is the opposite of adding an item to a topic, removing an item. In this case, we just remove and return the first  item in the queue. Before we see the implementation let's review the architecture of the system and the topic hash data structure. The system architecture is a front door that handles http requests and responses. There is a middle layer that handles the internal data structures and finally the internal  data structures themselves.

![system architecture](/images/MQ-Architecture-1.png)

The internal data structure we are manipulating is a hash table. The keys in the hash table are the topic  names. For each key, the value is a queue with all the items associated with that topic.

![internal data structure](/images/Racket-queue-2.png)

The enqueue function checked to see if a topic name existed in the hash table, adding it and the message data if required. Deleting messages off a topic is handled by popping the top item off the queue for a topic and returning that message.

```

(define (request->jshash request)
  (string->jsexpr (bytes->string/utf-8 (request-post-data/raw request))))

(define (get-queue-for-topic topic-name)
  ; just return the queue for this topic,
  ;  somebody  else has to check to see if the topic-name exists
      (hash-ref topic-hash topic-name))

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
        
(define (deque request)
  ; check if topic exists, remove 1st item from topic queue
  (let* ([js-hsh (request->jshash request)]
         [topic-name (hash-ref js-hsh 'topicname)]
         [rtn (make-hash)]
         [datam (remove-data-from-topic topic-name)])
    (begin
      (hash-set! rtn 'topic-name topic-name)
      (hash-set! rtn 'payload datam)
      (displayln (format ":datam:->~v --> ~v~%" datam rtn ))
      (displayln (with-output-to-string (lambda () (write-json rtn))))
      (http-response (with-output-to-string (lambda  () (write-json rtn)))))))

```

The implementation of deque has 3 helper functions: "remove-data-from-topic", "get-queue-for-topic" and "request->jshash". 

* Request->jshash takes the data coming in on the http POST and converts it to a Racket hash for easy access. 
* get-queue-for-topic is a function to return the queue assoicated with a topic-name.
* remove-data-from-topic handles the actual removal of the top message from the topic queue.
* deque handles reformating the incoming http request, removing the data and formating the http response.

Enque and deque are the "user interface" API calls for adding and removing messages to and from a topic. Next, let's start on the administration interface. First we can implement "topic-list", which simply creates a JSON list of all known topic names.

```
(define (topic-list request)
  ; show me all the topics in the topic-hash
  (begin
    (let* ([rtn (make-hash)])
      (hash-set! rtn 'topic-list (hash-keys topic-hash))
           
      (displayln (with-output-to-string (lambda () (write-json rtn))))
      (http-response (with-output-to-string (lambda() (write-json rtn)))))))

```

The implementation is straight forward. Create a return hash, which holds our topic name list. Get the current keys from the topic-name hash and format that list out as JSON.

Let's tackle "topic-count" and "topic-data". 

```
(define (topic-count request)
  ; show me a count of topics
  ; input: { count-topics: "all" }
  (begin
    (let ([rtn (make-hash)])
      (hash-set! rtn 'topic-count (hash-count topic-hash))
      (displayln (with-output-to-string (lambda () (write-json rtn))))
      (http-response (with-output-to-string (lambda () (write-json rtn)))))))

(define (topic-data request)
  ; list all data in a topic
  (let* ([hsh (request->jshash request)]
         [topic-name (hash-ref hsh 'quename)]
         [rtn (make-hash)])
        (hash-set! rtn 'topic-name topic-name)
        (hash-set!  rtn 'topic-list (queue->list (hash-ref topic-hash topic-name)))
        (displayln (with-output-to-string (lambda () (write-json rtn))))
        (http-response (with-output-to-string (lambda () (write-json rtn))))))
```

The function "topic-count" grabs a count of the total number of topics in the topic hash at that moment and formats it out to a JSON object. The function "topic-data" returns a JSON list of all the messages associated with a topic.

Next, we will code "drain-queue". The function "drain-queue" is supposed to remove all data associated with an input topic-name. Danger!! The implementation takes advantage of the hash function library to overwrite the queue for that topic name with a freshly initialized and empty queue. That is, we OVERWRITE the old queue.  It is up to the gabage collector to free the memory used by the old messages in the old queue.

```
(define (drain-queue request)
  (let* ([hsh (request->jshash request)]
         [topic-name (hash-ref hsh 'quename)]
         [rtn (make-hash)])
    (hash-set! topic-hash topic-name (make-queue))
    (hash-set!  rtn 'topic-name topic-name)
    (hash-set! rtn 'message "drain-queue: all data deleted")
    (displayln (with-output-to-string (lambda () (write-json rtn))))
    (http-response (with-output-to-string (lambda ()  (write-json  rtn))))))
```

Finally, we can code "topic-remove". This function removes the topic from the topic list. The Racket garbage collector will handle cleaning up the data/queue.

```
(define (topic-remove request)
  (let* ([hsh  (request->jshash request)]
         [topic-name (hash-ref hsh 'quename)]
         [rtn (make-hash)])
    (hash-remove! topic-hash topic-name)
    (hash-set! rtn 'message (format "topic-remove: removed topic ~v" topic-name))
    (displayln (with-output-to-string (lambda  () (write-json rtn))))
    (http-response (with-output-to-string (lambda () (write-json rtn))))))
```

With that we have defined a message queue. It is 218 lines total. It is not very sophisticaded. It also may have bugs. 

# Conclusion

That rounds out the full implementation of the message queue system. The next article will explore how to restrcuture the single code file so we can test it using Racket's test capabilities.