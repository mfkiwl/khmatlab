function [Jst,ndofs]=spatial_manipulator_jacobian(tws, th, thind, gprox, Jstprox)
%% Jst=body_manipulator_jacobian(tws, th, gprox)
%% Returns the spatial manipulator jacobian for the kinematic linkage. 
%% See eq (3.54) in Lee, Murray, Sastry, p116
%% Input
%%   tws    ->  nested array of twists
%%   gsli   ->  nested array of transformations taking points in the local coordinate system of
%%              each link to the static frame for th=0
%%   th     ->  generalized coordinates
%%   gprox   -> proximal rigid transformations (4 x 4) matrix, 
%%                 g_i = expr(twsprox(1), thprox(1))* ... * expr(twsprox(i), thprox(i))
%% Output
%%   Jsb    <-  The jacobians, a ((6 x nsts x n_endpoints) matrix

%% Kjartan Halvorsen
%% 2013-06-04

if nargin == 0
  do_unit_test();
else

  if nargin == 2  % Initial call
    gprox = eye(4);
    Jstprox = zeros(6, size(th,1));
    thind = 0;
  end

  %% First the "own" Jacobian, then the branches

  mytws=tws{1};
  nn=length(mytws);
  myx=th(thind+1:thind+nn);
  
  Jst = Jstprox;
  for st=1:nn
    Jst(:,thind+st) = adjoint_trf(vee(mytws{st}), gprox);
    gprox = gprox * expm( mytws{st}*myx(st) );
  end

  ndofs = nn;

  % ------------------------------------------------
  %  The branches.
  %  Not completely general. Will only work if branching once into two branches
  % ------------------------------------------------

  nbranches = length(tws)-1;
  try
  if (nbranches>0) % Branches exist
     thind = thind + nn;
     Jst = repmat(Jst, [1 1 nbranches]);

     twsbr=tws(2:length(tws));
     nsts = size(th,1);
     for br=1:length(twsbr)
       [Jstbr,ndofsbr] = spatial_manipulator_jacobian(twsbr{br},...
						  th,...
						  thind,...
						  gprox, Jst(:,:,br));
       if (size(Jstbr,3) == 2)
	  Jst = Jstbr;
       else
	   Jst(:,:,br) = Jstbr;
       end
       thind = thind + ndofsbr;
       ndofs = ndofs + ndofsbr;
    end
  end
  catch
       keyboard
  end
end

function do_unit_test()

if 0
  l1 = 1;
  l2 = 2;


  %% Two scara robots 
  tws = { { hat([0;0;0;0;0;1]) }, 
	  { { hat([l1;0;0;0;0;1]) }, 
	    { { hat([l1+l2;0;0;0;0;1]) }, 
	      { { hat([0;0;1;0;0;0]) } }}},
	  { { hat([l1;l1;0;0;0;1]) }, 
	    { { hat([l1+l2;l1;0;0;0;1]) }, 
	      { { hat([0;0;1;0;0;0]) } }}}};

  th = [pi/4; pi/5; pi/6; pi/7; pi/8; pi/9; pi/10];

  Jst = spatial_manipulator_jacobian(tws, th);

  %% From p 119
  th1 = th(1);
  th2 = th(2);
  Jtrue = [0 l1*cos(th1) l1*cos(th1)+l2*cos(th1+th2) 0
	   0 l1*sin(th1) l1*sin(th1)+l2*sin(th1+th2) 0
	   0    0                 0                  1
	   0    0                 0                  0
	   0    0                 0                  0
	   1    1                 1                  0];

  if norm(Jst(1:6,1:4) - Jtrue) > 1e-12
    disp('Test 1 failed')
    disp('Expected'), Jtrue
    disp('Found'), Jst
  else
    disp('Test 1 OK')
  end

end

th = [pi/4; pi/5; pi/6; pi/7];
test_scara(th, 'Test 2');

th = zeros(4,1);
test_scara(th, 'Test 3');

th = zeros(4,1);
th(1) = pi/3;
test_scara(th, 'Test 4');

th = zeros(4,1);
th(2) = pi/3;
test_scara(th, 'Test 5');

th = zeros(4,1);
th(1) = pi/2;
th(2) = pi/3;
test_scara(th, 'Test 6');

for i = 7:30
  th = randn(4,1);
  test_scara(th, sprintf('Test %d', i));
end

function test_scara(th, tstr)

%% Scara robot. See example 3.8, p.118, Lee, Murray, Sastry
l1 = 1;
l2 = 2;

tws = { { hat([0;0;0;0;0;1]) }, 
	{ { hat([l1;0;0;0;0;1]) }, 
	  { { hat([l1+l2;0;0;0;0;1]) }, 
	    { { hat([0;0;1;0;0;0]) } }}}};

Jst = spatial_manipulator_jacobian(tws, th);

%% From p 119
th1 = th(1);
th2 = th(2);
Jtrue = [0 l1*cos(th1) l1*cos(th1)+l2*cos(th1+th2) 0
	 0 l1*sin(th1) l1*sin(th1)+l2*sin(th1+th2) 0
	 0    0                 0                  1
	 0    0                 0                  0
	 0    0                 0                  0
	 1    1                 1                  0];

tol = 1e-12;

if norm(Jst - Jtrue) > tol
   disp([tstr, ' failed'])
   disp('Expected'), Jtrue
   disp('Found'), Jst
else
   disp([tstr, ' OK'])
end
