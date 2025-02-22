function [nallmarkers, npg, nci, nresids] = setc3dmarkers(newmarkers, ...
						  allmarkers, pg, ...
						  names, ci, resids)
%  [nallmarkers, npg] = setc3dmarkers(newmarkers, allmarkers, pg, names)
% Sets the trajectories for the marker names provided.
%
% Input
%   newmarkers      ->  marker data to add. (nfrs x 3 nnmarks) or
%                       (nfrs x nnmarks x 3)
%   allmarkers      ->  marker data as returned by readC3D (nfrs x
%                       nmarkers x 3)
%   pg              ->  parameter group
%   names           ->  cell array of names. If doesn't exist in
%                       data, then add 
% Output
%   nallmarkers     <-  new set of markers
%   npg             <-  new parameter group

% Kjartan Halvorsen
% 2005-03-06

names{:}
if length(names)>1
  for i=1:length(names)
    [nallmarkers, npg, nci, nresids] = ...
	setc3dmarkers(newmarkers(:,(i-1)*3+1:i*3),...
		      allmarkers, pg, names(i), ci, resids);
    allmarkers = nallmarkers;
    pg = npg;
    ci = nci;
    resids = nresids;
  end
else
  
  labels = getc3dparam(pg, 'POINT', 'LABELS');

  [slask, distind, nameind] = intersect(labels.data, names);

  if (size(newmarkers, 3) == 1)
    newmarkers = permute(reshape(newmarkers, ...
				 [size(newmarkers,1) 3 1]),...
			 [1 3 2]);
  end

  npg = pg;
  
  if isempty(slask)
    try
    disp(['Adding marker ', names{1}])
    % Add the marker
    nallmarkers = cat(2, allmarkers, newmarkers);
  
    % Set parametergroup
    param = getc3dparam(npg, 'POINT', 'USED');
    param.data = param.data + 1;
    npg = setc3dparam(npg, 'POINT', param);
  
    param = getc3dparam(npg, 'POINT', 'LABELS');
    param.data = cat(2, param.data, names);
    param.dim = [param.dim(1) param.dim(2)+1];
    npg = setc3dparam(npg, 'POINT', param);
    catch
      keyboard
    end
    
    try
      param = getc3dparam(npg, 'POINT', 'DESCRIPTIONS');
      param.data = cat(2, param.data, names);
      param.dim = [param.dim(1) param.dim(2)+length(names)];
      npg = setc3dparam(npg, 'POINT', param);
    catch 
    end
    
    nci = cat(2, ci, ci(:,1));
    nresids = cat(2, resids, resids(:,1));
    
  else
    
    disp(['Changing position for marker ', names{1}])
    % Note that the indices are sorted. Fix this
    [slask, sortind] = sort(nameind);
    distind = distind(sortind);
    
    [nfrs, nmarkers, tre] = size(newmarkers);
    
    nallmarkers = allmarkers;
  
    for i=1:length(distind)
      nallmarkers(:,distind(i),:) = newmarkers(:,i,:);
    end
  
    nci =ci;
    nci(:,distind(i)) = nci(:,1);
    nresids = resids;
    nresids(:,distind(i)) = nresids(:,1);
    
  end
end
