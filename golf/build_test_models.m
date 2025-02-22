function [gmleftclub, gmrightclub, gmbothleft, gmbothright] = build_test_models(refdata, trialdata, bodymass)
%  [gmleftclub, gmrightclub, gmbothleft, gmbothright] = build_test_models(refdata, trialdata, bodymass)
%
% Returns kinematic models to test mobility calculations
%   gmleft     <-  Consists of the left hand with club rigidly attached to hand.
%   gmright    <-  Consists of the right hand with club rigidly attached to hand.
%   gmbothleft  <-  Club rigidly attached to left hand. Right hand has endpoint at clubhead
%   gmbothright  <-  Club rigidly attached to right hand. Left hand has endpoint at clubhead
%
% Note that the grip is assumed to be firm, so that the club and hand(s) form one segment.
% In other words: no degrees of freedom between the hands and club.
%
% Input
%    refata    ->  Reference marker data. Must be struct exported
%                  from visual3D
%    trialdata ->  marker data from a swing trial. The start of the
%                  file should correspond to address position. Most
%                  importantly, that the grip is the same as the
%                  one used througout the swing.Must be struct exported
%                  from visual3D
%    bodymass  ->  Total mass of the subject
% Output
%    gm{left,right,both}  <-  struct. Contains the fields 
%        tws       <-  nested cell array of twists
%        gcnames   <-  array with names for the generalized
%                      coordinates.
%        p0        <-  nested cell array with reference marker positions.
%        jcs       <-  nested cell array with joint centra 
%        CoM       <-  nested cell array with center of mass 
%        inertia   <-  nested cell array with inertial matrices (6 x 6)
%        g0        <-  nested cell array with local coordinate frames (6 x 6)
%        object_frame  <-  nested cell array with local object frames (6 x 6). 
%                          Typically only given for the end segment.

% Kjartan Halvorsen
% 2013-08-23
% Based on build_golf_model_w_inertia
  
% Find suitable frame to use as address position

club_1_tr = extractmarkers(trialdata, 'ClubCoM');
[impact, impact_fit, pquad, dist2address, max_before_backsw] ...
= find_impact_from_point(club_1_tr);

trialdata{2} = trialdata{2}(max_before_backsw:max_before_backsw+1,:);
refdata = trialdata;

c7 = mmyextractmeanmarkers(refdata, 'C7');
ij = mmyextractmeanmarkers(refdata, 'Insicura Jugularis');
shoulder_l = mmyextractmeanmarkers(refdata, 'L Acromion');
shoulder_r = mmyextractmeanmarkers(refdata, 'R Acromion');
ghjc_l = mmyextractmeanmarkers(refdata, 'Wrt_LShoulder');
ghjc_r = mmyextractmeanmarkers(refdata, 'Wrt_RShoulder');
elbow_lat_l = mmyextractmeanmarkers(refdata, 'L Elbow lateral');
elbow_med_l = mmyextractmeanmarkers(refdata, 'L Elbow medial');
elbow_lat_r = mmyextractmeanmarkers(refdata, 'R Elbow lateral');
elbow_med_r = mmyextractmeanmarkers(refdata, 'R Elbow medial');
wrist_radial_l = mmyextractmeanmarkers(refdata, 'L Radial wrist');
wrist_ulnar_l = mmyextractmeanmarkers(refdata, 'L Ulnar wrist');
wrist_radial_r = mmyextractmeanmarkers(refdata, 'R Radial wrist');
wrist_ulnar_r = mmyextractmeanmarkers(refdata, 'R Ulnar wrist');
asis_l = mmyextractmeanmarkers(refdata, 'L ASIS');
asis_r = mmyextractmeanmarkers(refdata, 'R ASIS');
psis_l = mmyextractmeanmarkers(refdata, 'L PSIS');
psis_r = mmyextractmeanmarkers(refdata, 'R PSIS');
t8 = mmyextractmeanmarkers(refdata, 'T8');
pelvis_1 = mmyextractmeanmarkers(refdata, 'PELVIS_1');
pelvis_2 = mmyextractmeanmarkers(refdata, 'PELVIS_2');
pelvis_3 = mmyextractmeanmarkers(refdata, 'PELVIS_3');
ut_1 = mmyextractmeanmarkers(refdata, 'UPPER_TORSO_1');
ut_2 = mmyextractmeanmarkers(refdata, 'UPPER_TORSO_2');
ut_3 = mmyextractmeanmarkers(refdata, 'UPPER_TORSO_3');
uarm_1_l = mmyextractmeanmarkers(refdata, 'L_UPPER_ARM_1');
uarm_2_l = mmyextractmeanmarkers(refdata, 'L_UPPER_ARM_2');
uarm_3_l = mmyextractmeanmarkers(refdata, 'L_UPPER_ARM_3');
uarm_1_r = mmyextractmeanmarkers(refdata, 'R_UPPER_ARM_1');
uarm_2_r = mmyextractmeanmarkers(refdata, 'R_UPPER_ARM_2');
uarm_3_r = mmyextractmeanmarkers(refdata, 'R_UPPER_ARM_3');
hand_1_l = mmyextractmeanmarkers(refdata, 'L_HAND_1');
hand_2_l = mmyextractmeanmarkers(refdata, 'L_HAND_2');
hand_3_l = mmyextractmeanmarkers(refdata, 'L_HAND_3');
hand_1_r = mmyextractmeanmarkers(refdata, 'R_HAND_1');
hand_2_r = mmyextractmeanmarkers(refdata, 'R_HAND_2');
hand_3_r = mmyextractmeanmarkers(refdata, 'R_HAND_3');
hand_1_l_trial = mmyextractmeanmarkers(trialdata, 'L_HAND_1');
hand_2_l_trial = mmyextractmeanmarkers(trialdata, 'L_HAND_2');
hand_3_l_trial = mmyextractmeanmarkers(trialdata, 'L_HAND_3');
hand_1_r_trial = mmyextractmeanmarkers(trialdata, 'R_HAND_1');
hand_2_r_trial = mmyextractmeanmarkers(trialdata, 'R_HAND_2');
hand_3_r_trial = mmyextractmeanmarkers(trialdata, 'R_HAND_3');
mp_2_l = mmyextractmeanmarkers(refdata, 'L 2nd MP joint');
mp_5_l = mmyextractmeanmarkers(refdata, 'L 5th MP joint');
mp_2_r = mmyextractmeanmarkers(refdata, 'R 2nd MP joint');
mp_5_r = mmyextractmeanmarkers(refdata, 'R 5th MP joint');
grip_top = mmyextractmeanmarkers(refdata, 'Top of handle');
heel_bottom_grove = mmyextractmeanmarkers(refdata, 'Bottom grove@heel');
toe_bottom_grove = mmyextractmeanmarkers(refdata, 'Bottom grove@toe');
toe_top_grove = mmyextractmeanmarkers(refdata, 'Top grove@toe');
club_1 = mmyextractmeanmarkers(refdata, 'Club_1');
club_2 = mmyextractmeanmarkers(refdata, 'Club_2');
club_3 = mmyextractmeanmarkers(refdata, 'Club_3');
club_1_trial = mmyextractmeanmarkers(trialdata, 'CLUB_1');
club_2_trial = mmyextractmeanmarkers(trialdata, 'CLUB_2');
club_3_trial = mmyextractmeanmarkers(trialdata, 'CLUB_3');
%midhands_1 = mmyextractmeanmarkers(refdata, 'MidHands_1');
%midhands_2 = mmyextractmeanmarkers(refdata, 'MidHands_2');

		       
% Landmarks and anatomical directions
midtrunk = mean(cat(2, shoulder_l,shoulder_r, ...
		    c7, ij), 2);
midpelvis = mean(cat(2, asis_l, asis_r, psis_r, psis_l), 2); 

e_IS = midtrunk - midpelvis; % Inferior-superior direction 
e_IS = e_IS / norm(e_IS);
e_LR = shoulder_r - shoulder_l; % Left-right, local X
e_LR = e_LR - (e_LR'*e_IS)*e_IS;
e_LR = e_LR/norm(e_LR);
e_PA = cross(e_IS, e_LR); % Posterior-anterior, local Y.


% Elbow joint centers
ejc_l = 0.5*elbow_lat_l + 0.5*elbow_med_l;
ejc_r = 0.5*elbow_lat_r + 0.5*elbow_med_r;

% wrist joint centers
wjc_l = 0.5*wrist_radial_l + 0.5*wrist_ulnar_l;
wjc_r = 0.5*wrist_radial_r + 0.5*wrist_ulnar_r;


%----------------------------------------------------------------
% Define the segments
%----------------------------------------------------------------

% The left arm 
% Hand
mid_mp_l = 0.5*mp_5_l + 0.5*mp_2_l;

e_z = mid_mp_l - wjc_l;
e_z = e_z / norm(e_z);
e_x = mp_2_l - mp_5_l; % Local x-axis pointing left-right given by
                       % MP markers
e_x = e_x / norm(e_x);
% For the hand, adjust z-direction, not x-axis.
e_z = e_z - (e_z'*e_x)*e_x; 
e_z = e_z / norm(e_z);

e_y = cross(e_z, e_x);

lhand.name = 'left_hand';
lhand.localframe = cat(1, cat(2, e_x, e_y, e_z, wjc_l),...
		      [0 0 0 1]);
lhand.dof = {[1 2 3], [1 2 3]};
lhand.states = {'left wrist x', 1.0
		'left wrist y', 1.0
		'left wrist z', 1.0
		'left wrist flexion', 0.9170
	      'left wrist abduction', 0.5507
	      'left wrist rotation', 0.5507};
lhand.markers = {'L_Hand_1', hand_1_l
		 'L_Hand_2', hand_2_l
		 'L_Hand_3', hand_3_l
		 'R_Hand_1', hand_1_r
		 'R_Hand_2', hand_2_r
		 'R_Hand_3', hand_3_r
		 'CLUB_1', club_1
		 'CLUB_2', club_2
		 'CLUB_3', club_3};
%% Data from de Leva
lhand.length = norm(mid_mp_l - wjc_l);
lhand.mass = 0.0061*bodymass;
lhand.CoM = wjc_l + 0.79*lhand.length*e_z;
lhand.g0 = cat(1, cat(2, e_x, e_y, e_z, lhand.CoM), [0 0 0 1]);
lhand.moment_of_inertia = lhand.mass ...
			   * diag( (lhand.length*[0.628 0.513 0.40]).^2 );
lhand.generalized_inertia = [lhand.mass*eye(3) zeros(3,3)
			      zeros(3,3)  lhand.moment_of_inertia];

% Object frame is club frame
e_z = grip_top - heel_bottom_grove;
e_z = e_z / norm(e_z);
e_y = toe_bottom_grove - heel_bottom_grove;
e_y = e_y - (e_y'*e_z)*e_z; 
e_y = e_y / norm(e_y);
e_x = cross(e_y, e_z);

club_head_center =0.5*heel_bottom_grove + 0.5*toe_top_grove; 
% This point is used to compute the velocity of the club head
club.g0 = cat(1, cat(2, e_x, e_y, e_z, club_head_center),...
			[0 0 0 1]);
lhand.object_frame = club.g0;

%% Left hand+club
[club.mass, club.CoM, club.local_inertia, club.inertia] = ...
    get_club_model(grip_top, ...
		  toe_top_grove, ...
		  toe_bottom_grove,...
		  heel_bottom_grove);

lhandclub = lhand;
lhand_inertia_labframe = lhand.g0(1:3, 1:3)*lhand.moment_of_inertia*lhand.g0(1:3,1:3)'; 

[lhandclub.moment_of_inertia, lhandclub.CoM, lhandclub.mass] = combine_inertia(lhand_inertia_labframe, lhand.CoM, lhand.mass, club.inertia, club.CoM, club.mass);

%% Rotate moment of inertia matrix back to local coordinate system of club.
lhandclub.g0 = cat(1, cat(2, club.g0(1:3, 1:3), lhandclub.CoM), ...
		   [0 0 0 1]);
lhandclub.moment_of_inertia = lhandclub.g0(1:3, 1:3)'*lhandclub.moment_of_inertia ...
			      *lhandclub.g0(1:3,1:3); 
lhandclub.generalized_inertia = [lhandclub.mass*eye(3) zeros(3,3)
			      zeros(3,3)  lhandclub.moment_of_inertia];

rhandclub.localframe = cat(1, cat(2, club.g0(1:3, 1:3), wjc_l), ...
		   [0 0 0 1]);


% The right arm 
% Hand
mid_mp_r = 0.5*mp_5_r + 0.5*mp_2_r;

e_z = mid_mp_r - wjc_r;
e_z = e_z / norm(e_z);
e_x = mp_5_r - mp_2_r; % Local x-axis pointing left-right given by
                       % MP markers
e_x = e_x / norm(e_x);
% For the hand, adjust z-direction, not x-axis.
e_z = e_z - (e_z'*e_x)*e_x; 
e_z = e_z / norm(e_z);

e_y = cross(e_z, e_x);

rhand.name = 'right_hand';
rhand.localframe = cat(1, cat(2, e_x, e_y, e_z, wjc_r),...
		      [0 0 0 1]);
%%rhand.localframe = lhand.localframe;
rhand.dof = {[1 2 3], [1 2 3]};
rhand.states = {'right wrist x', 1.0
		'right wrist y', 1.0
		'right wrist z', 1.0
		'right wrist flexion', 0.9170
	      'right wrist abduction', 0.5507
	      'right wrist rotation', 0.5507};
rhand.markers = {'R_Hand_1', hand_1_r
		 'R_Hand_2', hand_2_r
		 'R_Hand_3', hand_3_r
		 'L_Hand_1', hand_1_l
		 'L_Hand_2', hand_2_l
		 'L_Hand_3', hand_3_l
		 'CLUB_1', club_1
		 'CLUB_2', club_2
		 'CLUB_3', club_3};
%% Data from de Leva
rhand.length = norm(mid_mp_r - wjc_r);
rhand.mass = 0.0061*bodymass;
rhand.CoM = wjc_r + 0.79*rhand.length*e_z;
rhand.g0 = cat(1, cat(2, e_x, e_y, e_z, rhand.CoM), [0 0 0 1]);
rhand.moment_of_inertia = rhand.mass ...
			   * diag( (rhand.length*[0.628 0.513 0.40]).^2 );
rhand.generalized_inertia = [rhand.mass*eye(3) zeros(3,3)
			      zeros(3,3)  rhand.moment_of_inertia];

% Object frame is right club frame
rhand.object_frame = club.g0;

rhandclub = rhand;
rhand_inertia_labframe = rhand.g0(1:3, 1:3)*rhand.moment_of_inertia*rhand.g0(1:3,1:3)'; 
[rhandclub.moment_of_inertia, rhandclub.CoM, rhandclub.mass] = combine_inertia(rhand_inertia_labframe, rhand.CoM, rhand.mass, club.inertia, club.CoM, club.mass);

%% Rotate moment of inertia matrix back to local coordinate system of club.
rhandclub.g0 = cat(1, cat(2, club.g0(1:3, 1:3), rhandclub.CoM), ...
		   [0 0 0 1]);
rhandclub.moment_of_inertia = rhandclub.g0(1:3, 1:3)'*rhandclub.moment_of_inertia ...
			      *rhandclub.g0(1:3,1:3); 
rhandclub.generalized_inertia = [rhandclub.mass*eye(3) zeros(3,3)
			      zeros(3,3)  rhandclub.moment_of_inertia];
 
rhandclub.localframe = cat(1, cat(2, club.g0(1:3, 1:3), wjc_r), ...
		   [0 0 0 1]);
rhand.localframe = cat(1, cat(2, club.g0(1:3, 1:3), wjc_r), ...
		   [0 0 0 1]);

%%keyboard
endpointstr = 'ClubCoM';


%%%%%%%%%%%%%%%%%%%%%
% Need also a dummy trunk segment to act as root
%%%%%%%%%%%%%%%%%%%%%

trunk.CoM = zeros(3,1);
trunk.mass = 0;
trunk.localframe = eye(4);
trunk.dof = {[], []};
trunk.states = {};
trunk.moment_of_inertia = zeros(3,3);
trunk.generalized_inertia = zeros(6,6);
trunk.g0 = eye(4);


%----------------------------------------------------------------
% Define the complete models
%----------------------------------------------------------------

[gmbothleft.twists, gmbothleft.p0, gmbothleft.gcnames, gmbothleft.jcs, gmbothleft.segm_names, gmbothleft.CoM, radius, gmbothleft.mass, gmbothleft.g0, gmbothleft.inertia, gmbothleft.object_frame, gmbothleft.objectcenter] = build_model(trunk);
gmbothright = gmbothleft;

[gmleftclub.twists, gmleftclub.p0, gmleftclub.gcnames, gmleftclub.jcs, gmleftclub.segm_names, gmleftclub.CoM, ...
 radius_la, gmleftclub.mass, gmleftclub.g0, gmleftclub.inertia, gmleftclub.object_frame, gmleftclub.objectcenter] =  build_model(lhandclub);

[gmleft.twists, gmleft.p0, gmleft.gcnames, gmleft.jcs, gmleft.segm_names, gmleft.CoM, ...
 radius_la, gmleft.mass, gmleft.g0, gmleft.inertia, gmleft.object_frame, gmleft.objectcenter] =  build_model(lhand);

[gmrightclub.twists, gmrightclub.p0, gmrightclub.gcnames, gmrightclub.jcs, gmrightclub.segm_names, gmrightclub.CoM, ...
 radius_la, gmrightclub.mass, gmrightclub.g0, gmrightclub.inertia, gmrightclub.object_frame, gmrightclub.objectcenter] =  build_model(rhandclub);

[gmright.twists, gmright.p0, gmright.gcnames, gmright.jcs, gmright.segm_names, gmright.CoM, ...
 radius_la, gmright.mass, gmright.g0, gmright.inertia, gmright.object_frame, gmright.objectcenter] =  build_model(rhand);

gmbothleft.twists{2} = gmleftclub.twists;
gmbothleft.twists{3} = gmright.twists;
gmbothleft.p0{2} = gmleftclub.p0;
gmbothleft.p0{3} = gmright.p0;
gmbothleft.jcs{2} = gmleftclub.jcs;
gmbothleft.jcs{3} = gmright.jcs;
gmbothleft.CoM{2} = gmleftclub.CoM;
gmbothleft.CoM{3} = gmright.CoM;
gmbothleft.g0{2} = gmleftclub.g0;
gmbothleft.g0{3} = gmright.g0;
gmbothleft.inertia{2} = gmleftclub.inertia;
gmbothleft.inertia{3} = gmright.inertia;
gmbothleft.object_frame{2} = gmleftclub.object_frame;
gmbothleft.object_frame{3} = gmright.object_frame;
gmbothleft.objectcenter{2} = gmleftclub.objectcenter;
gmbothleft.objectcenter{3} = gmright.objectcenter;
gmbothleft.gcnames = cat(1, gmbothleft.gcnames, gmleftclub.gcnames, gmright.gcnames);
gmbothleft.segm_names = cat(1, gmbothleft.segm_names, gmleftclub.segm_names, gmright.segm_names);

gmbothright.twists{2} = gmleft.twists;
gmbothright.twists{3} = gmrightclub.twists;
gmbothright.p0{2} = gmleft.p0;
gmbothright.p0{3} = gmrightclub.p0;
gmbothright.jcs{2} = gmleft.jcs;
gmbothright.jcs{3} = gmrightclub.jcs;
gmbothright.CoM{2} = gmleft.CoM;
gmbothright.CoM{3} = gmrightclub.CoM;
gmbothright.g0{2} = gmleft.g0;
gmbothright.g0{3} = gmrightclub.g0;
gmbothright.inertia{2} = gmleft.inertia;
gmbothright.inertia{3} = gmrightclub.inertia;
gmbothright.object_frame{2} = gmleft.object_frame;
gmbothright.object_frame{3} = gmrightclub.object_frame;
gmbothright.objectcenter{2} = gmleft.objectcenter;
gmbothright.objectcenter{3} = gmrightclub.objectcenter;
gmbothright.gcnames = cat(1, gmbothright.gcnames, gmleft.gcnames, gmrightclub.gcnames);
gmbothright.segm_names = cat(1, gmbothright.segm_names, gmleft.segm_names, gmrightclub.segm_names);

function m = mmyextractmeanmarkers(rd, mname)
% Will look in struct rd for marker (or landmark) of name
% mname. Returns the average position in a 3x1 column vector, or
% NaNs if not found.

m = nan(3,1);

if isstruct(rd)
  
  if isfield(rd,mname)
    md = getfield(rd,mname);
    
    m = (mean(md{1}(:,1:3),1))';
  end

else
  mm = extractmarkers(rd,mname);
  m = mm(1,1:3)';
end
