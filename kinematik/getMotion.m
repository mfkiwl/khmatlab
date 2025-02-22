function [T, resid, nonmissing]=getMotion(varargin)
% Computes rigid body motion. Usage:
% [T, resid, nonmissing]=getMotion(P1,[P2]) 
%  or
% [T, resid, nonmissing]=getMotion(mdata, segmentmarkers) 
%  or
% [T, resid, nonmissing]=getMotion(mdata, fixedsegmmarkers, ...
%                                  movingsegmmarkers) 
% or
% [T, resid, nonmissing]=getMotion(refdata, mdata, segmentmarkers) 
%  or
% [T, resid, nonmissing]=getMotion(refdata, mdata, movingsegmmarkers, ...
%                                  fixedsegmmarkers) 
%
% Returns a matrix T where the rows contain the 16
% elements of the 4 x 4 rigid body transformation.
% If P2 is emptym then the transformation is with respect to the
% first row of P1. Otherwise the motion is between corresponding
% rows of P1 and P2.
%
% Calls the function SODER, which is an implementation by Christoph 
% Reinschmidt of the algortihm propsed by Söderkvist and Wedin.
%
% Input
%    P1         ->    (m x n) Marker coordinates. n>9. If n is not a
%                     multiple of 3 it is assumed that the first column
%                     contains fram labels.
%    P2         ->   (m x n) as P1
%    mdata      ->   {attr, markerdata}, tsv data.
%    refdata    ->   {attr, markerdata}, tsv data for reference position.
%    segmentmarkers -> cell array of strings with marker names.
%    fixedsegmmarkers -> cell array of strings with marker names.
%    movingsegmmarkers -> cell array of strings with marker names.
%
% Output
%    T     ->   (m x 16) or (m x 17) Each row contains the elements 
%               of a rigid body transformation matrix (4 x 4). The
%               (4 x 4) matrix can be retained by
%               TT=reshape(T(row,:),4,4). 
%    resid ->   Residuals
%    nonmissing ->  vector with indices to the frames with no
%                   missing data
%

% Kjartan Halvorsen

% Revisions
% 2004-01-27   Added different number of input arguments, and new
%              ways of calling the function using mdata structs:
%              {attr, markerdata}.

switch nargin
 case 1
  P1 = varargin{1};
  startfr = 1;
 case 2
  if ismarkerdata(varargin{1})
    P1 = extractmarkers(varargin{1}, varargin{2});
    startfr = 1;
  else
    P1 = varargin{1};
    P2 = varargin{2};
    startfr = 1;
  end
 case 3
  if (ismarkerdata(varargin{1}) & ismarkerdata(varargin{2}))
    P1ref = extractmeanmarkers(varargin{1}, varargin{3});
    P1 = cat(1, P1ref(:)', extractmarkers(varargin{2}, varargin{3}));
    startfr = 2;
  else
    P1 = extractmarkers(varargin{1}, varargin{2});
    P2 = extractmarkers(varargin{1}, varargin{3});
    P1 = getRelMotion(P1, P2);
    startfr = 1;
  end
 case 4
    P1ref = extractmeanmarkers(varargin{1}, varargin{3});
    P2ref = extractmeanmarkers(varargin{1}, varargin{4});
    P1 = cat(1, P1ref(:)', extractmarkers(varargin{2}, varargin{3}));
    P2 = cat(1, P2ref(:)', extractmarkers(varargin{2}, varargin{4}));
    P1 = getRelMotion(P1, P2);
    startfr = 2;
end

[m,n]=size(P1);

labels=mod(n,3); % Checks for frame labels

T=zeros(m,16+labels);
resid = zeros(m,1);
missing=[];

if (~exist('P2', 'var'))

  if (labels==1)
    T(:,1)=P1(:,1);
    PP=P1;
    PP(:,1)=[];
  else
    PP=P1;
    
  end
  
  for i=1:m
    [mssng, pp1] = haslessthan3(PP(i,:));
    if ~mssng
      P1=cat(1, PP(1,:), pp1);
      [T1,res]=soder(P1);
      T1=reshape(T1,1,16);
      T(i,(1+labels):(16+labels))=T1;
      resid(i)= mean(res);
    else
      missing = cat(2, missing, i);
    end
  end

else % P2 exists
  if (labels==1)
    T(:,1)=P1(:,1);
    PP1=P1;
    PP1(:,1)=[];
    PP2=P2;
    PP2(:,1)=[];
  else
    PP1=P1;
    PP2=P2;
  end
  
  for i=1:m
    [mssng1, pp1] = haslessthan3(PP1(i,:));
    [mssng2, pp2] = haslessthan3(PP2(i,:));
    if (~mssng1 & ~mssng2 )
      [T1,res]=soder([pp1;pp2]);
      T1=reshape(T1,1,16);
      T(i,(1+labels):(16+labels))=T1;
      resid(i)= mean(res);
    else
      missing = cat(2, missing, i);
    end
  end
end

T=T(startfr:end,:);
resid = resid(startfr:end);
nonmissing = setdiff(1:m, missing);
nonmissing = nonmissing(startfr:end) - startfr + 1;