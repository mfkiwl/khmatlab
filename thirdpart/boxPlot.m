function [legh,xx] = boxPlot(data1, lineWidth, width, labels)
% boxPlot(data0) - plot box-whiskers diagram, accept multiple columns
% Arguments: data0 -  unsorted data, mxn, m samples, n columns
%            lineWidth -  line thickness in the plot default = 1;
%            width -  the width of the box, default = 1;
% Returns:	 
% Notes: each column is considered as a single set	

% Revisions
% 2008-10-07 Kjartan Halvorsen
% Changed to be able to work with severeal sets of data, grouping
% the box plots.

if (nargin < 4)
  labels = {};
end

if(nargin < 3)
        width = 1;
end;
if(nargin < 2)
  lineWidth = 1;
end;

plottypes = {'k^', 'ks', 'ko', 'k+'};
if (~iscell(data1))
  data1 = {data1};
  plottypes = {};
end

dl = length(data1);
dls = size(data1{1}, 2);

pad_s1 = 0.05;
boxwidth = 0.1;
pad_s2 = 1;

center = 0;
center_ticks = zeros(dl);

for i = 1:length(data1)
  center = center + pad_s2;
  center_ticks(i) = center;
  
  data0 = data1{i};
  
  
  [m n] = size(data0);
  
  q1 = zeros(1,n);
  q2 = zeros(1,n);
  q3 = zeros(1,n);
  mn = zeros(1,n);
  mx = zeros(1,n);
  minn = zeros(1,n);
  
  for col=1:n
    data = data0(:,col);
    data = data(find(data ~= 0)); % Remove zeros
    data = sort(data, 1); % ascend

    m = length(data);
    
    q2(col) = median(data, 1);
    mn(col) = mean(data,1);
    stdv(col) = std(data,1);
    mx(col) = data(end);
    minn(col) = data(1);
    
    if(rem(m,2) == 0)
      
      upperA = data(1:m/2);
      lowA =  data(m/2+1:end);
    
    else
      
      upperA = data(1:round(m/2));
      lowA =  data(round(m/2):end);  
      
    end
  
    q1(col) = median(upperA, 1);
    q3(col) = median(lowA, 1);
    
  end
  
  draw_data = [mx; q3; q2; q1; minn];
  %draw_data = [max_v; mn+2*stdv; mn; mn-2*stdv; min_v];
    
    % adjust the width
    [legh,xx] = drawBox(draw_data, lineWidth, boxwidth, center, pad_s1, plottypes);
    
end

if (~isempty(labels))
  set(gca, 'XTick', 1:length(data1))
  set(gca, 'XTickLabel', labels)
end

return;


function [legh,xx] =  drawBox(draw_data, lineWidth, width, center, padding, plottypes)

linecolor = [0 0 0];

n = size(draw_data, 2);
nhalv = (n-1)/2;


%    unit = (1-1/(1+n))/(1+9/(width+3));
unit = width/2;

totalwidth = n * width + (n-1) * padding;

x0 = center - totalwidth/2 + unit;
%    figure(figh);    
    hold on;       
    legh = zeros(n,1);
    xx = zeros(n,1);
    
    for i = 1:n
      x = x0 + (i-1) * (padding+width);
      xx(i) = x;
      v = draw_data(:,i);
      
      % draw the min line
      plot([x-unit, x+unit], [v(5), v(5)], 'LineWidth', lineWidth,...
	   'Color', linecolor);
      % draw the max line
      plot([x-unit, x+unit], [v(1), v(1)], 'LineWidth', lineWidth,...
	   'Color', linecolor);
      % draw middle line
      if (isempty(plottypes))
	plot([x-unit, x+unit], [v(3), v(3)], 'LineWidth', lineWidth,...
	     'Color', linecolor);
	else
	  if (strcmp(plottypes{i}, 'ko'))
	    legh(i) = plot([x], [v(3)], plottypes{i}, 'LineWidth', lineWidth,...
		 'Color', linecolor,'MarkerFaceColor', 'k',...
		 'MarkerEdgeColor', 'k'  );

	  else
	    legh(i) = plot([x], [v(3)], plottypes{i}, 'LineWidth', lineWidth,...
		 'Color', linecolor);
	    
	  end
	end
	  % draw vertical line
        plot([x, x], [v(5), v(4)], 'LineWidth', lineWidth,...
	     'Color', linecolor);
        plot([x, x], [v(2), v(1)], 'LineWidth', lineWidth,...
	     'Color', linecolor);
        % draw box
        plot([x-unit, x+unit, x+unit, x-unit, x-unit], [v(2), v(2), v(4), v(4), v(2)], 'LineWidth', lineWidth,...
	     'Color', linecolor);
        
    end;

return;