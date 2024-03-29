% Jensen-Shannon divergence
% Measures the similarity between two probability distributions. Relies on
% KL divergence, now bounded within a finite range and made symmetrical

function [jsd] = divergence_JS(P,Q)
    N = length(P);
    % First, we create a new combined distribution M
    M = (P + Q)/2;
    % If, the KL divergence is taking the log2 of the distributions, then
    % resulting JSD will be bounded between 0  and 1, inclusive
    
    jsd = (1/2) * divergence_KL(P,M) + divergence_KL(Q, M);
    % as a consequence, JSD (P || Q) = JSD (Q || P)