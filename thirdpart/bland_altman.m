%  [data_mean,data_diff,md,sd] = bland_altman(data1,data2)
%
% Function to generate Bland Altman plots. Barry Greene, September 2008
% Bland, J.M., Altman, D.G. 'Statistical methods for assessing agreement ...
% between two methods of clinical measurement'(1986) Lancet, 1 (8476), pp. 307-310.
% Inputs: data1: Data from first instrument
%         data2: Data from second instument  
% Produces Bland Altman plot with mean difference and mean difference +/-
% 2*SD difference lines.

function [data_mean,data_diff,md,sd] = bland_altman(data1,data2, xlbl, ...
						  ylbl, titl)

if (nargin < 5)
  titl = '';
end
if (nargin < 4)
  ylbl = 'Difference between two measures';
end
if (nargin < 3)
  xlbl = 'Mean of two measures';
end

[m,n] = size(data1);
if(n>m)
    data1 = data1';
    data2 = data2';
end

if(size(data1)~=size(data2))
    error('Data matrices must be the same size')
end

data_mean = mean([data1,data2],2);  % Mean of values from each instrument 
data_diff = data1 - data2;              % Difference between data from each instrument
md = mean(data_diff(find(~isnan(data_diff))));               % Mean of difference between instruments 
sd = std(data_diff(find(~isnan(data_diff))));                % Std dev of difference between instruments 

clf
plot(data_mean,data_diff,'k.','MarkerSize',8)   % Bland Altman plot
hold on
xl = get(gca, 'XLim');
plot(xl,[md md],'k', 'LineWidth', 2)             % Mean difference line  
plot(xl, [md+2*sd md+2*sd],'k', 'LineWidth', 2)                   % Mean plus 2*SD line  
plot(xl, [md-2*sd md-2*sd],'k', 'LineWidth', 2)                   % Mean plus 2*SD line  

%grid on
title(titl,'FontSize',9)
xlabel(xlbl,'FontSize',12)
ylabel(ylbl,'FontSize',12)
box off
%axis equal