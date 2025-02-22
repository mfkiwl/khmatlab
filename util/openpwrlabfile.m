function [data, dt, filename, labels] = openpwrlabfile(varargin)
% Opens a file dialog, reads the content of the text file, assuming
% it is exported from power lab.
  
% Kjartan Halvorsen
% 2003-12-02
  
if nargin < 2
  if (nargin == 0)
    title = 'Pick a data file';
  else
    title = varargin{1};
  end

  [filename, pathname] = uigetfile('*.*', title);
  
  if (~filename) 
    data=[];
    dt = [];
    return; 
  end
else
  [pathname, filename, ext] =  fileparts(varargin{2});
  filename = strcat(filename, ext);
end

fid = fopen(fullfile(pathname, filename));

dt=[];
nheaderlines = 0;
skipcolumn1 = 0;
while 1
  headerline = fgetl(fid);
  
  [tok, rest] = strtok(headerline);
  if (strfind(tok, 'Interval')) % Sampling interval
    dt = str2num(strtok(rest));
  elseif (strfind(tok, 'ChannelTitle'))
      labels = split(rest);
  end
  
  if (strfind(tok, ':'))
    skipcolumn1 = 1; 
    % First column is time. Skip it.
    break
  elseif (~isnan(str2double(tok)))
    break
  else
    nheaderlines = nheaderlines + 1;
  end
end


fclose(fid);

data = dlmread( fullfile(pathname, filename), '\t', ...
		nheaderlines, skipcolumn1 );
data(:,end) = []; % Line ends with tab. dlmread reads this as a
                  % column with zeros at the end
		  
		  
