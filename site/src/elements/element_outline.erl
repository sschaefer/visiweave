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
    api_event/3
]).

%% Done: update textarea with node text
%% Done: attach node read to focus event
%% Done: indicate no children with bullet of "O"
%% Done: uncollapse handled by javascript
%% Done: collapse handled by javascript
%% Done: node write title on blur event
%% Done: node write text on blur event
%% Next: node insert
%% Next: node delete
%% Next: right click menu on title
%% Next: scroll bar for outline
%% Next: scroll bar for text
%% Next: set size for outline to be screen (not more)
%% Next: set size for text to be screen (not more)
%% Next: +/- a la workflowy.com
%% Next: Hoist a la worflowy.com
-spec reflect() -> [atom()].
reflect() -> record_info(fields, outline).

% the gn_id is {Module, Function, Argument}, such that
% {Title, Text, ChildList} = Module:Function(Argument).
-spec render_element(#outline{}) -> body().
render_element(#outline{ gn_id={Module, Read, Write, Arg} }) ->
%    ?PRINT({Module, Read, Write, Arg}),
    UnitID = wf:temp_id(),
    ArrowID = wf:temp_id(),
    TitleID = wf:temp_id(),
    wf:wire(TitleID, TitleID, #event {
    	type = click,
    	delegate = ?MODULE,
    	postback = { click, {title, UnitID, TitleID, {Module, Read, Write, Arg} } }
    }),
    wf:wire(TitleID, TitleID, #event {
	type = focus,
	delegate = ?MODULE,
	postback = { focus, {title, UnitID, TitleID, {Module, Read, Write, Arg} } }
    }),
    { Title, _, ChildList } = Module:Read(Arg),
    wf:wire(TitleID, TitleID, #event {
	type = blur,
	delegate = ?MODULE,
	postback = {blur_title, TitleID, {Module, Read, Write, Arg}}
    }),
    wf:wire(TitleID, TitleID, #event {
	type = keypress,
	actions = [
	    #script { script=wf:f("if (event.ctrlKey && ([105].indexOf(event.which) >= 0)) {
		event.preventDefault();
		event.stopPropagation();
		page.control_key('~p', '~p', event.which); };", [TitleID, Arg]) }
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
			    postback = { click, {expand, UnitID, ArrowID, {Module, Read, Write, Arg} } }
			}),
			">"
		end
	    }]},
	    #textbox{ id=TitleID,  class="gn_"++Arg, text=Title }
	]}
    ].

event({click, {expand, UnitID, ArrowID, { Module, Read, Write, Arg }}}) ->
%    ?PRINT({arrow, UnitID, ArrowID, { Module, Read, Write, Arg }}),
    ExpandedArrowID = wf:temp_id(),
    ContractedArrowID = wf:temp_id(),
    wf:replace(ArrowID, [
	#span{ id=ExpandedArrowID,   body=[#button{ text="V" }] },
	#span{ id=ContractedArrowID, body=[#button{ text=">" }], style="display: none" } ]
    ),
    {_, _,  ChildList } = Module:Read(Arg),
    Body = [
	#outline{ gn_id={Module, Read, Write, C} } || C <- ChildList ],
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

event({focus, {title, _UnitID, _TitleID, { Module, Read, _Write, Arg }}}) ->
% It would be better to use browser "canonical" values for Title and Text;
% if it becomes a problem, set up a browser side hash from Arg to { title: , text: }
    { Title, Text, _ } = Module:Read(Arg),
    wf:set(".gn_"++Arg, Title),
    wf:set(".current_node", Arg),
    wf:set(".textarea", Text);

event({blur_title, TitleID, {Module, Read, Write, Arg}}) ->
    {OldTitle, Text, ChildList} = Module:Read(Arg),
    Title = wf:q(TitleID),
    case Title of
	OldTitle -> ok;
	_ ->
	    Module:Write(Arg, Title, Text, ChildList)
    end;
    
event(Any) ->
    ?PRINT({Any}).

api_event(control_key, _Tag, [_TitleID, _GraphNodeKey, KeyCode]) ->
    Msg = wf:f("Control-~p pressed",[KeyCode]),
    wf:flash(Msg).
