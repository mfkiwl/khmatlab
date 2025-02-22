function [btws, bg0, bstates, stateinds] = get_branches(km, states)
%%  [btws, bg0, bstates] = get_branches(km, states)
%% Returns the twists, g0 and states for each articulation up to the endlink of each branch
%% Works only for a single branch.
%% Input
%%       km       ->  kinematic model struct
%%       states   ->  joint states (nsts x nfrs)
%% Output
%%       btws     <-  cell array of cell array of twists
%%       bg0      <-  cell array of local transformations
%%       bstates  <-  cell array of states, each (ni x nfrs), where ni is the degrees of 
%%                    freedom of the ni'th end link
%%       stateinds <- cell array of indices into the state vector, indicating which state 
%%                    variables the branch depends on.

%% Kjartan Halvorsen
%% 2013-07-03

if (nargin == 0)
   do_unit_test();
else
    
  if isfield(km, 'object_frame')
    g0 = km.object_frame;
  else
    g0 = km.g0;
  end
  [btws, bg0, bstates, stateinds] = split_branches(km.twists, g0, states, 1);

end

function [tws, g0, st, stinds] = split_branches(ttws, tg0, states, startind)

  tws = {ttws{1}};
  mydofs = length(tws{1});
  stinds = {startind:startind+mydofs-1}; 
  st = {states(stinds{1},:)};
  startind = startind+mydofs;


  nbrs = length(ttws) - 1;

  if (nbrs == 0)
    g0 = {tg0{1}};
  else
      g0 = {};
  end

  if nbrs > 1
     tws = repmat(tws, 1, nbrs);
     g0 = repmat(g0, 1, nbrs);
     st = repmat(st, 1, nbrs);
     stinds = repmat(stinds, 1, nbrs);
  end

%  try
  for br = 1:nbrs
      [btws, bg0, bst, bstinds] = split_branches(ttws{br+1}, tg0{br+1}, states, startind);
      tws{br} = cat(1, tws{br}, btws{1});
      g0{br} = bg0{1};
      st{br} = cat(1, st{br}, bst{1});
      stinds{br} = cat(2, stinds{br}, bstinds{1});
      startind = startind + size(bst{1}, 1);
  end
 % catch
 %      keyboard
 % end

function do_unit_test()

km1 = planar_link_model();
km2 = planar_link_model();

km.twists = {{zeros(4,4)}, km1.twists, km2.twists};
km.g0 = {eye(4,4), km1.g0, km2.g0};

states = randn(7, 3);

[btws, bg0, bstates] = get_branches(km, states);

keyboard


