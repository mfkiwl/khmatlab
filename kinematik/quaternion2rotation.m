function R = quaternion2rotation(q)
%  R = quaternion2rotation(q)
% Computes the rotation matrix corresponding to a quaternion

% Kjartan Halvorsen 
% 2007-06-13

if (nargin == 1)
%%  q0=q(1);
%% q1=q(2);
%%  q2=q(3);
%%  q3=q(4);

  q0=q(4);
  q1=q(1);
  q2=q(2);
  q3=q(3);

  R = [1-2*(q2^2+q3^2) 2*q1*q2-2*q0*q3 2*q1*q3+2*q0*q2
       2*q1*q2+2*q0*q3 1-2*(q1^2+q3^2) 2*q2*q3-2*q0*q1
       2*q1*q3-2*q0*q2 2*q2*q3+2*q0*q1 1-2*(q1^2+q2^2)];
else
  % Unit test
  w1 = [1;0;0];
  w2 = [0;1;0];
  RR = expm_rodrigues(hat(w1), pi/3)*expm_rodrigues(hat(w2), pi/5);
  
  q = rotation2quaternion(RR);
  R = quaternion2rotation(q);
  
  norm(q)
  q
  R
  RR
  
  for i=1:1000
    q = randn(4,1);
    q = q/norm(q);
    R = quaternion2rotation(q);
    qq = rotation2quaternion(R);
    
    if ( (sum(abs(q-qq)) > 1e-14) )
      if ((sum(abs(q+qq)) > 1e-14)) 
	disp('quaternion2rotation unit test: test failed');
	disp('Expected')
	q
	disp('Found')
	qq
      end
    end
  end
end
