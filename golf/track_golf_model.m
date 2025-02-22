function [st,dataframes]=track_golf_model(varargin)
% function [st,dataframes]=...
%                         track_tennis_model(bm, mdata, bandwidth)
% Tracks the tennis model from marker data using an ekf.
%
% Input
%    bm        ->   model struct, containing fields 'tws', 'p0'
%                   and 'gcnames'.
%    mdata     ->   Cell array with marker data {attr, md} 
%    bandwidth ->   Filter tuning parameter
% Output
%    st        <-   a matrix where each column is a state vector.
%    dataframes<-   a binary vector of length equal to the number of
%                   frames. A 1 indicates that data exists.
%

% Kjartan Halvorsen
% 2003-08-04
%

bm=varargin{1};
mdata=varargin{2};

mnames = getvalue(mdata{1}, 'MARKER_NAMES');

if nargin==3 
   bandwidth=varargin{3};
else 
  bandwidth = 1;
end

% Prepare marker data.
% First fix specific issue with the golf data. In the reference file
[initnames, p0, p0vec] = prepare_mdata(bm.p0);
%size(initnames)
%size(p0vec)

%mnames=switchalias(mnames,alilist);
y_observations=extractmarkers(mdata{2}, mnames, initnames);

nfr=size(y_observations,1);

y0 = y_observations(1,:)';
y1 = y_observations(2,:)';
% Replace NaNs with zeros
%y_observations(find(y_observations==0)) = NaN;
y_observations(find(isnan(y_observations))) = 0;
y0(find(y0==0)) = NaN;
y1(find(y1==0)) = NaN;

% Remove frames at the beginning and end that only contains zeros
%[attr,y_observations,ind_removed,nmrks]=removeemptyframes({},y_observations);
y_observations=y_observations';
dataframes=ones(nfr,1);
%dataframes(ind_removed)=0;

% Enter keyboard mode for debugging
%keyboard

nfr=size(y_observations,2);

% The sampling time
freq=getvalue(mdata{1},'FREQUENCY');
if isstr(freq) freq=str2num(freq); end
if (isempty(freq))
  dt=1/240;
else
  dt=1/freq;
end

% Get filter parameters
% Ask the user to  choose the bandwidth of the tracking filter

%rrr = input('Enter filter parameter r: ');
rrr = bandwidth;
ra=1e4*rrr;
%ra=rrr;

%keyboard
R2=kron(diag(ones(length(initnames),1)), eye(3));
    
% The form of the process noise covariance is taken from Farina and 
% Studer "Radar data processing". It is the limit as dt*alpha goes
% to zero, or in plain words when the sampling time is much smaller
% than the time constant of the acceleration process.
nst=size(bm.gcnames,1);
ranges = values(bm.gcnames);
Ra=ra*diag(cat(1, ranges{:}));
R1=kron([dt^3/3 dt^2/2; dt^2/2 dt],Ra);

P0=kron(diag([1;10/dt]),eye(nst));

% To find initial state, first convert first frame data to tree
% structure, then call the firststate function
initp = vect2tree(y0, p0);
initp1 = vect2tree(y1, p0);
x0 = firststate(bm.twists, p0, initp);

%return

x1 = firststate(bm.twists, p0, initp1);

st = repmat(x0,1, nfr);


%x0(7:end) = 0;
%x0 = cat(1, x0, zeros(size(x0)));
x0 = cat(1, x0, (x1-x0)/dt);
% DEBUG
[y_test,Htest] = observe_mechanism_H(x0, y_observations(:,1), bm.twists, ...
			     p0);

rmse = y_test - y_observations(:,1);
rmse = sqrt(mean(rmse.*rmse));

%x0=zeros(nst*2,1);

% keyboard

%y_observations(:,1:10)
%p0

disp(['Tracking ', int2str(nst), ' degrees of freedom model ', ...
      'using trajectories of ', int2str(length(initnames)), ' markers...'])

padding=100;
y_observations = cat(2, repmat(y_observations(:,1),1, padding), ...
		     y_observations);
%[xhat,Phat]=ekf_mechanism_fixint(y_observations,x0,P0,R1,R2,...
%				 dt,bm.twists,p0, rmse);
[xhat,Phat]=ekf_mechanism_fixlag(y_observations,x0,P0,R1,R2,...
			          dt,bm.twists,p0,30);
   
%st=xhat(1:nst,padding+1:end);
st=xhat(:,padding+1:end);

