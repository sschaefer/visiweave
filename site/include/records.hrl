%% Include the automatically generated plugins directory
-include("plugins.hrl").

%% Include any application-specific custom elements, actions, or validators below
-record(outline, {?ELEMENT_BASE(element_outline),
        gn_id           :: {atom(), atom(), text()},
	postback     :: term()
    }).

