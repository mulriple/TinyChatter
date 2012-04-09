# TinyChatter

## Setup


### Clone from github
+ `git clone git://github.com/jtg2078/TinyChatter.git`
+ `cd TinyChatter`
+ `git submodule update --init`

## About this project

### Introduction
Lets build an XMPP chat app~

### Description
The main purpose of this project is to learn about XMPP protocol and framework. And what is the best way to get familiarize with it? Well I guess it is to build one yourself~

### Implementation detail
#### Phase one
+ [*DONE*] skeleton code for the app
+ [*DONE*] initial set of view controllers(Root, Roster, Chat, etc…)
+ [*DONE*] a manager type of class to wrap up XMPPFramework and to provide a cleaner and async-event-driven type of interface
+ proof of concept functionalities:
	+ [*DONE*] login
	+ [*DONE*] loading and persist friend list(roster)
	+ [*DONE*] loading and persist chat sessions
	+ [*DONE*] send out chat message
	+ [*DONE*] receive and display chat messages from others

#### Phase two
+ re-engineer the chat sessions code and persistence strategy
+ implement a better chat message view controller
+ more to come...

### Moving on
