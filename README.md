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
what is being described is source code, the label might be a function
name and the data the function definition.  The ordered links lead
(unidirectionally) to whatever else one might want to know from that
node.  Example: a node represents a file, which links to function
definitions which occur in that file.  Example: a node represents an
out call graph point, with links to out calls from a function.
Example: the same, except in calls.  Example: a node represents a file
system directory, with links to nodes representing files in that
directory.  Example: A node represents a configuration file, with links
representing objects mentioned in that configuration (e.g., hosts).
Example: a node represents the configuration of a host, with one link
taking you to the hardware configuration (possibly represented
hierarchically), another link taking you to the set of configuration
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

At this point, the project, aside from components (nitrogen, jquery,
cowboy) obviously the work of other authors, is entirely the product
of Stephen P. Schaefer, and I make that portion available under the
terms of the GNU Affero General Public License version 3.0 or later.

Design and implementation
-------------------------

For the browser front end, I'm working with [nitrogen](https://nitrogenproject.com).

The backend will provide the data store (CRUD) and graph traversals.
The current backend is being developed in Erlang; a cowboy RESTful interface
was contemplated but interfered with Nitrogen. I'm hoping that the graph
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
