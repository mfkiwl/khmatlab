function [xsmooth,Psmooth]=ekf_mechanism_fixint(y,x0,P0,R1,R2,dt,tws,p0,rmse)
%  [xhat,Phat]=ekf_kfixint(y,x0,P0,R1,R2,dt,tws,p0,rmse)
%		         
% Fixed-interval smoothing Extended Kalman Filter. Based on
% ekf_kfixint, with only difference that the sysfunc, obsfunc and
% noisefunc function names are explicit. This will allow the
% function to be compiled.
%    sysfunc       ->   The state transition function. 'trackf'
%    obsfunc       ->   The observation function. 'observe_mechanism_H'.
%    noisefunc     ->   Function determining how the process noise enters.
%			'identityM'
%
% Input
%    y             ->   The data vector.
%    x0            ->   The initial state estimate
%    P0            ->   The initial state covariance
%    R1            ->   The process noise covariance matrix
%    R2            ->   The measurement noise covariance matrix
%    dt            ->   The sampling time
%    tws           ->   Nested cell arrays of twists, determining
%                       the kinematic model
%    p0            ->   The reference positions of the markers
%    rmse          ->   The root mean square error in marker
%                       positions for the first frame. Used to
%                       detect divergence, and fall back to the
%                       inverse kinematics solution of function firststate.
% Output
%    xhat          <-   The state estimates
%    Phat          <-   The state covariance estimates
%

% Kjartan Halvorsen
% 2002-11-20
%
% Revisions
% 2003-09-23   Detecting divergence, fall back to firststate and
%              restart the ekf

rmse_tol = 1.3; % Tolerate 30% larger innovations than rmse of
                % initial marker residuals
rmse_tol = 2;  % Tolerate 200% larger innovations than rmse of
                % initial marker residuals

checkformarkererrors = 0; % Performs a check for errors in marker
                          % data at each time frame. 

[d,N]=size(y);

n=length(x0);

if (size(R1,3)==1) % Process noise is time invariant
  isR1ti=1;
  % diagonalize
  if size(R1,2)==1
    G=diag(sqrt(R1));
  else    
    G=chol(R1)';
  end
else
  isR1ti=0;
end
p=size(R1,1);

Gt=eye(n);

n2=n/2;
Ft=[eye(n2) dt*eye(n2) ; zeros(n2,n2) eye(n2)];
Ftinv=inv(Ft);

if (size(R2,3)==1) % Measurement noise is time invariant
  isR2ti=1;
else
  isR2ti=0;
end

% initialization

xt=x0;
Pt=P0;

xhat=zeros(n,N);
Phat=zeros(n,n,N);

restart = 0;
for t=1:N

  %warning('ekf-warning', ...
  %        ['ekf_mechanism_fixint: t=', int2str(t)])
  xhat(:,t)=xt;
  Phat(:,:,t)=Pt;
  
   % The measurement noise
   if isR2ti
     R2t=R2;
   else
     R2t=R2(:,:,t);
   end

   % The observation function returns the estimates ouput yhat, and
   % the linearized observation function.
   if checkformarkererrors
     [yhatt,Ht,slsk, y(:,t)]=observe_mechanism_H(xt,y(:,t),tws,p0,...
						 {Pt, R2t});
   else
     [yhatt,Ht]=observe_mechanism_H(xt,y(:,t),tws,p0);
   end
   
   % The innovations
   et = y(:,t)-yhatt;

   etrms = et(find(y(:,t) ~= 0));
   if ( sqrt(mean(etrms.*etrms)) > rmse_tol*rmse & t > 8)
     restart = t;
     break
   end
   
   
 
   % The kalman gain
   HPHR=Ht*Pt*Ht'+R2t;
   Kt=Pt*Ht'*inv(HPHR);

   % The filter update
   xtt=xt + Kt*et;

   %Ptt=Pt - Kt*Hbar*Pt;
   Ptt=Pt - Kt*Ht*Pt;
   
   % Prediction
   xt=Ft*xtt;

   % The process noise
   if ~isR1ti
     R1t=R1(:,:,t);
     % factorize
     G=chol(R1t)';
   end

   Pt=Ft*Ptt*Ft'+G*G';
end
	
% Then a backward pass to obtain the smoothed estimates

if restart
  N = restart-1;
end

Psmooth=zeros(n,n,N);
xsmooth=zeros(n,N);
xsmooth(:,end)=xtt;
Psmooth(:,:,end)=Ptt;

for t=N-1:-1:1
%  warning('ekf-warning', ...
%          ['ekf_mechanism_fixint: t=', int2str(t)])
  % Get Ft and Gt
  xt=Ft*xhat(:,t);

  % The process noise
  if ~isR1ti
    R1t=R1(:,:,t);
    % factorize
    G=chol(R1t)';
  end

  
  St=G'*inv(Phat(:,:,t+1));
  Mt=eye(p)-St*G;
  
  
  % The smoothed estimate
  xsmooth(:,t)=Ftinv*(xsmooth(:,t+1)-G*St*(xsmooth(:,t+1)-xhat(:,t+1)));

  % Covariance update
  Psit=Ftinv*(eye(n)-G*St);
  Pit=Ftinv*G;
  
  % Update the covariance matrix
  Psmooth(:,:,t)=Psit*Psmooth(:,:,t+1)*Psit' + Pit*Mt*Pit';
end

if restart

  % To find initial state, first convert first frame data to tree
  % structure, then call the firststate function
  yres = y(:,restart);
  yres(find(yres==0)) = NaN;
  initp = vect2tree(yres, p0);
  x0r = firststate(tws, p0, initp);
  x0r = cat(1, x0r, zeros(size(x0r)));

  [y_test] = observe_mechanism_H(x0r, y(:,restart), tws, ...
				 p0);
  rmse = y_test - y(:,restart);
  rmse(find(y(:,restart)==0)) = [];
  
  % Restart the ekf
  disp(['Restarting the tracking filter at frame ', ...
	int2str(restart)])

  clear xhat Phat
  
  [xsmooth_rest, Psmooth_rest] = ekf_mechanism_fixint(y(:,restart:end), ...
						  x0r, P0, R1, R2, ...
						  dt, tws, p0, ...
						  rmse);
  
  xsmooth = cat(2, xsmooth, xsmooth_rest);  
  Psmooth = cat(3, Psmooth, Psmooth_rest);
end
