function [distRecToStimCh] = RASdistanceToStim(RASCoordRecCh, RASCoordStimCh)
% Compute Euclidean distance to sSTIM channel based on RAS coordinates
% To compute this properly we need the spacing from the MRI!

distRecToStimCh = sqrt(sum((RASCoordRecCh - RASCoordStimCh).^2,2));

