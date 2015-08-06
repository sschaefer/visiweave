%% -*- mode: nitrogen -*-
%% vim: ts=4 sw=4 et
-module (index).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").
-include("records.hrl").
-include("visiweave_model.hrl").

main() -> #template { file="./site/templates/bare.html" }.

title() -> "Hello from vw.erl!".

body() -> 
    #graph_node{ children = Roots } = visiweave_node_server:read_roots(),
    OutlineBody = [ #outline{ gn_id={index,read_node,binary_to_list(Node)} } || Node <- Roots ],
    [FirstNode|_] = Roots,
    #graph_node{ text = Text } = visiweave_node_server:read_node(FirstNode),
    wf:wire(wf:f("jQuery('.resizable').resizable({handles: \"e, s, se\"})")),
    #panel{
	style="margin-left:50px;margin-right:50px;margin-top:0px;",
	body=
	#table{
	    style="height:100%;width:100%",
	    rows=[
		#tablerow{
		    cells=[
			#tablecell{
			    class="resizable",
			    style="border:1px solid;vertical-align:top",
			    body=
			    #panel{
				style="margin-top:0px",
				body=OutlineBody
			    }
			},
			#tablecell{
			    style="height:100%;border:1px solid;padding:2px 2px 10px 2px;",
			    class="resizable",    
			    body=#textarea{
				id="textarea",
				style="height:99%;width:99%;display:table-cell;",
				text=Text}
			}
		]}
	    ]
	}
    }.

vw_element_event(Other) ->
    wf:update(placeholder, Other),
    ?PRINT({vw_element_event, Other}).

event(Other) ->
    wf:update(placeholder, Other),
    ?PRINT({event, Other}).

handle_click({arrow, ArrowID}) ->
    Arrow = wf:q(ArrowID),
    ?PRINT({handle_click, ArrowID, Arrow}).

% translate from visiweave_model record to outline element expected tuple
read_node(Id) ->
    #graph_node{ title = Title,
	text = Text,
	children = Childlist } = visiweave_node_server:read_node(list_to_binary(Id)),
    { Title, Text, [binary_to_list(Child) || Child <- Childlist] }.
