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
    #graph_node{ children = Roots } = visiweave_node_server:read_roots(),
    OutlineBody = [ #outline{ gn_id={?MODULE,binary_to_list(Node)} } || Node <- Roots ],
    [FirstNode|_] = Roots,
    #graph_node{ text = Text } = visiweave_node_server:read_node(FirstNode),
    wf:wire(wf:f("jQuery('.resizable').resizable({handles: \"e\"})")),
    wf:wire(textarea, textarea, #event{ type=blur, postback=blur_text }),
    % fails if done within an element
    wf:wire(#api{ name=control_key, tag=[], delegate=element_outline }),
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
				style="borders-right:1px solid;vertical-align:top",
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
					style="height:99%;width:99%;display:table-cell;",
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
    Key = list_to_binary(wf:q(current_node)),
    Text = list_to_binary(wf:q(textarea)),
    #graph_node{ title = Title,
	text = OldText,
	children = ChildList } = visiweave_node_server:read_node(Key),
    case Text of
	OldText -> ok;
	_ ->
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
