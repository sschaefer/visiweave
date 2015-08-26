visiweave
=========

This project is in its initial stages and not yet functional.
-------------------------------------------------------------

Purpose: Understand and manipulate complex systems.

Visiweave is inspired by
[Leo](http://webpages.charter.net/edreamleo/front.html) but with a
number of differences.

* The underlying data is not constrained to be acyclic.  That affects
  graph traversal procedures.

* Data storage should be collaboration friendly; either text based
like git, or in a database with appropriate versioning tools (except
I've been unable to find a database supporting versioning?).

* The target interface is browser based.  I like what
[Workflowy](workflowy.com) does; something similar will occupy one
panel to provide navigation; the other panel(s) will provide
appropriate editors for data associated with the selected node.

So, what's the big idea?  First, a *rooted* *ordered* *directed*
*graph* is a useful way to describe a complex system.

* The graph: nodes have labels, data (we'll start with text; later we
might expand to other media) and ordered links to other nodes.  The
label should tell a person (or procedure) what the data is about.  If
what is being descrbied is source code, the label might be a function
name and the data the function definition.  The ordered links lead
(unidirectionally) to whatever else one might want to know from that
node.  Example: a node represents a file, which links to function
definitions which occur in that file.  Example: a node represents an
out call graph point, with links to out calls from a function.
Example: the same, except in calls.  Example: a node represents a file
system directory, with links to nodes representing files in that
directory.  Example: A node represents a configuratio file, with links
representing objects mentioned in that configuration (e.g., hosts).
Example: a node represents the configuration of a host, with one link
taking you to the hardware configuration (possibly represented
hiearachically), another link taking you to the set of configuration
files.  Example: a node represents a subnet, with links to the hosts
on that subnet.

* The links are ordered: If a node represents file contents, the links
reference components of that file in order.  Changing the order of the
links would change the order in which the file components appear in
the generated file.  The literature I've seen discussing trees nearly
always assumes there is an ordering on links, a.k.a. children, but the
literature on graphs seems to never explore that constraint.

* Rooted: there is an invisible node, the root, from which all nodes
are accessible by some path through the directed links; the root is
the parent from which the top level entries of the outline are
reached.  Because there are no other hierarchichal or cyclic
restrictions on the graph, such nodes may also appear as the target of
links from other nodes.

Why "visiweave"?  Well, "visigraph" is (TM).  The hope of this project
is to make visual exploration of a rooted ordered directed graph
intuitive through the use of outlines, and to provide a set of
"weaving" tools - procedures that traverse the graph generating useful
results, often source code for other systems.  The term *weave*
harkens back to one of the original [literate programming
tools](http://sunburn.stanford.edu/~knuth/cweb.html), which are
another source of inspiration for this project.

License
-------

At this point, the project, aside from components (dynatree, jquery,
cowboy) obviously the work of other authors, is entirely the product
of Stephen P. Schaefer, and I make that portion availble under the
terms of the GNU Affero General Public License version 3.0 or later.

Design and implementation
-------------------------

For the browser front end, I'm initially looking at
[dynatree](https://code.google.com/p/dynatree/) to help implement the
outline portion.  Initially the node data portion will consist of a
single text field, but I hope to integrate
[ACE](http://ace.ajax.org/#nav=about) or some other browser based
editor eventually.

Frontends (e.g., the web browser) will communicate to the backend
using a RESTful API, based around http://site/v1/nodes.  Originally, I
had thought that there would be an http://site/v1/roots, but I've
decided that roots are only a special case of nodes, and it is
unnecessary to name them separately.

The backend will provide the data store (CRUD) and graph traversals.
The current backend is being developed on cowboy; I'm hoping that the graph
traversal algorithms - even constrained by the ordering of links -
will be able to take advantage of Erlang's affinity for parallel
execution.  Graph traversal will start with a node (usually the
invisible root) and then do something with the node data - the label,
the data, the links.  For instance, if a node represents a file, one
might do a depth first traversal in the manner of a tree traversal,
but remembering a stack of nodes encountered on the path to this node,
so that one avoids following a link that leads to a cycle.  Such a
traversal might visit an acyclic subset multiple times, if linked to
from different nodes.  A different traversal might remember every node
visited, and be constrained to visit each no more than once.
Analogous to tree traversals, there may be pre-order or
post-order traversals (in-order would require either a binary tree or a
disambiguation of where "in" was within the links.  The traversal
algorithms may be supplemented by callbacks that make decisions about
link traversal or how to process the data associated with a node.

### Backend API

The following describes what I intend to implement, but is not yet
built.  Everything is subject to change upon new insight, but after
something is implemented, I'll increment the version number (currently
v1) if it is dropped or behaves incompatibly.  New implementation of
that which has not previously been implemented may operate differently
than originally described, but at that point I'll update the
description.

#### No qualification to nodes

* POST http://site/v1/nodes - create a new root node

* GET http://site/v1/nodes - returns all root nodes.  If there are no root nodes, initiallizes with a single stub root node, and returns that.

* PUT http://site/v1/nodes - error.  PUT makes changes to an existing node, and no existing node is specified to change.

* DEL http://site/v1/nodes - error: you did not want to do that

* DEL http://site/v1/nodes?reallyDeleteAll=yes - removes all data

#### A specific node is named

* POST http://site/v1/nodes/nodeid - create a new node with the data provided, and put a link to the new node as the last edge of nodeid's list of edges.  If nodeid does not exist and is a syntactically correct nodeid, creates the new node with that nodeid as a root node.

* POST http://site/v1/nodes/nodeid?position=n - create a new node with the data provided, and insert a link to the new node as the (0-based) nth entry in nodeid's list of edges.  Nodeid must exist, or this returns 404 (node not found).

* GET http://site/v1/nodes/nodeid - retrieve nodeid's data.  Can return 404 (node not found).

* PUT http://site/v1/nodes/nodeid - replace some of nodeid's data.  Can return 404 (node not found).

* DEL http://site/v1/nodes/nodeid - remove nodeid from the list of roots.  Nodes can become inaccessible from the current graph roots, but don't actually get deleted.

#### git analogs

* GET http://site/v1/nodes/add - stage the current set of nodes for git commit

* GET http://site/v1/nodes/nodeid/add - stage the specific node for git commit

* GET http://site/v1/nodes/commit - do a git commit over the nodes: requires commit data (e.g., message, optional tag, blame)

* GET http://site/v1/nodes/branch - report on available branches

* POST http://site/v1/nodes/branch - creates a new branch (requires name)

* GET http://site/v1/nodes/branch?name=branch_name - switches branches

* GET http://site/v1/nodes/status - git status

* GET http://site/v1/nodes/log - git log

#### Graph walks

* POST http://site/v1/nodes/derive - sends a tar file to become a tree of nodes

* GET http://site/v1/nodes/derive - retrieves a tar file containing a derived set of files

* PUT http://site/v1/nodes/derive - compares tar file sent to what would be derived, and applies differences to nodes such that they now create the tar file contents

* DEL http://site/v1/nodes/derive - error

* POST http://site/v1/nodes/nodeid/derive - sends a tar file to become a tree of nodes, the top of which is nodeid: root entries in the tar file get references added to the end of the list of edges in nodeid.

* GET http://site/v1/nodes/nodeid/derive - retrieves a tar file generated by graph traversal beginning at nodeid

* PUT http://site/v1/nodes/nodeid/derive - compares tar file sent to what would be derived starting at nodeid, and applies differences to nodes such that they now create the tar file contents

* DEL http://stie/v1/nodes/nodeid/derive - error

#### Assistant

* PUT http://site/v1/nodes/nodeid/parse - parses the contents of nodeid, and creates a tree which would generate the contents of nodeid.  Clues about what language is being parsed must be provided, and an optional indication of the degree of decomposition.

Restfulness and efficiency
--------------------------

The intent is to have a large number of nodes, but differing in
character from a typical file system by having 10% or less the
average content size, and 10 times as many "directories" (especially
since every node can be considered a directory).

In the initial implementation, a PUT always sends one of: the entire
title; the entire text; or the entire edge list.  If practice shows
that writing the entirety of these is too slow, we'll come up with a
syntax for incremental updates.  The intent is that larger texts will
be decomposed (have stucture exposed) thus making transactions
smaller.

Integrity
---------

What to do when a nonexistent nodeid appears in an edge list?  First,
how might that arise?  One of: UI bug; concurrent edit; the
transaction to create the node appears out of order.  Possible
responses: reject the transaction; create a stub node with that
nodeid.

Challenges
----------

* I'm a slow coder.

* I'll need to design a way of visualizing differences between outlines.

* How best to deliver the result of various graph traversals?  E.g.,
if the visiweave graph represents a code tree, does one expose a URL
that could be the source of a "git pull"?

* How does one share a visiweave corpus?

* If one starts with a directory tree generated by visiweave, and then
one changes that directory tree, how does one incorporate the changes
back into visiweave?  "git push" may not provide sufficient
information.
