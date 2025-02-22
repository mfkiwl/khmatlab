function [twn, Ad_g_inv] = adjoint_trf_inv(tw, g)
%  [twn, Ad_g_inv] = adjoint_trf_inv(tw, g)
% Transforms the twist tw into twn by applying the inverse adjoint transformation associated with g.
% See eq 2.58 in Murray, Li, Sastry:
%   Ad_g = [R'  -\hat{R'p}R' ]
%          [0      R'    ],
% where 
%   g = [R  p]
%       [0  1].

%% Kjartan Halvorsen
% 2013-05-31

if nargin==0
    do_unit_test()
else
    
  if size(tw,1) == 4
    twv = vee(tw);
  else
    twv = tw;
  end

  R = g(1:3, 1:3);
  p = g(1:3, 4);

  Ad_g_inv = [ R'  -hat(R'*p)*R'
	       zeros(3,3) R'];

  twn = Ad_g_inv*twv;

  if size(tw, 1) == 4
    twn = hat(twn);
  end
end
end

function do_unit_test()
    tws0 = randn(6,1);
    
    twsrot = randn(6,1);
    g = expm(hat(twsrot));
    
    [twsr, Ad_inv] = adjoint_trf_inv(tws0, g);
    twsr2 = Ad_inv * tws0;
    
    [tws, Ad] = adjoint_trf(twsr, g);
    tws2 = Ad*twsr2;
    
    tol = 1e-12;
    
    if norm(tws0 - tws) > tol
        disp(sprintf('Test %d failed', 1))
        disp('Expected'), tws0
        disp('Found'), tws
    else
        disp(sprintf('Test %d OK', 1))
    end
    if norm(tws0 - tws2) > tol
        disp(sprintf('Test %d failed', 2))
        disp('Expected'), tws0
        disp('Found'), tws2
    else
        disp(sprintf('Test %d OK', 2))
    end
end
    

