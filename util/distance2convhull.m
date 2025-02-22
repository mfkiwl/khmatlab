function [d, dxpos, dxneg, dypos, dyneg ,p1, p2, K] = distance2convhull(xy, ...
						  p, plotit, fighandle, paus)
%  [d, dxpos, dxneg, dypos, dyneg, p1, p2] = distance2convhull(xy,
%  p [, plotit, fighandle, paus])
% Computes the distance from a 2d point p to the edge of a convex hull of the
% points in the m x 2 matrix xy.
%
% Input
%    xy     ->   m x 2 matrix of points in the plane
%    p      ->   a 2d point
%    plotit ->   if 1, a 2d plot of the result is shown. The figure
%                window must be closed to continue execution.
%    fighandle ->   handle to a figure. if missing, a new figure
%                   is created
%    paus   ->   time to wait after drawing plot. Default is 0.01
% Output
%    d      <-   the closest distance from p to the edge of the
%                convex hull. Negative if p is outside the hull
%    dxpos  <-   the closest distance in positive x direction from
%                p to the edge of the 
%    dxneg  <-   the closest distance in negative x direction from
%                p to the edge of the 
%                convex hull. 
%    dypos  <-   the closest distance in positive y direction from
%                p to the edge of the 
%    dyneg  <-   the closest distance in negative y direction from
%                p to the edge of the 
%                convex hull. 
%    pi     <-   vertex points defining the line closest to p
  
% Kjartan Halvorsen
% 2006-11-27

if nargin > 0
  
  if nargin < 3
    plotit = 0;
  end
  
  if nargin < 5
    paus = 0.01;
  end
  
  % Indices of the extreme points. Runs counter-clockwise. First and
  % last index the same
  K = convhull(xy(:,1), xy(:,2));

  % unit vectors along the edges
  u = xy(K(2:end),:) - xy(K(1:end-1), :);
  
  d_magn = realmax;
  d_pos = 1;
  dxpos = realmax;
  dxneg = -realmax;

  dypos = realmax;
  dyneg = -realmax;

  p = [p(:)]';
  for i = 1:length(K)-1
    v = p - xy(K(i),:);
    ui = u(i,:) / norm(u(i,:));
    d = ui(1)*v(2) - ui(2)*v(1);
    if d<0  % point is outside hull
	    % check if angle between v and ui > pi/2. If so distance is
	    % distance to p1
	    vproj = v*ui';
	    if (vproj < 0)
	      di_magn = norm(v);
	      if (di_magn < d_magn)
		d_magn = di_magn;
		p1 = xy(K(i),:);
		p2 = xy(K(i+1),:);
	      end
	      d_pos = 0;
	    elseif (vproj < norm(u(i,:))) % Point is not off the next vertex
	      di_magn = abs(d);
	      if (di_magn < d_magn)
		d_magn = di_magn;
		p1 = xy(K(i),:);
		p2 = xy(K(i+1),:);
	      end
	      d_pos = 0;
	    end
    else % point is inside the hull
	 % check if angle between v and ui > pi/2. If so distance is
	 % distance to p1
	 vproj = v*ui';
	 if (vproj < 0)
	   di_magn = norm(v);
	 elseif (vproj > norm(u(i,:))) % Point is off the next
				       % vertex. Distance is
				       % distance to p2
					  
           di_magn = norm(p-xy(K(i+1),:));
	 else
	   di_magn = abs(d);
	 end
	 
	
	 if (di_magn < d_magn)
	   d_magn = di_magn;
	   p1 = xy(K(i),:);
	   p2 = xy(K(i+1),:);
	 end
	 d_pos = d_pos & 1;
    end % check of whether point is inside or outside hull
  
    % Compute distances in x and y direction
    [dxi, dyi, dxonedge, dyonedge] = xydistance2edge(p, xy(K(i),:), u(i,:));
    
    if ( dxonedge & (dxi > 0) )
      if (dxi < dxpos)  
	dxpos = dxi;
      end
    elseif (dxonedge & (dxi < 0))
      if (dxi > dxneg)
	dxneg = dxi;
      end
    end

    if ( dyonedge & (dyi > 0) )
      if (dyi < dypos ) 
	dypos = dyi;
      end
    elseif (dyonedge & (dyi < 0))
      if (dyi > dyneg)
	dyneg = dyi;
      end
    end
    
  end % for i = 1:length(K) -1 
  
  if d_pos
    d = d_magn;
  else
    d = -d_magn;
  end
  
  if plotit
    
    if ( (nargin < 4) | isempty(fighandle) )
      hfig = figure;
    else
      hfig = fighandle;
      figure(fighandle);
      cla
    end
    
  
    hplot = plot(xy(:,1), xy(:,2), 'bo');
    hold on
    plot(xy(K,1), xy(K,2), 'm');
    plot(p(1), p(2), 'r*');
    plot([p1(1) p2(1)], [p1(2) p2(2)], 'r');
  
    if (dypos < realmax) 
      str = sprintf('%2.2f', dypos);
      plot(p(1), p(2)+dypos, 'ro');
      hdypos = plot([p(1) p(1)], [p(2) p(2)+dypos], 'Color', [1 0 0]);
      text(p(1)+dypos/6, p(2)+dypos/2, str)
      disp(['dypos = ', str])
    end
    
    if (dyneg > -realmax) 
      str = sprintf('%2.2f', dyneg);
      plot(p(1), p(2)+dyneg, 'ro');
      hdyneg = plot([p(1) p(1)], [p(2) p(2)+dyneg], 'Color', [1 0 0]);
      text(p(1)+dyneg/6, p(2)+dyneg/2, str)
      disp(['dyneg = ', str])
    end
    
    if(dxpos < realmax)
      str = sprintf('%2.2f', dxpos);
      plot(p(1)+dxpos, p(2), 'ro');
      hdxpos = plot([p(1) p(1)+dxpos], [p(2) p(2)], 'Color', [1 0 0]);
      text(p(1)+dxpos/4, p(2)+dxpos/6, str)
      disp(['dxpos = ', str])
    end
    if(dxneg > -realmax)
      str = sprintf('%2.2f', dxneg);
      plot(p(1)+dxneg, p(2), 'ro');
      hdxneg = plot([p(1) p(1)+dxneg], [p(2) p(2)], 'Color', [1 0 0]);
      text(p(1)+3*dxneg/4, p(2)+dxneg/6, str)
      disp(['dxneg = ', str])
    end

  
    axis equal
    
    xlim = get(gca, 'XLim');
    ylim = get(gca, 'YLim');
    
    text(mean(xlim) - (xlim(2)-xlim(1))/4, mean(ylim), ...
	 ['Distance to edge: ', num2str(d)])
    
    drawnow
 
%    keyboard
    pause(paus);

    if(dxpos < realmax)
      delete(hdxpos);
    end
    if(dxneg > -realmax)
      delete(hdxneg);
    end
    if(dypos < realmax)
      delete(hdypos);
    end
    if(dyneg > -realmax)
      delete(hdyneg);
    end
    
  end % if plotit

else % Unit test
  
  % Generate test points in the plane
  figh = figure;
  plotit = 1;
  
  plot(1,1)
  axis equal
  xlabel('x')
  ylabel('y')
  hold on
  for i=1:10
    xy = rand(12,2);
    p = rand(1,2);

    [d, dxpos, dxneg, dypos, dyneg, p1, p2, K] = distance2convhull(xy,p, plotit, figh);

    keyboard
  end
end


function [tx, ty, txonedge, tyonedge] = xydistance2edge(p, q, u)
% Computes the distance (positive or negative) along the x and y
% directions from the  point p to the edge defined by the 
% point q and the vector u.
% txonedge will be 1 if the closest point is on the
% edge. Otherwise, txonedge is 0 and the returned distance is the
% distance (in the direction) to point p.

tol = 1e-10;

if (abs(u(2)) > tol)
  sx = (p(2) - q(2)) / u(2);
  tx = q(1) - p(1) + sx * u(1);

  if ( (sx >= 0) & (sx <= 1) )
    txonedge = 1;
  else
    txonedge = 0;
  end
else
  tx = 1e30;
  txonedge = 0;
end

if (abs(u(1)) > tol)
  sy = (p(1) - q(1)) / u(1);
  ty = q(2) - p(2) + sy * u(2);


  if ( (sy >= 0) & (sy <= 1) )
    tyonedge = 1;
  else
    tyonedge = 0;
  end
else
  ty = 1e30;
  tyonedge = 0;
end

