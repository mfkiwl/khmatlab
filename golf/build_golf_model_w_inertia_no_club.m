function [tm, endpointstr] = build_golf_model_w_inertia_no_club(refdata,trialdata, bodymass)
%  gm = build_golf_model_w_inertia_no_club(refdata, trialdata, bodymass)
%
% Returns a kinematic model for the golf study.
% The model contains the segments:
%    pelvis, trunk, upperarms, underarms, hands
% The pelvis is the root segment.
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
%    tm        <-  struct. Contains the fields 
%        tws       <-  nested cell array of twists
%        gcnames   <-  array with names for the generalized
%                      coordinates.
%        p0        <-  nested cell with reference marker positions.
%        jcs       <-  nested cell with joint centra 
%        CoM       <-  nested cell with center of mass 
%    endpointstr   <-  If not empty, contains the name of the
%                      marker used as endpoint
%

% Kjartan Halvorsen
% 2009-06-26
% Based on build_tennis_model.m from  2003-09-16
  
% Revisions
% 2010-03-21   Added output endpointstr 
% 2010-06-20   Added 3dof for the right arm (FT)
% 2010-06-20   Added relative peak acceleration for each degree of freedom
%              during the downswing phase (FT)
% 2013-06-06   Added inertial parameters to the model. These are based on de Leva, 
%              J Biomech 1996 (KH)
% 2013-07-08   Skip club from model. Use only to define common local reference frame (object
%              frame) for both right and left arm. The reference frame is defined from 
%              the club markers, and assumed fixed to the two endpoints (hands).
% 2013-07-19   Make shoulder 3dof to ease interpretation of mobility

% Find suitable frame to use as address position

club_1_tr = extractmarkers(trialdata, 'ClubCoM');
[impact, impact_fit, pquad, dist2address, max_before_backsw] ...
= find_impact_from_point(club_1_tr);

trialdata{2} = trialdata{2}(max_before_backsw:max_before_backsw+1,:);

c7 = mmyextractmeanmarkers(refdata, 'C7');
ij = mmyextractmeanmarkers(refdata, 'IJ');
shoulder_l = mmyextractmeanmarkers(refdata, 'L_Acromion');
shoulder_r = mmyextractmeanmarkers(refdata, 'R_Acromion');
ghjc_l = mmyextractmeanmarkers(refdata, 'Wrt_LShoulder');
ghjc_r = mmyextractmeanmarkers(refdata, 'Wrt_RShoulder');
elbow_lat_l = mmyextractmeanmarkers(refdata, 'L_Elbow_lateral');
elbow_med_l = mmyextractmeanmarkers(refdata, 'L_Elbow_medial');
elbow_lat_r = mmyextractmeanmarkers(refdata, 'R_Elbow_lateral');
elbow_med_r = mmyextractmeanmarkers(refdata, 'R_Elbow_medial');
wrist_radial_l = mmyextractmeanmarkers(refdata, 'L_Radial_wrist');
wrist_ulnar_l = mmyextractmeanmarkers(refdata, 'L_Ulnar_wrist');
wrist_radial_r = mmyextractmeanmarkers(refdata, 'R_Radial_wrist');
wrist_ulnar_r = mmyextractmeanmarkers(refdata, 'R_Ulnar_wrist');
asis_l = mmyextractmeanmarkers(refdata, 'L_ASIS');
asis_r = mmyextractmeanmarkers(refdata, 'R_ASIS');
psis_l = mmyextractmeanmarkers(refdata, 'L_PSIS');
psis_r = mmyextractmeanmarkers(refdata, 'R_PSIS');
t8 = mmyextractmeanmarkers(refdata, 'T8');
pelvis_1 = mmyextractmeanmarkers(refdata, 'Pelvis_1');
pelvis_2 = mmyextractmeanmarkers(refdata, 'Pelvis_2');
pelvis_3 = mmyextractmeanmarkers(refdata, 'Pelvis_3');
ut_1 = mmyextractmeanmarkers(refdata, 'Upper_Torso_1');
ut_2 = mmyextractmeanmarkers(refdata, 'Upper_Torso_2');
ut_3 = mmyextractmeanmarkers(refdata, 'Upper_Torso_3');
uarm_1_l = mmyextractmeanmarkers(refdata, 'L_Upper_Arm_1');
uarm_2_l = mmyextractmeanmarkers(refdata, 'L_Upper_Arm_2');
uarm_3_l = mmyextractmeanmarkers(refdata, 'L_Upper_Arm_3');
uarm_1_r = mmyextractmeanmarkers(refdata, 'R_Upper_Arm_1');
uarm_2_r = mmyextractmeanmarkers(refdata, 'R_Upper_Arm_2');
uarm_3_r = mmyextractmeanmarkers(refdata, 'R_Upper_Arm_3');
hand_1_l = mmyextractmeanmarkers(refdata, 'L_Hand_1');
hand_2_l = mmyextractmeanmarkers(refdata, 'L_Hand_2');
hand_3_l = mmyextractmeanmarkers(refdata, 'L_Hand_3');
hand_1_r = mmyextractmeanmarkers(refdata, 'R_Hand_1');
hand_2_r = mmyextractmeanmarkers(refdata, 'R_Hand_2');
hand_3_r = mmyextractmeanmarkers(refdata, 'R_Hand_3');
hand_1_l_trial = mmyextractmeanmarkers(trialdata, 'L_HAND_1');
hand_2_l_trial = mmyextractmeanmarkers(trialdata, 'L_HAND_2');
hand_3_l_trial = mmyextractmeanmarkers(trialdata, 'L_HAND_3');
hand_1_r_trial = mmyextractmeanmarkers(trialdata, 'R_HAND_1');
hand_2_r_trial = mmyextractmeanmarkers(trialdata, 'R_HAND_2');
hand_3_r_trial = mmyextractmeanmarkers(trialdata, 'R_HAND_3');
mp_2_l = mmyextractmeanmarkers(refdata, 'L_2nd_MP_joint');
mp_5_l = mmyextractmeanmarkers(refdata, 'L_5th_MP_joint');
mp_2_r = mmyextractmeanmarkers(refdata, 'R_2nd_MP_joint');
mp_5_r = mmyextractmeanmarkers(refdata, 'R_5th_MP_joint');
grip_top = mmyextractmeanmarkers(refdata, 'TopOfHandle');
heel_bottom_grove = mmyextractmeanmarkers(refdata, 'BottomGroveHeel');
toe_bottom_grove = mmyextractmeanmarkers(refdata, 'BottomGroveToe');
toe_top_grove = mmyextractmeanmarkers(refdata, 'TopGroveToe');
club_1 = mmyextractmeanmarkers(refdata, 'Club_1');
club_2 = mmyextractmeanmarkers(refdata, 'Club_2');
club_3 = mmyextractmeanmarkers(refdata, 'Club_3');
club_1_trial = mmyextractmeanmarkers(trialdata, 'CLUB_1');
club_2_trial = mmyextractmeanmarkers(trialdata, 'CLUB_2');
club_3_trial = mmyextractmeanmarkers(trialdata, 'CLUB_3');
%midhands_1 = mmyextractmeanmarkers(refdata, 'MidHands_1');
%midhands_2 = mmyextractmeanmarkers(refdata, 'MidHands_2');



% Transform the club markers so that they appear in the reference trial (which is
% as always neutral standing) as if gripped as in addressing the ball. This means that
% there will be separate reference club points for each arm. 
g_cl_trial_ref = ...
    soder(cat(1, ...
	      cat(2, club_1', club_2', club_3'),...
	      cat(2, club_1_trial', club_2_trial', ...
		  club_3_trial')));
g_rh_ref_trial = ...
    soder(cat(1, ...
	      cat(2, hand_1_r_trial', hand_2_r_trial', ...
		  hand_3_r_trial'),...
	      cat(2, hand_1_r', hand_2_r', hand_3_r')));
g_lh_ref_trial = ...
    soder(cat(1, ...
	      cat(2, hand_1_l_trial', hand_2_l_trial', ...
		  hand_3_l_trial'),...
	      cat(2, hand_1_l', hand_2_l', hand_3_l')));

club_1_r = g_rh_ref_trial*g_cl_trial_ref * cat(1, club_1, 1);
club_1_r(4)=[];
club_2_r = g_rh_ref_trial*g_cl_trial_ref * cat(1, club_2, 1);
club_2_r(4)=[];
club_3_r = g_rh_ref_trial*g_cl_trial_ref * cat(1, club_3, 1);
club_3_r(4)=[];
grip_top_r = g_rh_ref_trial*g_cl_trial_ref * cat(1, grip_top, 1);
grip_top_r(4)=[];
heel_bottom_grove_r = g_rh_ref_trial*g_cl_trial_ref * cat(1, heel_bottom_grove, 1);
heel_bottom_grove_r(4)=[];
toe_bottom_grove_r = g_rh_ref_trial*g_cl_trial_ref * cat(1, toe_bottom_grove, 1);
toe_bottom_grove_r(4)=[];
toe_top_grove_r = g_rh_ref_trial*g_cl_trial_ref * cat(1, toe_top_grove, 1);
toe_top_grove_r(4)=[];

club_1_l = g_lh_ref_trial*g_cl_trial_ref * cat(1, club_1, 1);
club_1_l(4)=[];
club_2_l = g_lh_ref_trial*g_cl_trial_ref * cat(1, club_2, 1);
club_2_l(4)=[];
club_3_l = g_lh_ref_trial*g_cl_trial_ref * cat(1, club_3, 1);
club_3_l(4)=[];
grip_top_l = g_lh_ref_trial*g_cl_trial_ref * cat(1, grip_top, 1);
grip_top_l(4)=[];
heel_bottom_grove_l = g_lh_ref_trial*g_cl_trial_ref * cat(1, heel_bottom_grove, 1);
heel_bottom_grove_l(4)=[];
toe_bottom_grove_l = g_lh_ref_trial*g_cl_trial_ref * cat(1, toe_bottom_grove, 1);
toe_bottom_grove_l(4)=[];
toe_top_grove_l = g_lh_ref_trial*g_cl_trial_ref * cat(1, toe_top_grove, 1);
toe_top_grove_l(4)=[];


		       
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

% The root segment: pelvis
pelvis.name = 'pelvis';
                                             
e_x = e_LR;
e_y = e_PA;
e_z = e_IS;

pelvis.localframe = cat(1, cat(2, e_x, e_y, e_z, midpelvis),...
			[0 0 0 1]);
pelvis.dof = {[1 2 3], [1 2 3]};

%states with typical range of motion
pelvis.states = {'pelvis x', 0.0821
		 'pelvis y', 0.0640
		 'pelvis z', 0.0770
		 'pelvis tilt', 0.1648
		 'pelvis obliqueity', 0.2129
		 'pelvis rotation', 0.3120};

% Tracking markers
pelvis.markers = {'PELVIS_1' pelvis_1
		  'PELVIS_2' pelvis_2
		  'PELVIS_3' pelvis_3};

%% Using LPT (lower part of trunk) data from de Leva
pelvis.length = 146*1e-3;
pelvis.mass = 0.112*bodymass;
pelvis.CoM = midpelvis;
pelvis.g0 = pelvis.localframe; %% Local coordinate system with origin at CoM of segment.
pelvis.moment_of_inertia = pelvis.mass ...
			   * diag( (pelvis.length*[0.615 0.551 0.587]).^2 );
pelvis.generalized_inertia = [pelvis.mass*eye(3) zeros(3,3)
			      zeros(3,3)  pelvis.moment_of_inertia];

% The trunk
trunk.name = 'trunk';
trunk_center = midpelvis; % Assume rotations around a point in
                              % the middle of the asis-psis plane.
trunk.localframe = cat(1, cat(2, e_x, e_y, e_z, trunk_center),...
		       [0 0 0 1]);
trunk.dof = {[2 1 3], []}; % The order of (euler) angles is y-x-z
trunk.states = {'trunk tilt', 0.2541
	        'trunk obliquety', 0.2468
	        'trunk rotation', 0.3226};
trunk.markers = {'UPPER_TORSO_1', ut_1
		 'UPPER_TORSO_2', ut_2
		 'UPPER_TORSO_3', ut_3};

%% Using MPT together with UPT (middle and upper part of trunk) data from de Leva
%% Ignoring the head, since it is close to still during the movement.
mpt.length = 216*1e-3;
mpt.mass = 0.163*bodymass;
mpt.CoM = midpelvis + 0.4*e_IS*mpt.length;
mpt.moment_of_inertia = mpt.mass  ...
			* diag( (mpt.length*[0.482 0.383 0.468]).^2 );
upt.length = 170*1e-3;
upt.mass = 0.16*bodymass;
upt.CoM = midtrunk - 0.3*e_IS*upt.length;
upt.moment_of_inertia = upt.mass  ...
			* diag( (upt.length*[0.716 0.454 0.659]).^2 );
trunk.mass = mpt.mass + upt.mass;
trunk.CoM = (mpt.CoM*mpt.mass + upt.CoM*upt.mass) / trunk.mass;
trunk.g0 = cat(1, cat(2, e_LR, e_PA, e_IS, trunk.CoM), [0 0 0 1]);
vm = mpt.CoM - trunk.CoM;
vu = upt.CoM - trunk.CoM;
trunk.moment_of_inertia = mpt.moment_of_inertia + mpt.mass * diag( [vm(2:3)'*vm(2:3)
								    vm([1 3])'*vm([1 3])
								    vm([1 2])'*vm([1 2])] ) ...
			  +upt.moment_of_inertia + upt.mass * diag( [vu(2:3)'*vu(2:3)
								    vu([1 3])'*vu([1 3])
								    vu([1 2])'*vu([1 2])] );
trunk.generalized_inertia = [trunk.mass*eye(3) zeros(3,3)
			     zeros(3,3) trunk.moment_of_inertia];

% The left arm 
luarm.name = 'left_upper_arm';
e_z = ejc_l - ghjc_l; % Local z-axis pointing axially from shoulder
                      % joint to elbow joint
e_z = e_z / norm(e_z);
e_x =  elbow_med_l - elbow_lat_l; % Local x-axis pointing
                                  % left-right 
e_x = e_x - (e_x'*e_z)*e_z;
e_x = e_x / norm(e_x);
e_y = cross(e_z, e_x);

luarm.localframe = cat(1, cat(2, e_x, e_y, e_z, ghjc_l),...
		      [0 0 0 1]);
luarm.dof = {[1 2 3], []};
%'left shoulder x', 0.1050
%            'left shoulder y', 0.1148
%            'left shoulder z', 0.0850
%            'left shoulder flexion', 0.6668
luarm.states = {'left shoulder flexion', 0.6668
            'left shoulder abduction', 0.7578
            'left shoulder rotation', 0.5297};
luarm.markers = {'L_Upper_Arm_1' , uarm_1_l
		'L_Upper_Arm_2' , uarm_2_l
		 'L_Upper_Arm_3' , uarm_3_l};

%% Data from de Leva
luarm.length = norm(ejc_l - ghjc_l);
luarm.mass = 0.027*bodymass;
luarm.CoM = ghjc_l + 0.577*luarm.length*e_z;
luarm.g0 = cat(1, cat(2, e_x, e_y, e_z, luarm.CoM), [0 0 0 1]);
luarm.moment_of_inertia = luarm.mass ...
			   * diag( (luarm.length*[0.285 0.269 0.158]).^2 );
luarm.generalized_inertia = [luarm.mass*eye(3) zeros(3,3)
			      zeros(3,3)  luarm.moment_of_inertia];

% Forearm
e_z = wjc_l - ejc_l;
e_z = e_z / norm(e_z);
e_x = e_x - (e_x'*e_z)*e_z; % Local x-axis similar to upper arm,
                            % but adjusted for the different axial direction
e_x = e_x / norm(e_x);
e_y = cross(e_z, e_x);

llarm.name = 'left_forearm';
llarm.localframe = cat(1, cat(2, e_x, e_y, e_z, ejc_l),...
		      [0 0 0 1]);
llarm.dof = {[1 3], []};
llarm.states = {'left elbow flexion', 0.5708
	      'left elbow rotation', 0.6794};
llarm.markers = {}; % No markers to track the forearm

%% Data from de Leva
llarm.length = norm(ejc_l - wjc_l);
llarm.mass = 0.0162*bodymass;
llarm.CoM = ejc_l + 0.457*llarm.length*e_z;
llarm.g0 = cat(1, cat(2, e_x, e_y, e_z, llarm.CoM), [0 0 0 1]);
llarm.moment_of_inertia = llarm.mass ...
			   * diag( (llarm.length*[0.276 0.265 0.121]).^2 );
llarm.generalized_inertia = [llarm.mass*eye(3) zeros(3,3)
			      zeros(3,3)  llarm.moment_of_inertia];

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
lhand.dof = {[1 2], []};
lhand.states = {'left wrist flexion', 0.5369
	      'left wrist abduction', 0.8487};
lhand.markers = {'L_Hand_1', hand_1_l
		 'L_Hand_2', hand_2_l
		 'L_Hand_3', hand_3_l
		 'CLUB_1', club_1_l
		 'CLUB_2', club_2_l
		 'CLUB_3', club_3_l};
%% Data from de Leva
lhand.length = norm(mid_mp_l - wjc_l);
lhand.mass = 0.0061*bodymass;
lhand.CoM = wjc_l + 0.79*lhand.length*e_z;
lhand.g0 = cat(1, cat(2, e_x, e_y, e_z, lhand.CoM), [0 0 0 1]);
lhand.moment_of_inertia = lhand.mass ...
			   * diag( (lhand.length*[0.628 0.513 0.40]).^2 );
lhand.generalized_inertia = [lhand.mass*eye(3) zeros(3,3)
			      zeros(3,3)  lhand.moment_of_inertia];


% The right arm 
ruarm.name = 'right_upper_arm';
e_z = ejc_r - ghjc_r; % Local z-axis pointing axially from shoulder
                      % joint to elbow joint
e_z = e_z / norm(e_z);
e_x =  elbow_lat_r - elbow_med_r; % Local x-axis pointing
                                  % left-right 
e_x = e_x - (e_x'*e_z)*e_z;
e_x = e_x / norm(e_x);
e_y = cross(e_z, e_x);

ruarm.localframe = cat(1, cat(2, e_x, e_y, e_z, ghjc_r),...
		      [0 0 0 1]);
ruarm.dof = {[1 2 3], []};
%'right shoulder x', 0.2678
%            'right shoulder y', 0.1001
%            'right shoulder z', 0.1048
            
ruarm.states = {'right shoulder flexion', 0.5174
		'right shoulder abduction', 0.3660
	       'right shoulder rotation', 1};
ruarm.markers = {'R_Upper_Arm_1' , uarm_1_r
		'R_Upper_Arm_2' , uarm_2_r
		 'R_Upper_Arm_3' , uarm_3_r};

%% Data from de Leva
ruarm.length = norm(ejc_r - ghjc_r);
ruarm.mass = 0.027*bodymass;
ruarm.CoM = ghjc_r + 0.577*ruarm.length*e_z;
ruarm.g0 = cat(1, cat(2, e_x, e_y, e_z, ruarm.CoM), [0 0 0 1]);
ruarm.moment_of_inertia = ruarm.mass ...
			   * diag( (ruarm.length*[0.285 0.269 0.158]).^2 );
ruarm.generalized_inertia = [ruarm.mass*eye(3) zeros(3,3)
			      zeros(3,3)  ruarm.moment_of_inertia];


% Forearm
e_z = wjc_r - ejc_r;
e_z = e_z / norm(e_z);
e_x = e_x - (e_x'*e_z)*e_z; % Local x-axis similar to upper arm,
                            % but adjusted for the different axial direction
e_x = e_x / norm(e_x);
e_y = cross(e_z, e_x);

rlarm.name = 'right_forearm';
rlarm.localframe = cat(1, cat(2, e_x, e_y, e_z, ejc_r),...
		      [0 0 0 1]);
rlarm.dof = {[1 3], []};
rlarm.states = {'right elbow flexion', 0.7490
	      'right elbow rotation', 0.2101};
rlarm.markers = {}; % No markers to track the forearm

%% Data from de Leva
rlarm.length = norm(ejc_r - wjc_r);
rlarm.mass = 0.0162*bodymass;
rlarm.CoM = ejc_r + 0.457*rlarm.length*e_z;
rlarm.g0 = cat(1, cat(2, e_x, e_y, e_z, rlarm.CoM), [0 0 0 1]);
rlarm.moment_of_inertia = rlarm.mass ...
			   * diag( (rlarm.length*[0.276 0.265 0.121]).^2 );
rlarm.generalized_inertia = [rlarm.mass*eye(3) zeros(3,3)
			      zeros(3,3)  rlarm.moment_of_inertia];

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
rhand.dof = {[1 2], []};
rhand.states = {'right wrist flexion', 0.9170
	      'right wrist abduction', 0.5507};
rhand.markers = {'R_Hand_1', hand_1_r
		 'R_Hand_2', hand_2_r
		 'R_Hand_3', hand_3_r
		 'CLUB_1', club_1_r
		 'CLUB_2', club_2_r
		 'CLUB_3', club_3_r};
%% Data from de Leva
rhand.length = norm(mid_mp_r - wjc_r);
rhand.mass = 0.0061*bodymass;
rhand.CoM = wjc_r + 0.79*rhand.length*e_z;
rhand.g0 = cat(1, cat(2, e_x, e_y, e_z, rhand.CoM), [0 0 0 1]);
rhand.moment_of_inertia = rhand.mass ...
			   * diag( (rhand.length*[0.628 0.513 0.40]).^2 );
rhand.generalized_inertia = [rhand.mass*eye(3) zeros(3,3)
			      zeros(3,3)  rhand.moment_of_inertia];


% The club

% We need to define two club segments, but tracked using the same
% markers. Each "club" is at the end of either left and right
% kinematic chain.

e_z = grip_top_l - heel_bottom_grove_l;
e_z = e_z / norm(e_z);
e_y = toe_bottom_grove_l - heel_bottom_grove_l;
e_y = e_y - (e_y'*e_z)*e_z; 
e_y = e_y / norm(e_y);
e_x = cross(e_y, e_z);


club_head_center = 0.5*heel_bottom_grove_l + 0.5*toe_top_grove_l; 
% This point
% is used to
% compute the
% velocity of
% the club head

lhand.object_frame = cat(1, cat(2, e_x, e_y, e_z, club_head_center),...
			[0 0 0 1]);

grip2hand = wjc_r - grip_top_r;
club_head_center = 0.5*heel_bottom_grove_r + 0.5*toe_top_grove_r; 

e_z = grip_top_r - heel_bottom_grove_r;
e_z = e_z / norm(e_z);
e_y = toe_bottom_grove_r - heel_bottom_grove_r;
e_y = e_y - (e_y'*e_z)*e_z; 
e_y = e_y / norm(e_y);
e_x = cross(e_y, e_z);

rhand.object_frame = cat(1, cat(2, e_x, e_y, e_z, club_head_center),...
			[0 0 0 1]);
%club_r.CoM = club_1_r;
endpointstr = 'ClubCoM';


%----------------------------------------------------------------
% Define the complete model
%----------------------------------------------------------------

[tws, p0, gcnames, jc, segmnames, CoM, radius, mass, g0, inertia, object_frame, object_center] = build_model(pelvis);
[tws_ub, p0_ub, gcnames_ub, jc_ub, segmnames_ub, CoM_ub, radius_ub, ...
 mass_ub, g0_ub,  inertia_ub, object_frame_ub, object_center_ub] = build_model(trunk);
[tws_la, p0_la, gcnames_la, jc_la, segmnames_la, CoM_la, radius_la, ...
mass_la, g0_la, inertia_la, object_frame_la, object_center_la] =  build_model(luarm, llarm, lhand);
[tws_ra, p0_ra, gcnames_ra, jc_ra, segmnames_ra, CoM_ra, radius_ra, ...
mass_ra, g0_ra, inertia_ra, object_frame_ra, object_center_ra] = build_model(ruarm, rlarm, rhand);

tws_ub{2} = tws_la;
tws_ub{3} = tws_ra;
tws{2} = tws_ub;

p0_ub{2} = p0_la;
p0_ub{3} = p0_ra;
p0{2} = p0_ub;

jc_ub{2} = jc_la;
jc_ub{3} = jc_ra;
jc{2} = jc_ub;

gcnames_ub = cat(1, gcnames_ub, gcnames_la, gcnames_ra); 
gcnames = cat(1, gcnames, gcnames_ub);

segmnames_ub = cat(1, segmnames_ub, segmnames_la, segmnames_ra); 
segmnames = cat(1, segmnames, segmnames_ub);

CoM_ub{2} = CoM_la;
CoM_ub{3} = CoM_ra;
CoM{2} = CoM_ub;

g0_ub{2} = g0_la;
g0_ub{3} = g0_ra;
g0{2} = g0_ub;

inertia_ub{2} = inertia_la;
inertia_ub{3} = inertia_ra;
inertia{2} = inertia_ub;

object_frame_ub{2} = object_frame_la;
object_frame_ub{3} = object_frame_ra;
object_frame{2} = object_frame_ub;

object_center_ub{2} = object_center_la;
object_center_ub{3} = object_center_ra;
object_center{2} = object_center_ub;

tm.twists = tws;
tm.p0 = p0;
tm.jcs = jc;
tm.gcnames = gcnames;
tm.segm_names = segmnames;
tm.CoM = CoM;
tm.g0 = g0;
tm.inertia = inertia;
tm.object_frame = object_frame;
tm.objectcenter = object_center;

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
