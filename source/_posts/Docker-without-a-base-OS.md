---
title: Docker_without_a_base_OS
date: 2022-01-29 18:23:11
tags:
---

The mechanics of creating docker images without loading a base O/S

<!-- more -->

# Introduction

We always see containers creates with a statement like: 

```

FROM ubuntu
 ...

```

Ubuntu, in the "FROM" statement refers to a version of the linux operating system provided by Canonical. Could we create a container without the OS?

The answer is yes, but you have to understand how a program is translated from source code to a executable image. This post will cover these ideas at a very high level.

# A sample program to work from

To get started we need a simple program. How about this...

```

#include <stdio.h>

void main(int argc, char *argv[]) {
    printf("hello world\n");
}

```

Yeah I know, REALLY! Hello world? In this case all we need is a program that outputs something. "Hello world" is perfect.

# Dynamic vs. Static Linking

The C programming language is really a base language specification with a flexible library system to support it. These libraries are how you program novel software and hardware devices. These libraries are extensions of the base language. It would be very difficult to envision every possible extension or library in advance. 

For example, the C language provides a "standard output" library to handle a wide range of I/O. There is a library to handle working with strings, time, and even specific database systems.

Let's first compile our simple example program with no switches. We will compile it down to an executable. Then let's examine how the a.out program is created and setup to run:

```
~/Documents/racket-stuff/junk$ ls
hello.c
~/Documents/racket-stuff/junk$ gcc hello.c 
~/Documents/racket-stuff/junk$ ls -lah
total 32K
drwxrwxr-x  2 magoo magoo 4.0K Jan 29 20:51 .
drwxrwxr-x 10 magoo magoo 4.0K Jan 29 20:48 ..
-rwxrwxr-x  1 magoo magoo  17K Jan 29 20:51 a.out
-rw-rw-r--  1 magoo magoo   82 Jan 29 20:51 hello.c
~/Documents/racket-stuff/junk$ file a.out
a.out: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=2c3dad874dc1ee4d5a610d0a0862b622fc36dc8c, for GNU/Linux 3.2.0, not stripped
~/Documents/racket-stuff/junk$ ldd a.out
	linux-vdso.so.1 (0x00007fff85f43000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fbe9bd1b000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fbe9bf21000)



```
The command "file a.out" exposed information about the executable. "File" told us the a.out executable was a 64 bit dynamically linked executable. To discover more, I used the ldd command, a command that prints shared object information. With no switches the "hello.c" program source file was compiled down to a shared or dynamic executable format file. In order for it to execute, the compiler and linker added information to the output so it could find or ask for the information it needed. This information tells the system how to find stuff like output routines, and how to call the kernel to do the printf output.

What does the output of ldd tell us? "ldd" told us that there are 3 libraries linked into the executable. These are:

* linux-vdso.so.1 - a kernel interface file that makes calling kernel functions faster
* libc.so.6 - the C standard library
* /lib64/ld-linux-x86-64.so.2 - the linux shared linker library that can find and complete linkages at run time.

At this point we know the 17K byte a.out file has the translated instructions from the hello.c source, plus some additional information so the system can find and run the code.

If we try to put this a.out file into a docker container without an operating system we would have problems. First, let's create a docker config file:

```
FROM scratch
WORKDIR /app
COPY a.out .
CMD ["/app/a.out"]

```

The Dockerfile does the following:

* FROM scratch - open a new image with nothing in it
* WORKDIR /app - create a working directory
* COPY a.out . - copy the hello executable file into the container /app dir
* CMD ["/app/a.out"] - when the container starts run the file /app/a.out

Building the docker image and running results in the following:

```

$ docker build -t hello-fail .
Sending build context to Docker daemon  20.48kB
Step 1/4 : FROM scratch
 ---> 
Step 2/4 : WORKDIR /app
 ---> Using cache
 ---> e03ed3305d58
Step 3/4 : COPY a.out .
 ---> Using cache
 ---> 8b248397018d
Step 4/4 : CMD ["/app/a.out"]
 ---> Using cache
 ---> dcccce5f30a1
Successfully built dcccce5f30a1
Successfully tagged hello-fail:latest

$ docker images
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
hello-fail   latest    e8de259a2e11   5 seconds ago   16.7kB

$ docker run -it hello-fail
standard_init_linux.go:228: exec user process caused: no such file or directory

```

The docker image errors out with the criptic "exec user process caused: no such file or directoy. Not a great error message. What is happening? The command interpreter could not complete the dynamic links in the executable. Also, notice how small the docker image is. 

# Link it statically and rety

Now, we'll fix these problems. To do this we can link the executable in a different way. Instead of dynamically linking the file, we link it statically. Linking statically means we will create an executable file with everything we need to run the code contained in the file. 

```

$ 
$ gcc -static -o hello hello.c
$ ls -lh
total 856K
-rwxrwxr-x 1 magoo magoo 852K Jan 29 21:27 hello
-rw-rw-r-- 1 magoo magoo   82 Jan 29 20:51 hello.c
$ file hello
hello: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=5059e58e2072dc3785f8d790bfa13486a66db711, for GNU/Linux 3.2.0, not stripped
$ ldd hello
not a dynamic executable

```

There is a big difference in the size of the hello executable now: it went from 17K bytes to 852K bytes. That means all the library code needed to execute the file is now contained in the file. If we use this executable in docker we get results we want...

```

$ docker build -t hello-works .
Sending build context to Docker daemon  875.5kB
Step 1/4 : FROM scratch
 ---> 
Step 2/4 : WORKDIR /app
 ---> Using cache
 ---> 7d2174bc1ce3
Step 3/4 : COPY hello .
 ---> 85ea45621e25
Step 4/4 : CMD ["/app/hello"]
 ---> Running in 682723d27bc5
Removing intermediate container 682723d27bc5
 ---> 4ed66db60ee7
Successfully built 4ed66db60ee7
Successfully tagged hello-works:latest
magoo@FreeU:~/Documents/simDocker$ docker images
REPOSITORY    TAG       IMAGE ID       CREATED          SIZE
hello-works   latest    4ed66db60ee7   4 seconds ago    872kB
hello-fail    latest    e8de259a2e11   15 minutes ago   16.7kB
$ docker run -it hello-works
Hello world
$ dive hello-works
Layer   Permission     UID:GID       Size  Filetree
   0    drwxr-xr-x         0:0     872 kB  └── app
   1    -rwxrwxr-x         0:0     872 kB      └── hello


```

The new image is 872K bytes and it produces the  "hello world" message. Using "dive" to explore the container contents, we see that there is only one thing in the container: the hello executable file.



# Conclusion

This post demonstrtated how to create a statically linked executable file and place it is a docker container.  The container only contains the executable file.  There is no O/S present in the image. We used the C programming language in this demonstration. Any programming language that can compile down to a statically linked executable can be used. For example, GO programs can compile to statically linked executables.  Many other programming languages can be made to generate statically linked files, but you have to experiment with building them. This means changing the way the program compiles. This can be a time consuming exercise.