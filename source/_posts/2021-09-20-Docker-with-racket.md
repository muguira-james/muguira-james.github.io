---
title: Using Racket in Docker containers
tags:
  - Racket
  - Docker
categories:
  - Programming
  - Containers
date: 2021-09-20 13:27:12
---


Using Racket in Docker
<!-- more -->
# Introduction

The Racket programming language is an implementation of the Scheme standard. Racket is very well supported. It has great capabilities as a teaching language. To get  started with Racket see https://racket-lang.org

This post came about because one of the people on my team said that lisp and scheme were "no good for production, becuase you  can't put them in containers." This post will describe how to put Racket into a Docker container. In production environments, deploying software can be problematic. For example, many programming languages / solutions require loading additional components and libraries beyond the standard set that is shipped with the language. 

This post assumes you have installed both Racket and Docker on your machine. I also use the command line tool dive to inspect the container contents. Dive is a great tool.

# A simple case of saying hello

This post covers 2 things: 

* building the basic container with a working racket program, 
* exploiting Racket tooling to create a compiled version of the sample program.


First, we need a simple program. 

Our first sample Racket program is very simple. It will make use of Racket's http services stack. This post is not a tutorial for Racket, there are many very well written tutorials in the Racket documentation.

Our basic program will start, initialize Racket's web stack, and return a message when somebody hits the URL with a browser.

```

#lang racket

; bring in the racket web stack
(require web-server/servlet
         web-server/servlet-env)

; this function will return some html to the requestor
(define (start request)
  (response/xexpr
   '(html
     (head (title "James and his blog"))
     (body (h1 "My Blog under construction")))))

; start the server on port 8000 and don't launch a browser
; #:listen-ip tells the network stack to listen on all ip addresses
; #:launch-broswer says don't start a new browser
(serve/servlet start #:port 8000 #:listen-ip #f #:launch-browser? #f)


```

From a container perspective, this program highlights a couple of concerns:

* The container will be running a server capable of responding to browser requests,
* The container will require a port to be opened,
* The program needs to have all of its dependencies loaded into the container.

Racket, installed on my Mac is a dynamically linked application. That means libraries are loaded at run time, from system libraries. That is our first huddle to over come. Docker containers create a self contained environment. That means all dynamic code and dependent libraries needs to be inside inside the container.

Let's take a simple approach to get something running. Then we'll improve it over several steps. As a first step, we'll create a docker configuration file.

```

FROM ubuntu
RUN apt update -y && apt install -y racket
WORKDIR /app
COPY web1.rkt .
EXPOSE 8080
CMD ["racket", "web1.rkt"]

```

That Dockerfile will create the container, update ubuntu to it's latest  configuration, install Racket into the container, expose the port and run racket with the mentioned script. 

Let's see this in action. The following first builds the container. The second line runs the comtainer:

```

$ docker build -t foo .
$ docker run -it -p 8000:8000 foo 
Your Web application is running at http://localhost:8080.
Stop this program at any time to terminate the Web Server.

```

If you open Firefox and enter http://localhost:8000 in the URL bar you should see:

```

Welcome to the Racket Web Server

Find out more about writing servlets by reading the Continue tutorial in the Help Desk.

Find out more about the server by reading its reference manual in the Help Desk.

Please replace this page with your favorite index page.

Powered by Racket

For more information on Racket, please follow the icon link.

```

Humm,  that was not what  I expected?  Reading into the Racket docs, I see I need to use a different URL:  http://localhost:8000/servlets/standalone.rkt. Ok, that worked, the container builds and runs. Use Ctl-C to stop things. Let us examine what we have created. Issue the following command:

```

$ docker images
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
foo          latest    836d83e4f6b9   44 hours ago   490MB

```

# Packaging without loading Racket

On my machine, I see a large container, wieghing in at 490 megabytes. That is pretty large for such a simple program. Using the program "dive" i can see that the first line of the Dockerfile: "FROM ubnutu" created a 73 MB layer in the container. The sencond line, which updates ubuntu and installs Racket, adds 417 MB !!! Doing the copy of the web1.rkt script adds 352 bytes.

We can improve this. We loaded the full Racket environment into the container. We don't need to do that. Our current setup assumes we will run Racket and let it run the web1.rkt script. So, we are interpreting the script. Ideally, we should be able to compile our Racket script.  Racket has command line tools, let's explore those.

The Racket documentation describes a set of tools for compiling and distributing Racket code. We'll now explore raco. The raco tool provides a number of tools that are run from the command line. This is perfect for including racket into Ci/CD pipelines. We will explore raco exe and raco distribute.

Let's go back to what I said earlier about Racket being a dynamically linked  language.  Most  modern programming languages assume you are going to link your program dynamically. The executable will depend on libraries loading as the program is running. In a unix environment (Mac & Linux), there is an environment  variable  called "LD_LIBRARY_PATH" that points to where system libraries are loaded from. For Windows machines  see https://docs.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-search-order?redirectedfrom=MSDN#search_order_for_desktop_applications.

To make a ccontainer work, we  need to gather all of  the dependencies together and load them all  into the  container.  This means we have to ;

* compile our Racket code into a  standalone executable,
* have just the Racket run-time load into the container vs. the entire Racket environment,
* have all libraries loaded into  the  container.

Raco exe is used to compile our script. Instead of interpreting, after using raco exe, we get a stand alone executable. This means that the Racket run-time is included in. Raco exe alone creates a program that dependes on having the racket system installed on your machine. That is not quite what we want but let's explore it.

```

raco exe web1.rkt
$ ls -lh
-rw-r--r--   1 muguira  staff   122B Sep 23 19:08 Dockerfile
-rwxr-xr-x   1 muguira  staff    62M Sep 26 13:37 web1
-rw-r--r--   1 muguira  staff   352B Sep 24 17:43 web1.rkt
$

```

The directoy listing shows a 62 MB executable (web1).  That is a lot better than 490MB. However, that executable does depend on a working Racket installation. 

What we need is a way to combine the parts of Racket we need and the script to produce a working program. Raco distribute is the command for that! Raco Distribute creates a pacckage that can be run on other machines (without Racket installed). The command places the standalone executable and all dependencies into a directory.  For this example I'll call that directory "build".

```

raco distribute build web1
$ ls -lh
total 126120
-rw-r--r--   1 muguira  staff   122B Sep 23 19:08 Dockerfile
drwxr-xr-x   4 muguira  staff   128B Sep 26 13:43 build
-rwxr-xr-x   1 muguira  staff    62M Sep 26 13:37 web1
-rw-r--r--   1 muguira  staff   352B Sep 24 17:43 web1.rkt

$ du -d1 -h build
 62M	build/bin
5.7M	build/lib
 67M	build

$ ls -lh build/bin
total 125992
-rwxr-xr-x  1 muguira  staff    62M Sep 26 13:43 web1

```

The result is a 67MB self-contained directory that contains everything we want in one place. Under build/bin we see the executable  file web1, which is 62MB. The build/lib directory contains all of the dependencies. Now let's change the Dockerfile and compare our results:

```

FROM ubuntu
WORKDIR /app
COPY build .
EXPOSE 8080
CMD ["/app/bin/web1"]

```

Notice, that we DO NOT update ubuntu or install Racket. Instead, we set a working directory in the container called /app and we copy the build directory into /app in the container. We still expose the port. Last, we change the command to run our program to point to "/app/bin/web1"

To compare, let's change the name of the container for this build to be foosmall:

```

$ docker build -t foosmall .

$ docker images
REPOSITORY   TAG       IMAGE ID       CREATED              SIZE
foo          latest    fee0476d757a   About a minute ago   490MB
foosmall     latest    24d628917cf5   8 minutes ago        143MB

```

Our final container size is 143 MB. Using dive, we see that the docker copy added 70MB to the 73 Mb ubuntu base image.

# Conclusion

This post walked through the steps to create a docker container with a working Racket program.  The small Racket program demonstrated how to create a simple web server that could reply with html to a browser.  Our first container effort created a large 490 MB container with the full Racket environment installed  inside the container. From a security point of view this is less than optmial.  We don't need a full Racket install in the container to reply to a simple request. Our second effort reduced the container size and placed only the elements of the Raclet run-time in the container. The Racket environment supplied two commands  that helped us create a standalone executable. Finally we used docker commands to copy that executable into the container and expose the proper  ports. 

