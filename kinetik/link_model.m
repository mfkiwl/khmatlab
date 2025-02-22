function [rm, links] = link_model(lengths, masses, origin, g0_end, object_frame)
%% Returns a model of a manipulator with 3dof joints links of lengths and masses given
%% The three rotations of each joint are z-y-x.
%% Based on planar_link_model.m


%% Kjartan Halvorsen
%% 2013-07-17

if nargin == 0
   %% Default: Three link model with unit length and unit mass
   l1 = 1; l2 = 1; l3 = 1;
   m1 = 1; m2 = 1; m3 = 1;
   origin = [0;0;0];
   R = expm(hat(randn(3,1)));
   g0_end = [R [l1+l2+l3;0;0]
	     0 0 0 1];
   object_frame = [R [l1+l2+l3;0;0]
		   0 0 0 1];

   rm = link_model([l1;l2;l3], [m1;m2;m3], origin, g0_end, object_frame);
   return
end

if nargin < 3
   origin = [0;0;0];
end

if nargin < 4
   g0_end = eye(4);
end

if nargin < 5
   object_frame = eye(4);
end

if isempty(origin)
   %% positions of the joints are given instead of lengths
   pos = lengths;
else
    nlinks = length(lengths);
    pos = zeros(3, nsegms+1);
    pos(:,1) = origin;
    for i=2:nsegms+1
	pos(:,i) = pos(:,i-1) + lengths(i-1)*[1;0;0];
    end
end

Z3 = zeros(3,3);
I3 = eye(3);

nlinks = size(pos,2)-1;
links = cell(nlinks,1);

for i = 1:nlinks
  mi = masses(i);
  li = norm(pos(:,i+1) - pos(:,i));
  links{i}.name = 'link1';
  links{i}.localframe = [I3, pos(:,i)
			 zeros(1,3), 1];
  links{i}.dof = {[3 2 1],[]};
  links{i}.states = {sprintf('th%dz', i), pi
		    sprintf('th%dy', i), pi
		    sprintf('th%dx', i), pi};
  links{i}.CoM = 0.5*pos(:,i) + 0.5*pos(:,i+1);
  ex = pos(:,i+1) - pos(:,i);
  ez = [0;0;1];
  ey = cross(ez, ex);

  links{i}.g0 = [ex ey ez links{i}.CoM
		 zeros(1,3), 1];
  links{i}.mass = mi;
  links{i}.moment_of_inertia = mi * diag( [0; li^2/12; li^2/12] );
  links{i}.generalized_inertia = [mi*I3, Z3
				  Z3, links{i}.moment_of_inertia];
end

%links{end}.dof = {[1 2 3],[]};
%links{end}.states = {'e1', pi
%		    'e2', pi
%		    'e3', pi};
links{end}.g0 = g0_end;
links{end}.object_frame = object_frame;

[tws, p0, gcnames, jc, segmnames, CoM, radius, mass, g0, inertia, obj_frame] = build_model(links{:});

rm.twists = tws;
rm.p0 = p0;
rm.jcs = jc;
rm.gcnames = gcnames;
rm.segm_names = segmnames;
rm.CoM = CoM;

rm.g0 = g0;
rm.inertia = inertia;
rm.mass = mass;
rm.object_frame = obj_frame;
