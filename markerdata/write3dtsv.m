function  ok=write3dtsv(varargin)
%  ok=write3dtsv(attr,mdata,fid)
% Saves marker data to a tsv file.

% Kjartan Halvorsen
% 2000-12-15

% Revisions
% 2001-07-26	Complete new version based on tsvppcode/tsvfilewrite
% 2001-09-05    With only two input argument, the first is assumed to be
%		marker data, and a bare file is written (no header).


if (nargin==3)
% Write the header part of the tsv file.
attr=varargin{1};
mdata=varargin{2};
fid=varargin{3};

k=keys(attr);
for at=1:length(k)
   fprintf(fid,'%s\t',k{at});

   val=getvalue(attr,k{at});
   if (ischar(val))
      fprintf(fid,'%s\n',val);
   elseif (iscell(val))
      vl=length(val);
      for m=1:vl-1
         if(ischar(val{m}))
            fprintf(fid,'%s\t',val{m});
         else
            fprintf(fid,'%f\t',val{m});
         end
      end
      if(ischar(val{vl}))
         fprintf(fid,'%s\n',val{vl});
      else
         fprintf(fid,'%f\n',val{vl});
      end
   else
      fprintf(fid,'%f\n',val);
   end      
end

else

   mdata=varargin{1};
   fid=varargin{2};

end

% write the data part
  [m,n]=size(mdata);
  format='';
  for col=1:n-1
    format=[format,'%f\t'];
  end
  format=[format,'%f\n'];

ok =  fprintf(fid,format,mdata');











