function [qq, dqqdq, dqqdw] = qpropagate(q,w,dt)
  %% qq = qpropagate(q,w,dt)
  %% Propagates a quaternion assuming a fixed angular velocity w over the
  %% time interval dt 

  %% Kjartan Halvorsen
  %% 2011-03-20

  if (nargin == 0)
    do_unit_test();
  else
    qq = q;

    for i=1:size(q,2)
      try
      expw = qexp(w(:,i)*dt);
      qq(:,i) = qmult(q(:,i), expw);
      catch
	keyboard
      end
    end

    if (nargout > 1)
      %% Return jacobian. See Todorov 2007 p 1935
      v = w(1:3)*dt;
      %%expw = qexp(0.5*v);
      expw = qexp(v); %% New definition of quaternion exponential
      dqdq = eye(4);
      dqqdq = zeros(4,4);
      for i=1:4
	dqi = qmult(dqdq(i,:), expw);
	dqqdq(:,i) = dqi';
      end
      
      alpha = norm(v);
      if (alpha < 1e-6)
	sa = 1/2 - alpha^2/48;
	ca = -1/24 + alpha^2/960;
      else
	sa = sin(alpha*0.5)/alpha;
	ca = 1/alpha^2 * ( 0.5*cos(alpha*0.5)-sa);
      end
      dexpw = cat(1, ca*v*v' + sa*eye(3), -sa*0.5*v'); %*dt;
      dqqdw = zeros(4,3);
      for i=1:3
	dqqdw(:,i) = (qmult(q(1:4), dexpw(:,i)))';
      end
    end
  end

  function do_unit_test()
    disp("Unit test of function qpropagate")

    tol = 1e-12;

    q0 = quaternion([0;0;1], pi/2)';
    w0 = [0;0;1]*(-pi/2);

    v = randn(3,1);
    v = v/norm(v);
    th = rand(1,1);
    q2 = quaternion(v, th)';
    w2 = -v*th;

    qq = qpropagate(q0,w0,1);
    q1 = [0;0;0;1];
    if (norm(qq-q1) > tol)
      disp('Test 1: Failed')
      disp(sprintf("Unexpected result. Norm = %0.8f", norm(qq-q1)))
      disp('Expected'), disp(q1)
      disp('Found'), disp(qq)
    else
      disp('Test 1: OK')
    end

    qq = qpropagate(q2,w2,1);
    q1 = [0;0;0;1];
    if (norm(qq-q1) > tol)
      disp('Test 2: Failed')
      disp(sprintf("Unexpected result. Norm = %0.8f", norm(qq-q1)))
      disp('Expected'), disp(q1)
      disp('Found'), disp(qq)
    else
      disp('Test 2: OK')
    end

    qq = qpropagate(cat(2,q0,q2),cat(2, w0, w2),1);
    q1 = [0;0;0;1];
    q1 = cat(2, q1, q1);
    if (norm(qq-q1) > tol)
      disp('Test 3: Failed')
      disp(sprintf("Unexpected result. Norm = %0.8f", norm(qq-q1)))
      disp('Expected'), disp(q1)
      disp('Found'), disp(qq)
    else
      disp('Test 3: OK')
    end

    
    q = quaternion(randn(3,1), rand(1))';
    w = randn(3,1);
    qq = qpropagate(q,w,1);
    qq1 = qpropagate(qq,-w,1);

    if (norm(q-qq1) > tol)
      disp('Test 4: Failed')
      disp(sprintf("Unexpected result. Norm = %0.8f", norm(q-qq1)))
      disp('Expected'), disp(q)
      disp('Found'), disp(qq1)
    else
      disp('Test 4: OK')
    end
    
