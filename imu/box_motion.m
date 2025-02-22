function [q, w, d, yp, r] = box_motion(md, boxmarkers, ekf, origin)
%%  [q, w, d] = box_motion(md, boxmarkers, ekf)
%% Calculates the motion of the box, given marker data. The orientation is
%% given by a quaternion representing the rotation with respect to the
%% orientation of a body frame coinciding with the laboratory spatial
%% frame at the first frame of data.
%%
%% Input
%%   md          ->  cell array with marker data {attributes, data}
%%   boxmarkers  ->  cell array with  markernames
%%   ekf         ->  if different from zero, will be interpreted as the
%%                   bandwidth parameter used in an EKF for estimating the orientation
%%                   and velocity.
%% Output
%%   q           <-  quaternion (4xnfr) representing the orientation of
%%                   the box.
%%   w           <-  angular velocity in the body frame.

%% Kjartan Halvorsen
%% 2012-05-15

if (nargin == 0)
  do_unit_test();
else

  if (nargin < 3)
    ekf = 0;
  end

  if iscell(md)
    fs = str2double(getvalue(md{1}, 'FREQUENCY'));
    dt = 1/fs;

    nmarkers = length(boxmarkers);
    nfr = size(md{2},1);
    Y = extractmarkers(md, boxmarkers);
  else
    Y = md;
    nmarkers = size(Y,2)/3;
    nfr = size(Y,1);
    dt = boxmarkers;
  end 
  if ekf
    x0 = zeros(9,1);
    Q = diag([1/dt 1/dt 1/dt 0.1 0.1 0.1  1/dt 1/dt 1/dt ].^2)*ekf;
    %%Q = eye(9);
    P0 = 10*Q;
    A = eye(9);
    A(4:6, 7:9) = dt*eye(3);
    
    %%R = (0.01).^2*eye(nmarkers*3); % Measurement noise
    R = eye(nmarkers*3); % Measurement noise
    Rinv = inv(R);

    q = zeros(4, nfr);
    w = zeros(3,nfr);
    d = zeros(3,nfr);
    yp = zeros(nmarkers*3,nfr);
    r = zeros(nmarkers*3,nfr);

    x = x0;
    P = P0;

    p0 = reshape(Y(1,:), 3, nmarkers);
    d0 = mean(p0, 2);
    r0 = cat(1, p0 - repmat(d0, 1, nmarkers), \
	     zeros(1, nmarkers));
    
    qfr = [0;0;0;1];

    resfunc = "observe_box";
    rfparams = {qfr, dt, d0, r0};
    for fr = 1:nfr
      y = Y(fr,:)';

      %% Prediction
      xpred = A*x;
      Pp = A*P*A' + Q;

      %% Update

      %% Use Todorovs implementation
      %%[x, P, S, res, ypred] = ekf_update(y, xpred, Pp, resfunc, rfparams, R);
      [x, P] = ekf_update(y, xpred, Pp, resfunc, rfparams, R);
      
      %% Do it inline (must be debugged)?
      %%[r, pred, J] = observe_box(y, xpred, qfr, dt, d0, r0);
      %%Pinv = inv(Pp);
      %%JV = J'*Rinv;
      %%grad = JV*r;
      %%H = Pinv + JV*J;
      %%Hinv = inv(H);
      
      %%x = xpred - Hinv*grad;
      %%P = Hinv;
      
      qfr = qmult(qfr, qexp(dt*x(1:3)));
      rfparams{1} = qfr;
      q(:,fr) = qfr;
      w(:,fr) = x(1:3);
      %%d(:,fr) = x(4:6);
      %%yp(:,fr) = ypred;
      %%r(:,fr) = res;
    end
  else %% Direct computation from quaternion

    g = getMotion(md, boxmarkers);

    q = zeros(4,nfr);
    for fr = 1:nfr
      gfr = reshape(g(fr,:), 4, 4);
      q(:,fr) = rotation2quaternion(gfr(1:3,1:3));
    end

    qdot = (centraldiff(q', fs))';
    
    w = zeros(3,nfr);

    d = g(:,13:15)';

    for fr = 1:nfr
      wq = 2*qmult(qconj(q(:,fr)), qdot(:, fr));
      w(:,fr) = wq(1:3);
    end
  end
end


function do_unit_test()

disp('Unit test for box_motion')

  test = 2;

  if (test == 1)
    N = 100;
    phi = linspace(0,2*pi,N)';
    sp = sin(phi);
    cp = cos(phi);
    sp2 = sin(phi+pi/2);
    cp2 = cos(phi+pi/2);
    sp3 = sin(phi+pi);
    cp3 = cos(phi+pi);
    z = zeros(size(sp));
    Y = [cp sp z cp2 sp2 z cp3 sp3 z];
    
    [q,w,d,yp,res] = box_motion(Y, 0.01, 1);
    
    figure(1)
    clf
    plot(w'*180/pi);

    keyboard
    return
  else
    [b,a] = butter(4, 40/100); %% Low pass filter marker data
    
    md = openmocapfile('', './prnyplnz1.tsv');
    md{2} = filtfilt(b, a, md{2});

				%keyboard
    
    %%md{2} = md{2}(5700:7000,:);

    [q,w,d] = box_motion(md, {'box1','box2','box3','box4'}, 0);

    save -binary PRNyPLNz_noekf q w d md

    figure(2)
    clf
    plot(w'*180/pi);

    save 
  end

 