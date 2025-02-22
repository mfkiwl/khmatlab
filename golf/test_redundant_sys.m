%% Script for testing understanding of theory of redundandt manipulators, chapter 6.3.1 in 
%% Murray, Li, Sastry p.286

%% Kjartan Halvorsen
%% 2013-06-12

%% Mechanism with three planar links

%% Twists
w = [0;0;1];
p1 = [0;0;0];
p2 = [1;0;0];
p3 = [2;0;0];
v1 = -cross(w,p1);
v2 = -cross(w,p2);
v3 = -cross(w,p3);

tws = { {hat([v1;w])}, { {hat([v2;w])}, { {hat([v3;w])} } } };
p03 = [3;0;0];
p0 = { [], { [], {p03} } };

N = 20;

%% Joint angles
th1b = linspace(0,4*pi, N);
th2b = linspace(0.2,6*pi+0.2, N);
th3b = linspace(0.4,2*pi+0.4, N);

%% Angles wrt x-axis
th1 = th1b;
th2 = th1b+th2b;
th3 = th1b+th2b+th3b;

%% End point coordinates, angles wrt x-axis
x = cos(th1) + cos(th2) + cos(th3);
y = sin(th1) + sin(th2) + sin(th3);

%% Computed using twists

p_e = zeros(3, N);
JH = zeros(2,3,N);
for i=1:N
  [p_e(:,i),H] = observe_mechanism_H(cat(1, th1b(i), th2b(i), th3b(i)), [1;1;1], tws, p0);
  JH(:,:,i) = H(1:2,1:3);
end

%% Assert that endpoint really the same
assert(p_e(1:2, :), cat(1, x, y), 1e-12);
disp('Test of endpoint calculation: OK')


%% Jacobian, stacked in the 3rd dimension
JJ = zeros(2, 3, N);
JJtest = zeros(2, 3, N);
JJtw = zeros(2, 3, N);
JJs = zeros(6, 3, N);
for i=1:N
  JJ(:,:,i) = [-sin(th1(i)) -sin(th2(i)) -sin(th3(i))
	       cos(th1(i)) cos(th2(i)) cos(th3(i))];
  JJtest(:,:,i) = [-sin(th1(i))-sin(th2(i))-sin(th3(i)) -sin(th2(i))-sin(th3(i)) -sin(th3(i))
	            cos(th1(i))+cos(th2(i))+cos(th3(i)) cos(th2(i))+cos(th3(i)) cos(th3(i))];
  Jstwi = spatial_manipulator_jacobian(tws, cat(1, th1b(i), th2b(i), th3b(i)));
  JJs(:,:,i) = Jstwi;
  JJtwi = zeros(4,size(Jstwi,2));
  p3h = cat(1, p_e(:,i), 1);
  for j=1:size(JJtwi,2)
      JJtwi(:,j) = hat(Jstwi(:,j))*p3h;
  end
  JJtw(:,:,i) = JJtwi(1:2,:);
end
			
assert(JJtest, JH, 1e-12);
disp('Test of Jacobian 1: OK')
assert(JJtest, JJtw, 1e-12);
disp('Test of Jacobian 2: OK')

%% Manipulator inertia
states = cat(1, th1b, th2b, th3b);
l1 = 1; l2 = 1; l3 = 1; m1 = 1; m2 = 1; m3 = 1;
rm = three_link_planar_model(l1, l2, l3, m1, m2, m3);

M = generalized_manipulator_inertia(rm, states);
WW1 = mobility(rm, states);			 

%% Choices of K
K1 = repmat([0, 0, 1], [1 1 N]);
K2 = cat(2, reshape(sin(th2-th3), [1,1,N]), ...
	 reshape(-sin(th1-th3), [1,1,N]), ...
	 reshape(sin(th1-th2), [1,1,N]));

Jbar1 = cat(1, JJ, K1);
Mbar1 = zeros(3,3,N);

Jbar2 = cat(1, JJ, K2);
Mbar2 = zeros(3,3,N);

Mbar3 = zeros(3,3,N);
for i=1:N
    Jinv1 = inv(Jbar1(:,:,i));
    Mbar1(:,:,i) = Jinv1'*M(:,:,i)*Jinv1;
    Jinv2 = inv(Jbar2(:,:,i));
    Mbar2(:,:,i) = Jinv2'*M(:,:,i)*Jinv2;
    Jinv3 = inv(cat(1, JJ(:,:,i), null(JJ(:,:,i))'));
    Mbar3(:,:,i) = Jinv3'*M(:,:,i)*Jinv3;
end

%% This fails:
%assert(Mbar1(1:2,1:2,:), Mbar2(1:2,1:2,:), 1e-12);

%% The effective mass of the manipulator depends on the parametrization of the internal
%% motion, through the matrix K, whose definition is through
%%    v_i = K \dot{theta},
%% that is, it gives a linear relation between the (instantanous) internal velocity v_i and
%% the joint velocities, in the same way as the regular jacobian does for the endpoint
%% velocity.
%% Can we force v_i to be zero by suitable choice of K (not zero)? Yes, if \dot{theta} lies
%% in the nullspace of K (is perpendicular to the rows of K).  


%% Mobility
W = zeros(2,2,N);
W3 = zeros(3,3,N);
W2 = zeros(3,3,N);
W3b = zeros(2,2,N);
W2b = zeros(2,2,N);
for i=1:N
    W(:,:,i) = JJ(:,:,i)*inv(M(:,:,i))*JJ(:,:,i)';
    W3(:,:,i) = inv(Mbar3(:,:,i));
    W2(:,:,i) = inv(Mbar2(:,:,i));
    W3b(:,:,i) = inv(Mbar3(1:2,1:2,i));
    W2b(:,:,i) = inv(Mbar2(1:2,1:2,i));
end

assert(W(1:2, 1:2, :), W3(1:2,1:2,:), 1e-12);
disp('Test of mobility calculation 1: OK')
assert(W(1:2, 1:2, :), W2(1:2,1:2,:), 1e-12);
disp('Test of mobility calculation 2: OK')

%% Fails
%assert(W(1:2, 1:2, :), W2b(1:2,1:2,:), 1e-12);
%disp('Test of mobility calculation 3: OK')
%assert(W(1:2, 1:2, :), W3b(1:2,1:2,:), 1e-12);
%disp('Test of mobility calculation 4: OK')

%% Both assertions above are true. So the choice of K does not affect the computed mobility.
%% This makes sense: Mobilty describes how "easy" it is to move the endpoint in different
%% directions. The (possible) internal motion does not affect this mobility.


%% Test what happens if we add a very heavy link.
largemass = 1000;
states2 = cat(1, zeros(1,N), states);
rm2 = planar_link_model([1;1;1;1], [largemass; 1; 1; 1], [-1;0;0]);
WW2 = mobility(rm2, states2);
M2 = generalized_manipulator_inertia(rm2, states2);

JJ2s = zeros(6, 4, N);
for i=1:N
    JJ2s(:,:,i) = spatial_manipulator_jacobian(rm2.twists, states2(:,i));
end

%assert(M, M2(2:4, 2:4, :), 20/largemass); % Actually fails with tolerance 1e-12
%disp('Test of mobility adding a heavy root segment: OK')
assert(JJs, JJ2s(:, 2:4, :), 1e-12); 
disp('Test of Jacobian calculation extra root segment: OK')

%% Fails
%assert(WW1, WW2, 20/largemass); %% Not quite equal, but close
%disp('Test of mobility calculation extra root segment: OK')




