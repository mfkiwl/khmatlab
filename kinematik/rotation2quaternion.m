function q = rotation2quaternion(R, twobytwo) 
%  q = rotation2quaternion(R [, twobytwo]) 
% Computes the quaternion representation of a rotation matrix.
% If optional input twobytwo exists and is not zero, the output is
% a (2x2) imaginary matrix

% From D.C. Agnew 2006

% Kjartan Halvorsen
% 2007-06-13

if (nargin < 2)
  twobytwo = 0;
end


q0 = 0.5*sqrt(1 + R(1,1) + R(2,2) + R(3,3));
q1 = 0.5*sqrt(1 + R(1,1) - R(2,2) - R(3,3));
q2 = 0.5*sqrt(1 + R(2,2) - R(1,1) - R(3,3));
q3 = 0.5*sqrt(1 + R(3,3) - R(1,1) - R(2,2));

qabs = abs([q0 q1 q2 q3]);
qmax = max(qabs);

if (qabs(1) == qmax)
  %disp('rotation2quaternion: q0 is largest')
  q1 = (R(3,2) - R(2,3)) / (4*q0);
  q2 = (R(1,3) - R(3,1)) / (4*q0);
  q3 = (R(2,1) - R(1,2)) / (4*q0);
elseif (qabs(2) == qmax)
  q0 = (R(3,2) - R(2,3)) / (4*q1);
  q2 = (R(1,2) + R(2,1)) / (4*q1);
  q3 = (R(1,3) + R(3,1)) / (4*q1);
elseif (qabs(3) == qmax)
  q0 = (R(1,3) - R(3,1)) / (4*q2);
  q1 = (R(1,2) + R(2,1)) / (4*q2);
  q3 = (R(2,3) + R(3,2)) / (4*q2);
elseif (qabs(4) == qmax)
  q0 = (R(2,1) - R(1,2)) / (4*q3);
  q1 = (R(1,3) + R(3,1)) / (4*q3);
  q2 = (R(2,3) + R(3,2)) / (4*q3);
end

if twobytwo
  q = [q0+i*q1 q2+i*q3
       -q2+i*q3 q0-i*q1];
else
%%  q = [q0;q1;q2;q3];
  q = [q1;q2;q3;q0];
end
