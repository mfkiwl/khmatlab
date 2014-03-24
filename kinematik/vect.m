function v=vect(R)
% function v=vect(R)
% The vector associated with a (usually) skew symmetric matrix.

% Kjartan Halvorsen
% 1999-05-31

Ras=(R-R.')/2;
v=[Ras(3,2); Ras(1,3); Ras(2,1)];