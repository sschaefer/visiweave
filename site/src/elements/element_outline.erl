%% -*- mode: nitrogen -*-
%% vim: ts=4 sw=4 et
-module (element_outline).
-include_lib("nitrogen_core/include/wf.hrl").
-include("records.hrl").
-include("visiweave_model.hrl").
-export([
    reflect/0,
    render_element/1,
    event/1
]).

%% Done: update textarea with node text
%% Done: attach node read to focus event
%% Done: indicate no children with bullet of "O"
%% Next: node write on blur event
%% Next: node insert
%% Next: node delete
%% Next: right click menu on title
%% Next: collapse handled by javascript
%% Next: uncollapse handled by javascript
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
render_element(#outline{ gn_id=GNID }) ->
    % nitrogen seems to have trouble with bitstrings; convert
    { Module, Outline, Arg } = GNID,
    ?PRINT({Module, Outline, Arg}),
    UnitID = wf:temp_id(),
    ArrowID = wf:temp_id(),
    TitleID = wf:temp_id(),
    wf:wire(TitleID, TitleID, #event {
    	type = click,
    	delegate = ?MODULE,
    	postback = { click, {title, UnitID, TitleID, {Module, Outline, Arg} } }
    }),
    wf:wire(TitleID, TitleID, #event {
	type = focus,
	delegate = ?MODULE,
	postback = { focus, {title, UnitID, TitleID, {Module, Outline, Arg} } }
    }),
    wf:wire(TitleID, TitleID, #event {
	type = blur,
	delegate = ?MODULE,
	postback = { blur, {title, UnitID, TitleID, {Module, Outline, Arg} } }
    }),
    { Title, _, ChildList } = Module:Outline(Arg),
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
			    postback = { click, {expand, UnitID, ArrowID, {Module, Outline, Arg} } }
			}),
			">"
		end
	    }]},
	    #textbox{ id=TitleID,  class="gn_"++Arg, text=Title }
	]}
    ].

event({click, {expand, UnitID, ArrowID, GNID}}) ->
    { Module, Outline, Arg } = GNID,
    ?PRINT({arrow, UnitID, ArrowID, { Module, Outline, Arg }}),
    NewArrowID = wf:temp_id(),
    wf:replace(ArrowID, #span{ id=NewArrowID, body=[#button{ text="V" }] }),
    {_, _,  ChildList } = Module:Outline(Arg),
    Body = [
	#outline{ gn_id={Module, Outline, C} } || C <- ChildList ],
    case ChildList of
	[] -> ok;
	_ ->
	    ChildrenID = wf:temp_id(),
	    wf:insert_bottom(UnitID, #panel{ style="margin-left: 32px", id=ChildrenID, body=Body}),
	    wf:wire(NewArrowID, NewArrowID, #event {
		type = click,
		delegate = ?MODULE,
		postback = { click, {collapse, UnitID, NewArrowID, ChildrenID} }
	    })
    end;

event({click, {collapse, UnitID, ArrowID, ChildrenID}}) ->
    wf:update(ArrowID, #button{ text=">" }),
    wf:wire(ArrowID, ChildrenID, #hide{}),
    wf:wire(ArrowID, ArrowID, #event {
    	type = click,
    	delegate = ?MODULE,
    	postback = { click, {uncollapse, UnitID, ArrowID, ChildrenID} }
    });

event({click, {uncollapse, UnitID, ArrowID, ChildrenID}}) ->
    NewArrowID = wf:temp_id(),
    wf:replace(ArrowID, #span{ id=NewArrowID, body=[#button{ text="V" }] }),
    wf:wire(NewArrowID, ChildrenID, #show{}),
    wf:wire(NewArrowID, NewArrowID, #event {
	type = click,
	delegate = ?MODULE,
	postback = {click, {collapse, UnitID, NewArrowID, ChildrenID} }
    });

event({focus, {title, UnitID, TitleID, GNID}}) ->
    { Module, Outline, Arg } = GNID,
    ?PRINT({focus, {title, UnitID, TitleID, {Module, Outline, Arg}}}),
    { Title, Text, _ } = Module:Outline(Arg),
    wf:set(".gn_"++Arg, Title),
    wf:set(".textarea", Text);

event(Any) ->
    ?PRINT({Any}).
