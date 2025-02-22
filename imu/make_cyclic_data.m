 dta = load("./mocapdata/mc200_3_smooth");
 
 qc = (dta.q(:,886:1030))';
 

 %% Make periodic using fft
 Qc = fft(qc);
 Qc(10:end, :) = 0;
 qc = real(ifft(Qc));

%% Make unit norm
 qcn = zeros(size(qc));
 for i=1:size(qc,1)
   qcn(i,:) = qc(i,:) / norm(qc(i,:));
 end

 q1inv = qinv(qcn(1,:));
 for i=1:size(qcn,1)
   qcn(i,:) = qmult(qcn(i,:), q1inv);
 end

%% Compute exact derivative
 dqcn = periodic_derivative(qcn, 1/125, 0);

%% Angular velocity
wq = zeros(size(qcn));
for i=1:size(qc,1)
  wq(i,:) = 2*qmult(dqcn(i,:), qinv(qcn(i,:)));
end

figure(1)
clf
plot(repmat(qcn,3,1));
hold on
plot(repmat(dqcn/5, 3, 1), 'linewidth', 2);

figure(2)
clf
plot(repmat(wq,3,1));

w = wq(:,1:3)';
q = qcn';

alpha = (periodic_derivative(w', 1/125, 0))';


%% Make acceleration periodic
ac = (dta.a(:,886:1030))';
Ac = fft(ac);
Ac(10:end, :) = 0;
Ac(1,:) = 0;
a = (real(ifft(Ac)))';

t = (0:144)'/125;
v = cumtrapz([t t t], a')';
d = cumtrapz([t t t], v')';

save -mat periodic-realistic-matlab q w alpha a


%% Check

qdt = centraldiff(q', 125);
wtest = zeros(size(qdt));



   