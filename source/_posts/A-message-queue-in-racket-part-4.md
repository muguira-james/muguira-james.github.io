---
title: A-message-queue-in-racket-part-4
date: 2021-10-24 12:36:11
tags:
---

building a message queue  in Racket - part 4
<!-- more -->

# Introduction

The previous articles in this series laid the foundation for a message queue  similar to RabbitMQ or Apache's ActiveMQ.  The message queue presents an API that allows you to add or delete message from topics. There is also an administrative API interface to view and manipulate the topic store.

This article will clean up the code structure and get us in a position so we can apply testing to the system.  As it stands, the code works, but it does have bugs. It is also in a single 200+ line file. We are going to split the code up so it looks more like the architecture.

For the git repo [see the message-que directory](https://github.com/muguira-james/racket-stuff.git).

The original code for the previous articles is in the jam-message-que directory.

![System Architecture](/images/MQ-Architecture-1.png)

The system architecture has 3 distinct components: a front-door, a topic store, and some middleware to manipulate the topic store.  We are going to use Racket's module syntax to split the code into 3 files. 

# The front-door

The front-door is all the code required to present the API and interact with http services expose from the Racket libraries. At  high level, the front-door is structured like this:

* server start-up, ports paths, TCP-IP considerations
* decoding the http requests and dispatching the right handler
* creating a valid JSON response
* formating and returning the http response in 'application/JSON' format to the caller.

In code form, the front-door looks like this:

```
#lang racket
;
; -------------------------------------------
; define a simple message queue
;

(require web-server/servlet) 
(require web-server/servlet-env)
(require json)
(require data/queue)

;
; pull in the middleware code for manipulating the topic-hash
(require "middleware.rkt")


(define (hello request)
  (http-response (format "hello: today")))

(define (do-nothing request)
  ; just say nothing useful
  (http-response "<div>welcome to <span style=\"color:blue\">jamQ</span></div>"))

(define (greeting-page request)
  ; say hi
  (http-response (list-ref '("Hi" "Hello") (random 2))))


(define (enque request)
  ; put something in a queue
  ; input: { topic: "name", payload: "data-type" }
  (let* ([hsh (request->jshash request)]
         [topic-name (hash-ref hsh 'topicname)]
         [payload-data (hash-ref hsh 'payload)])
    (begin         
      (add-data-to-topic topic-name payload-data)
    
      (let ([rtn (make-hash)])
        (build-json-response rtn 'cmd "enque")
        (build-json-response rtn 'topic-name topic-name)
        (build-json-response rtn 'data payload-data)

        (displayln (with-output-to-string (lambda () (write-json  rtn))))
        (http-response (with-output-to-string (lambda  () (write-json rtn))))))))

(define (deque request)
  ; check if topic exists, remove 1st item from topic queue
  (let* ([js-hsh (request->jshash request)]
         [topic-name (hash-ref js-hsh 'topicname)]
         [rtn (make-hash)]
         [datam (remove-data-from-topic topic-name)])
    (begin
      (build-json-response rtn 'topic-name topic-name)
      (build-json-response rtn 'payload  datam)
      (displayln (with-output-to-string (lambda () (write-json rtn))))
      (http-response (with-output-to-string (lambda  () (write-json rtn)))))))


(define (topic-list request)
  ; show me all the topics in the topic-hash
  (begin
    (let* ([rtn (make-hash)])
      (build-json-response rtn 'topic-list (hash-keys topic-hash))
      (displayln (with-output-to-string (lambda () (write-json rtn))))
      (http-response (with-output-to-string (lambda() (write-json rtn)))))))

(define (topic-count request)
  ; show me a count of topics
  ; input: { count-topics: "all" }
  (begin
    (let ([rtn (make-hash)])
      (build-json-response rtn 'topic-count (hash-count topic-hash))
      (displayln (with-output-to-string (lambda () (write-json rtn))))
      (http-response (with-output-to-string (lambda () (write-json rtn)))))))

(define (topic-data request)
  ; list all data in a topic
  (let* ([hsh (request->jshash request)]
         [topic-name (hash-ref hsh 'quename)]
         [rtn (make-hash)])
        (build-json-response rtn 'topic-name topic-name)
        (build-json-response rtn 'topic-list (queue->list (hash-ref topic-hash topic-name)))
        (displayln (with-output-to-string (lambda () (write-json rtn))))
        (http-response (with-output-to-string (lambda () (write-json rtn))))))

(define (drain-queue request)
  (let* ([hsh (request->jshash request)]
         [topic-name (hash-ref hsh 'quename)]
         [rtn (make-hash)])
    (hash-set! topic-hash topic-name (make-queue))
    (build-json-response rtn 'cmd "drain-queue")
    (build-json-response rtn 'topic-name topic-name)
    (build-json-response rtn 'message (format "drain-queue: ~v: all data deleted" topic-name)
    (displayln (with-output-to-string (lambda () (write-json rtn))))
    (http-response (with-output-to-string (lambda ()  (write-json  rtn)))))))

(define (topic-remove request)
  (let* ([hsh  (request->jshash request)]
         [topic-name (hash-ref hsh 'quename)]
         [rtn (make-hash)])
    (hash-remove! topic-hash topic-name)
    (build-json-response rtn 'message (format "topic-remove: removed topic ~v" topic-name))
    (displayln (with-output-to-string (lambda  () (write-json rtn))))
    (http-response (with-output-to-string (lambda () (write-json rtn))))))

(define (build-json-response hsh key value)
  (hash-set! hsh key value))

(define (http-response content)  
  (response/full
    200                  ; HTTP response code.
    #"OK"                ; HTTP response message.
    (current-seconds)    ; Timestamp.
    TEXT/HTML-MIME-TYPE  ; MIME type for content.
    '()                  ; Additional HTTP headers.
    (list                ; Content (in bytes) to send to the browser.
      (string->bytes/utf-8 content))))


(define-values (dispatch generate-url)
  ;; URL routing table (URL dispatcher).
  (dispatch-rules
   [("") do-nothing]
   [("hello") hello]  ; check to see if the service is working
   [("enque") #:method "post" enque]
   [("deque") #:method "post" deque]
   [("topic-list") topic-list]
   [("topic-count") topic-count]
   [("topic-data") #:method "post" topic-data]
   [("drain-queue") #:method "post" drain-queue]
   [("topic-remove") #:method "post" topic-remove]
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

Really, nothing new here if you have been following this series. The only new thing is the restructuring.  line 14 of the above listing is where we use Racket's 'require' statement to bring the middleware code in.

# The middleware code

The middleware manipulates the topic-hash. If we add a message to the topic-hash, that means we first, check to see if the topic is present. If it is not, then we make a queue, add the message to that queue and then add that queue to the topic-hash under the missing topic name. If the topic is present, we simply get the queue associated with that topic-name and add the message.

Splitting the middleware out from the front-door will make testing easier and provides better code structure. For testing of  the overall system, we want to test the middleware code using Racket test capabilities and test the front-door using something like cucumber or Mocha.

The middleware code follows:

```
#lang racket

(require web-server/servlet) 
(require web-server/servlet-env)
(require json)
(require data/queue)
  ;  (require gregor)

;; a hash is structured as a topic and a queue
(define topic-hash (make-hash))


(define (contains-topic key)
  ;; is key in this hash
  (if (member key (hash-keys topic-hash))
      #t
      #f))

(define (add-data-to-topic key data)
  ;; check to see if key is in the topic-hash and add data to the correct topic
  (if (contains-topic key)
      (enqueue! (hash-ref topic-hash key) data)
      (begin
        (let ([q (make-queue)])
          (enqueue! q data)
          (hash-set! topic-hash key q)))))

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
        


(define (get-queue-for-topic topic-name)
  ; just return the queue for this topic,
  ;  somebody  else has to check to see if the topic-name exists
      (hash-ref topic-hash topic-name))

(define (request->jshash request)
  (string->jsexpr (bytes->string/utf-8 (request-post-data/raw request))))

(provide topic-hash
         request->jshash
         get-queue-for-topic
         remove-data-from-topic
         add-data-to-topic
         )

```

The new thing here is the 'provide' statement.  Racket's 'provide' exposes function calls in this file to external callers.  Exposing topic-hash  is not the best style, but we'll fix that in the next article.

# Conclusion

We have split the code and restructed it so we now have 2 files: the front-door and the middleware.  The middleware code exposes a set of functions to the front-door for manipulating the topic-hash. This code structure places functionality into specific files.  For the system at this point it might seem over kill. Once we start testing, we are going to expose a number of bugs.  Fixing the bugs will expand the code by a few lines. Taking the code all the way to the point were we might want to put this code into production is going to introduce even more changes.  We will use exception handling, which will clutter up the code even more and this restructure will separate the exception code, isolating it to the front-door file.  