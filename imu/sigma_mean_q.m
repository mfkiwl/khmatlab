function [mu,S, EE,WW] = sigma_mean_q(XX, qi, Wm, Wc)
%%  [mu,Sx, EE] = sigma_mean_q(XX, qindstart, Wm, Wc)
%% Computes mean and covariance of sigma points for the system with quaternion representation
%% of rotation in elements qindstart:qindstart+3 of the state vector.
%%
%% Input
%%   XX           ->   Sigma points 
%%   qindstartx    ->  Row index into XX where quaternion starts. Could
%%                     be empty.
%%
%% Output
%%   mu     <-   The mean of the sigma points 
%%   Sx     <-   The covariance of the set XX 
%%   EE     <-   Error vectors form calculation of covariance of
%%               quaternion part

%% Revisions

%% Compute the mean

  n = size(XX,1);

  mu = zeros(n,1);
  for i=1:size(XX,2)
    mu = mu + Wm(i) * XX(:,i);
  end

  
  %% The quaternion part must be handled separately
  if (isempty(qi) == 0) % State vector has quaternion
    for j=1:length(qi)
      qii = qi(j);
      qe = qii+3;
    [mu(qii:qe), EE, its] = qmean(XX(qii:qe,:),Wm);
    %disp('its'), disp(its)
  else
    EE = [];
  end

  %% and the covariance
  if (isempty(qi) == 0) % State vector has quaternion
    WW = zeros(n-1, size(XX,2));
    S = zeros(n-1,n-1);
    for i=1:size(XX,2)
      W = cat( 1, XX(1:qi-1,i) - mu(1:qi-1), EE(:,i), XX(qe+1:end,i) - mu(qe+1:end) );
      S = S + Wc(i) * W * W';
      WW(:,i) = W;
    end
  else
    S = zeros(n,n);
    for i=1:size(XX,2)
      W = XX(:,i) - mu;
      S = S + Wc(i) * W * W';
    end
    end


