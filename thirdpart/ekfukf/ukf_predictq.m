% Based on 
%UKF_PREDICT2  Augmented (state and process noise) UKF prediction step
%
% Syntax:
%   [M,P] = UKF_PREDICTQ(M,P,Q,dt)
%
% In:
%   M - 19x1 mean state estimate of previous step
%   P - 18x18 state covariance of previous step
%   Q - Non-singular 18x18 covariance of process noise w
%   dt - sampling time
%
% Out:
%   M - Updated state mean
%   P - Updated state covariance
%
% Description:
%   Perform Unscented Kalman Filter prediction step
%   for model with quaternion representation of rotation
%

% This software is distributed under the GNU General Public
% Licence (version 2 or later); please refer to the file
% Licence.txt, included with the software, for details.

function [M,P] = ukf_predictq(M,P,Q,dt)


  %% Create sigma points
  
  

  n = size(M,1);
  QP = P + Q;
  A = chol(QP)';
  [WM,WC,c] = ut_weights(size(M,1),alpha,beta,kappa);

  X = zeros(n, 2*n+1);
  AA = sqrt(c)*[A -A];
  MM = repmat(M,1,size(X,2));
  X(1:9,:) = MM(1:9,:) + cat(2, zeros(9,1), AA(1:9,:));
  X(10:13,2:end) = qpropagate(MM(10:13,2:end), AA(10:12,:), 1); 
  keyboard
  X(14:end, :) = MM(14:end,:) + cat(2, zeros(6,1), AA(13:end,:));

  %% Propagate sigma points
  XX = dynamics_rb(X,dt);

  %% Compute the mean
  mu = zeros(n,1);
  for i=1:size(XX,2)
    mu = mu + WM(i) * XX(:,i);
  end

  %% The quaternion part must be handled separately
  mu(10:13) = qmean(XX(10:13,:),WM);


  

