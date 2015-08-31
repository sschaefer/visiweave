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
    wf:defer("$('.leftpanel').resizable(
	{
           handles: 'e',
           stop:    function(event, ui) {
	     ui.size.height=screen.availHeight-10;
	     $('.leftpanel').css('height', screen.availHeight-50);
	     $('.leftpanel textarea').css('height', screen.availHeight-50);
	     $('.container').css('overflow','hidden');
           },
           resize:  function(event, ui) {
             var leftpw=ui.size.width;
             $('.rightpanel').css('left', (leftpw+10)+'px');
             var rightpt=$('.rightpanel textarea');
             rightpt.css('left', (leftpw+15)+'px');
             rightpt.css('width', (screen.availWidth-(leftpw+20))+'px');
           }
        });"),
    wf:wire(textarea, textarea, #event{ type=blur, postback=blur_text }),
    wf:defer(#script{ script="$('.rightpanel, .textarea').css('height', (screen.availHeight-5)+'px');" }),
    wf:defer(".gn_"++binary_to_list(FirstNode), #script{ script=wf:f("$(~p).focus()", [".gn_"++binary_to_list(FirstNode)]) }),
    [
	#flash{},
	#panel{
	    class="container",
	    style="position: relative; height: 99%; margin-left:0px; margin-right:0px; margin-top:0px; margin-bottom:10px; overflow-x: hidden; overflow-y: hidden;",
	    body=[
		#panel{
		    class="leftpanel",
		    style="position: absolute; top: 0; bottom: 5px; width: 500px; overflow-y: auto; border-right: 2px; border-style: solid; border-color:#000; overflow-x: hidden;",
		    body=OutlineBody
		},
		#panel{
		    class="rightpanel",
		    style="position: absolute; top: 0; bottom: 5px; left: 510px;",
		    body=[
			#textarea{
			    id="textarea",
			    style="border: none; overflow-y: auto; postition: absolute; top: 0; bottom: 5px; width:500px;",
			    text=binary_to_list(Text)},
			#hidden{
			    id="current_node", text=binary_to_list(FirstNode)}
		    ]
		}
	    ]
	}
    ].

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
