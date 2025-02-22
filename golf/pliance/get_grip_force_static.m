function [gripforce, gripcop, grippoints] = get_grip_force(plAscData)
  %% Comptutes the grip force and center of pressure in the local coordinate
  %% system of the grip. The origin is at the center of the grip at row 1 of the
  %% cells. The local x-axis points towards the midpoint of cell 11, and the
  %% local z-axis is along the axis of the grip.
  %%
  %% Input
  %%  plAscData       ->   name of ascii file with pliance data, or data already loaded
  %% Output
  %%  gripforce        <-   the grip force (3 x nfr)
  %%  gripcop          <-   the center of pressure (3 x nfr)
  %%  grippoints       <-   the position of the center of the cells (3 x 16*4)

  %% Kjartan Halvorsen
  %% 2012-12-04
  
  %% Modified by Fredrik Tinmark
  %% 2013

if (nargin == 0)
  do_unit_test()

else

  %% Load pliance data
  if ischar(plAscData)
    pd = openplianceasc_static(plAscData);
  else
    pd = plAscData;
  end

  nframes =size(pd{2}, 1);

  [plpoints, plnvectors, plnames, cellarea] = get_pliance_model_static();

  gripforce = zeros(3, nframes);
  gripcop = zeros(3,nframes);

  c1 = [0;0;0];
  c2 = [0;0; 226*1e-3];
  vvn = [0;0;1];
  P_v = eye(3) - vvn*vvn';
  
  for j = 1:nframes
    gripf = plnvectors * diag(pd{2}(j,2:65)) * ...
	cellarea * 1000 ; % in N. Pliance gives data in kPa
    gripforce(:,j) = sum(gripf, 2);
    
    gripmoments = cross(plpoints, gripf);
    gripmoment = sum(gripmoments, 2);
    F = gripforce(:,j);
    %% Determine the center of pressure as the being on the axis
    %% of the grip
    %% Need to scale the moment equation first
    Fn = norm(F);
    FM = [-hat(F/Fn); P_v];
    cop_st= FM \ [gripmoment/Fn; zeros(3,1)];
    gripcop(:,j) = cop_st;
  end

  %%keyboard

end

function do_unit_test()

  pld = 10*ones(10,65);

  [gripf, gripcop] = get_grip_force_static({[],pld});

  % Should be close to zero:
  gripf

  % Should be middle of the grip:
  gripcop

  f = 10;
  pld2 = zeros(10,65);
  pld2(:,2:17) = f;
  [gripf2, gripcop2] = get_grip_force_static({[],pld2});

  radius = 10*1e-3; % 10 mm
  circum = 2*pi*radius;
  length = 226*1e-3; % 226mm
  celllength = length/16;
  cellwidth = circum/4;
  cellarea = celllength*cellwidth;

  % Should be 
  F_exp = 16*cellarea*1000*f
  gripf2


  % Should be middle of the grip:
  CoP_exp = [0;0;226/2*1e-3]
  gripcop2

  
  keyboard