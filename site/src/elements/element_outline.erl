%% -*- mode: nitrogen -*-
%% vim: ts=4 sw=4 et
-module (element_outline).
-include_lib("nitrogen_core/include/wf.hrl").
-include("records.hrl").
-include("visiweave_model.hrl").
-export([
    reflect/0,
    render_element/1,
    event/1,
    api_event/3,
    push_onto_write_stack/4,
    pop_from_write_stack/0
]).

%% Done: update textarea with node text
%% Done: attach node read to focus event
%% Done: indicate no children with bullet of "O"
%% Done: uncollapse handled by javascript
%% Done: collapse handled by javascript
%% Done: node write title on blur event
%% Done: node write text on blur event
%% Done: node insert
%% Next: Undo.  Keep a stack of previous node states, pop and apply them.
%% - insert node working
%% - undo title change not working
%% Next: node delete
%% Next: node right
%% Next: node left
%% Next: right click menu on title
%% Next: scroll bar for outline
%% Next: scroll bar for text
%% Next: set size for outline to be screen (not more)
%% Next: set size for text to be screen (not more)
%% Next: +/- a la workflowy.com
%% Next: Hoist a la worflowy.com
-spec reflect() -> [atom()].
reflect() -> record_info(fields, outline).

%%%%%%%% IMPORTANT %%%%%%%%%%
% This element requires:
% a page state key 'undo' used as a stack of changes
% the gn_id is {Module, Key}, such that
% Module exports: read_roots, write_roots, read_node, write_node, next_node
% such that:
% * Key is a character list of 40 hexadecimal digits
% * {Title, Text, ChildList} = Module:read_node(Key)
% where Title and Text are strings and ChildList is a list of Keys
% * Module:write_node(Key, Title, Text, ChildList) writes the information
% * Key = Module:new_node() returns a string of 40 hexadecimal digits for a new node
% * Module:read_roots() returns a list of strings
% * Module:write_roots() writes a list of strings

-spec render_element(#outline{}) -> body().
render_element(#outline{ gn_id={Module, Arg} }) ->
    case wf:state_default(api_control_key, false) of
	false ->
	    wf:wire(#api{ anchor=page, name=control_key, tag=[], delegate=element_outline }),
	    wf:state(api_control_key, true);
	_ -> ok
    end,
    UnitID = wf:temp_id(),
    ArrowID = wf:temp_id(),
    TitleID = wf:temp_id(),
    wf:wire(TitleID, TitleID, #event {
    	type = click,
    	delegate = ?MODULE,
    	postback = { click, {title, UnitID, TitleID, {Module, Arg} } }
    }),
    wf:wire(TitleID, TitleID, [
	#event {
	    type = focus,
	    delegate = ?MODULE,
	    actions = #add_class{ class=selected, speed=0 },
	    postback = { focus, {title, UnitID, TitleID, {Module, Arg} } }
	}
    ]),
    { Title, _, ChildList } = Module:read_node(Arg),
    wf:wire(TitleID, TitleID, [
	#event {
	    type = blur,
	    delegate = ?MODULE,
	    actions = #remove_class{ class=selected, speed=0 },
	    postback = {blur_title, TitleID, {Module, Arg}}
	}
    ]),
    wf:wire(TitleID, TitleID, #event {
	type = keypress,
	actions = [
	    #script { script=wf:f("if (event.ctrlKey && ([105,121,122].indexOf(event.which) >= 0)) {
		event.preventDefault();
		event.stopPropagation();
		var me = $(~p);
		var node_index = me.index();
		var key_pattern = /gn_[0-9a-f]{40}/;
		var parent_key = key_pattern.exec(me.parent().prev().attr('class'));
		if (parent_key == null) {
		    parent_key = 'root';
		} else {
		    parent_key = parent_key.slice(3,43);
	        }
		page.control_key(event.which, ~p, '~p', parent_key, node_index); };", [".wfid_"++TitleID, UnitID, Module]) }
	]
    }),
    [
	#panel{ id=UnitID, body= [
	    #span{ id=ArrowID, body = [#button{ text=
		case ChildList of
		    [] ->
			"O";
		    _ -> 
			wf:wire(ArrowID, ArrowID, #event {
			    type = click,
			    delegate = ?MODULE,
			    postback = { click, {expand, UnitID, ArrowID, {Module, Arg} } }
			}),
			">"
		end
	    }]},
	    #textbox{ id=TitleID,  class="gn_"++Arg, text=Title }
	]}
    ].

event({click, {expand, UnitID, ArrowID, { Module, Arg }}}) ->
    ?PRINT({click, {expand, UnitID, ArrowID, { Module, Arg }}}),
    ExpandedArrowID = wf:temp_id(),
    ContractedArrowID = wf:temp_id(),
    wf:replace(ArrowID, [
	#span{ id=ExpandedArrowID,   body=[#button{ text="V" }] },
	#span{ id=ContractedArrowID, body=[#button{ text=">" }], style="display: none" } ]
    ),
    {_, _,  ChildList } = Module:read_node(Arg),
    Body = [
	#outline{ gn_id={Module, C} } || C <- ChildList ],
    case ChildList of
	[] -> ok;
	_ ->
	    ChildrenID = wf:temp_id(),
	    Event = #event {
		type = click,
		actions = [
		    #toggle{ target=ExpandedArrowID },
		    #toggle{ target=ContractedArrowID },
		    #toggle{ target=ChildrenID, options=[{duration, 800}] }
		]
	    },
	    wf:insert_bottom(UnitID, #panel{ style="margin-left: 32px", id=ChildrenID, body=Body}),
	    wf:wire(ExpandedArrowID, ExpandedArrowID, Event),
	    wf:wire(ContractedArrowID, ContractedArrowID, Event)
    end;

event({focus, {title, UnitID, TitleID, { Module, Arg }}}) ->
% It would be better to use browser "canonical" values for Title and Text;
% if it becomes a problem, set up a browser side hash from Arg to { title: , text: }
    ?PRINT({focus, {title, UnitID, TitleID, { Module, Arg }}}),
    { Title, Text, _ } = Module:read_node(Arg),
    wf:set(".gn_"++Arg, Title),
    wf:set(current_node, Arg),
    wf:set(textarea, Text);

event({blur_title, TitleID, {Module, Arg}}) ->
    ?PRINT({blur_title, TitleID, Arg}),
    {OldTitle, Text, ChildList} = Module:read_node(Arg),
    Title = wf:q(TitleID),
    case Title of
	OldTitle -> ok;
	_ ->
	    push_onto_write_stack(Arg, OldTitle, Text, ChildList),
	    Module:write_node(Arg, Title, Text, ChildList)
    end;
    
event(Any) ->
    ?PRINT({Any}).

api_event(control_key, _Tag, [KeyCode, UnitID, ModuleString, Parent, ChildIndex]) ->
    Module = list_to_existing_atom(ModuleString),
    case KeyCode of
    	105 ->
    	    % ctrl-i - insert a node
    	    % obtain a new node
	    
    	    NewNode = Module:new_node(),
    	    % insert the new node at the index just after the focused node in the parents list
    	    % - we need to know the parent key
    	    % - we need to know the index of the focused node
	    case Parent of
		"root" ->
		    OldRoots = Module:read_roots(),
		    NewRoots = lists:sublist(OldRoots, ChildIndex) ++
		    [NewNode] ++
		    lists:sublist(OldRoots, ChildIndex+1, length(OldRoots)-ChildIndex),
		    push_onto_write_stack("root", "", "", OldRoots),
		    Module:write_roots(NewRoots),
		    wf:insert_after(UnitID, #outline{ gn_id={Module, NewNode} })
		    ;
		_ ->
		    {Title, Text, OldChildren} = Module:read_node(Parent),
		    NewChildren = lists:sublist(OldChildren, ChildIndex) ++
		    [NewNode] ++
		    lists:sublist(OldChildren, ChildIndex+1, length(OldChildren)-ChildIndex),
		    push_onto_write_stack(Parent, Title, Text, OldChildren),
		    Module:write_node(Parent, Title, Text, NewChildren),
		    wf:insert_after(UnitID, #outline{ gn_id={Module, NewNode} })
	    end;
	122 ->
	    % ctrl-z - undo
	    case pop_from_write_stack() of
		empty -> ok;
		{Key, Title, Text, Children} ->
		    case Key of
			"root" ->
			    Module:write_roots(Children);
			_ ->
			    Module:write_node(Key, Title, Text, Children)
		    end
		    %  * find all instances on the page of the Key
		    %  * starting with the last (and thus deepest) instance
		    %    * replace the title
		    %    * compare the child lists, returning a list of adds/removes
		    %      * no differences: done
		    %      * child removed: remove
		    %      * child added: add collapsed
		    %      * add/removes look like (add, index, key) or (remove, index)
	    end;
	_ ->
	    Msg = wf:f("Control-~p pressed",[KeyCode]),
	    wf:flash(Msg)
    end.

push_onto_write_stack(Key, Title, Text, ChildList) ->
    wf:state(undo, [{Key, Title, Text, ChildList}|wf:state(undo)]).

pop_from_write_stack() ->
    case wf:state(undo) of
	[Top|Remainder] ->
	    wf:state(undo, Remainder),
	    Top;
	[] ->
	    empty
    end.
