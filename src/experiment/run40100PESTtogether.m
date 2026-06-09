% run40100PESTtogether.m
% Author: Zhenxian LI (zhenxian.li@insa-lyon.fr), INSA Lyon, LVA
% -------------------------------------------------------------------------
% Convenience wrapper that runs both reference-speed blocks in one session.
% By default the 100 km/h block is run first, then the 40 km/h block.
%
% Remember to counter-balance the block order (and the sound-condition order
% inside each block) across participants.
% -------------------------------------------------------------------------

run2down1upPEST100
run2down1upPEST40
