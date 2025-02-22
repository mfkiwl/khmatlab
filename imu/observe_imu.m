function [y]=observe_imu(x)
%  [y]=observe_imu(x, qi)
% Measurement function for an imu with orientation represented by
% a quaternion. 
%
% Input
%    x      ->   the current state. (n x N) vector.  x=[d,v,acc,q,w,alpha]

% Output
%    y     <-   the measurements [acc;w]

% Kjartan Halvorsen
% 2012-03-27
%
%

if (nargin == 0)
  do_unit_test();
else
  N = size(x,2);

  %% Both acceleration and angular velocity are given in the body frame.
  
  y = x([7:9 14:16],:);
  
  return
  
  for sp = 1:N
    acc = x(7:9,sp);
    w = x(14:16,sp);
    
    %% Rotate the acceleration
    y(1:3,sp) = qtransv(acc,qbs);
    
    %% Rotate the angular velocity
    %y(4:6,sp) = qtransv(w, qbs);
    %% or not
    y(4:6,sp) = w;
  end
end

function do_unit_test()
  disp("Unit test for function observe_imu")

  %% Rotation about 
  ax = [0;0;1];
  %% a fixed angualar velocity
  w0 = 100/180*pi; % rad/sangle 
  %% The axis is at 
  r = 1;
  p0 = [-r;0;0]; % in static frame
  %% The orientation of the imu is currently after a quarter rotation,
  %% so local x-axis is pointing in static y-direction
  d = [-r;r;0];
  %% The velocity is tangential, so
  v = [-r*w0;0;0];
  %% The acceleration is radial, so
  acc = [0; -w0^2*r;0];
  %% The orientation is 
  q = quaternion([0;0;1], pi/2)';
  %% The angular velocity is fixed, so
  w = [0;0;w0];
  %% The angular acceleration is zero
  alpha = [0;0;0];

  y = observe_imu(cat(1, d,v,acc,q,w,alpha));

  %% The acceleration should be in negative body x-direction
  if (norm(y(1:3) - [-w0^2*r;0;0]) > 1e-12)
    disp('Test1: Failed')
    disp('Expected'), disp([-w0^2*r;0;0])
    disp('Found'), disp(y(1:3))
  else
    disp('Test1: OK')
  end    

  %% The angular velocity should be in positive body z-direction, same
  %% as for the static frame
  if (norm(y(4:6) - w) > 1e-12)
    disp('Test2: Failed')
    disp('Expected'), disp(w)
    disp('Found'), disp(y(4:6))
  else
    disp('Test2: OK')
  end    
