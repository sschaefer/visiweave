%% -*- mode: nitrogen -*-
%% vim: ts=4 sw=4 et
-module (index).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").
-include("records.hrl").
-include("visiweave_model.hrl").

main() -> #template { file="./site/templates/bare.html" }.

title() -> "VisiWeave".

body() ->
    % set up undo stack
    wf:state(undo, wf:state_default(undo,[])),
    #graph_node{ children = Roots } = visiweave_node_server:read_roots(),
    OutlineBody = [ #outline{ gn_id={?MODULE,binary_to_list(Node)} } || Node <- Roots ],
    [FirstNode|_] = Roots,
    #graph_node{ text = Text } = visiweave_node_server:read_node(FirstNode),
    wf:wire(wf:f("jQuery('.resizable').resizable({handles: \"e\"})")),
    wf:wire(textarea, textarea, #event{ type=blur, postback=blur_text }),
    wf:defer(".gn_"++binary_to_list(FirstNode), #script{ script=wf:f("$(~p).focus()", [".gn_"++binary_to_list(FirstNode)]) }),
    [
	#flash{},
	#panel{
	    style="height:100%;margin-left:50px;margin-right:50px;margin-top:0px;",
	    body=
	    #table{
		style="height:100%;width:100%",
		rows=[
		    #tablerow{
			cells=[
			    #tablecell{
				class="resizable",
				style="border-right:1px solid;vertical-align:top",
				body=
				#panel{
				    style="margin-top:0px",
				    body=OutlineBody
				}
			    },
			    #tablecell{
				style="height:100%;padding:2px 2px 10px 2px;",
				class="resizable",    
				body=[
				    #textarea{
					id="textarea",
					style="height:99%;width:99%;display:table-cell;border:none",
					text=binary_to_list(Text)},
				    #hidden{
					id="current_node", text=binary_to_list(FirstNode)}
				]
			    }
		    ]}
		]
	    }
    }].

vw_element_event(Other) ->
    wf:update(placeholder, Other),
    ?PRINT({vw_element_event, Other}).

event(blur_text) ->
    StringKey = wf:q(current_node),
    Key       = list_to_binary(StringKey),
    Text      = list_to_binary(wf:q(textarea)),
    ?PRINT({blur_text, StringKey, Text}),
    #graph_node{
	title = Title,
	text = OldText,
	children = ChildList } = visiweave_node_server:read_node(Key),
    case Text of
	OldText -> ok;
	_ ->
	    element_outline:push_onto_write_stack(
		StringKey,
		binary_to_list(Title),
		binary_to_list(OldText),
		[binary_to_list(C) || C <- ChildList]),
	    visiweave_node_server:write_node(#graph_node{
		key = Key,
		title = Title,
		text = Text,
		children = ChildList})
    end;
    
event(Other) ->
    wf:update(placeholder, Other),
    ?PRINT({event, Other}).

% translate from visiweave_model record with binary members to outline element expected tuple with list members
read_node(Id) ->
    #graph_node{ title = Title,
	text = Text,
	children = ChildList } = visiweave_node_server:read_node(list_to_binary(Id)),
    {
	binary_to_list(Title),
	binary_to_list(Text),
	[binary_to_list(Child) || Child <- ChildList]
    }.

write_node(Key, Title, Text, ChildList) ->
    visiweave_node_server:write_node(#graph_node{
	key = list_to_binary(Key),
	title = list_to_binary(Title),
	text = list_to_binary(Text),
	children = [list_to_binary(Child) || Child <- ChildList]}).

new_node() ->
    New = binary_to_list(visiweave_node_server:next_node()),
    ?PRINT(New),
    New.

read_roots() ->
    #graph_node{ children = Roots } = visiweave_node_server:read_roots(),
    [ binary_to_list(Root) || Root <- Roots ].

write_roots(Roots) ->
    visiweave_node_server:write_roots([list_to_binary(Root) || Root <- Roots]).
