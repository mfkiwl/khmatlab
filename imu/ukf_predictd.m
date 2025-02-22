% Based on 
%UKF_PREDICT2  Augmented (state and process noise) UKF prediction step
%
% Syntax:
%   [M,P] = UKF_PREDICTQ(M,P,Q,dt,qindstart)
%
% In:
%   M - 19x1 mean state estimate of previous step
%   P - 18x18 state covariance of previous step
%   Q - Non-singular 18x18 covariance of process noise w
%   dt - sampling time
%%   qindstart      ->   Row index where quaternion starts. Empty matrix
%%   means no quaternion
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

function [XXm,Pk, EE] = ukf_predictd(M,P,Q,dt)


  %% Create sigma points
  n= size(P,1);
  [Wm,Wc,c] = ut_weights(n);

  X = sigmaq(P+Q,M,[]);

  %% Propagate sigma points
  %XX = dynamics_rb(X,dt,qi);
  XX = dynamics_d(X,dt);

  [XXm,Pk,EE] = sigmamean(XX,0,Wm,Wc);


  
  

  

