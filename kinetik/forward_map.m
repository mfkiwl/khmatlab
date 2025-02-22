function [gst,ndofs]=forward_map(tws, g0, th, gprox)
%  [gst]=forward_map(tws, g0, th, gprox)
% Forward map for manipulator defined by nested array of twists tws. 
% WHen gst is operated on a point in the local frame of the end point it gives that point's
% position in the spatial frame for the current configuration of the linkage.
%        p^s(th) = gst(th) * p^t, 
% where the superscript t stands for 'tool frame'.
%      
%
% Input
%    tws   ->   nested cell array with twists
%    g0    ->   nested cell array with local frames. Only that of the endpoints will be used.
%    th    ->   generalized coordinates (nsts x 1) vector.
%    gprox ->   the forward map of the proximal part of the linkage.
%
% Output
%    gst   <-   the forward map, a (4 x 4 x n_endpoints) matrix.

% Kjartan Halvorsen
% 2013-07-08
%
%

if (nargin == 0)
   do_unit_test();
   return
end

if (nargin == 3)  % Initial call
  gprox = eye(4);
end

% First the "own" forward map, then the branches
try
mytws=tws{1};
nn=length(mytws);
myx=th(1:nn);

catch
     keyboard
end

for st=1:nn
   gprox = gprox * expm(mytws{st}*myx(st));
end

ndofs = nn;

% ----------------------------------------------------------
% Call function recursively
% to get the position and jacobian of the distal segments.
% ----------------------------------------------------------

nbranches = length(tws) - 1;

if (nbranches == 0)
   %% This is an endpoint. Multiply with g0
   gst = gprox * g0{1};
else
  %% Branches exist
  startind = ndofs+1;
  gst = [];
  twsbr=tws(2:length(tws));
  xelems = size(th,1);
  for br=1:length(twsbr)
    [gstbr, ndofsbr] = forward_map(twsbr{br}, g0{br+1}, th(startind:xelems, 1), gprox);
    startind = startind+ndofsbr;
    ndofs = ndofs + ndofsbr;
    gst = cat(3, gst, gstbr);
  end
end


function do_unit_test()
	    l1 = 1;
	    l2 = 2;
	    m1 = 1;
	    m2 = 2;
	    m3 = 0.6;
	    m4 = 0.3;

	    sm = scara_robot_model(l1, l2, m1, m2, m3, m4);

	    th = randn(4,1);

	    gst = forward_map(sm.twists, sm.g0, th);

	    %% According to eq (3.4) p 89 of Murray, Li, Sastry
	    th1 = th(1);
	    th2 = th(2);
	    th3 = th(3);
	    th4 = th(4);

	    R = [cos(th1+th2+th3) -sin(th1+th2+th3) 0
		 sin(th1+th2+th3) cos(th1+th2+th3) 0
		 0    0 1];
	    p = [-l1*sin(th1)-l2*sin(th1+th2)
		 l1*cos(th1)+l2*cos(th1+th2)
		 th4];
	    gst_true = [ R p
			 0 0 0 1];

	    %%keyboard
	    assert(gst, gst_true, 1e-12)
	    disp('Test1 OK')

