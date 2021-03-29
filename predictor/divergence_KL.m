function [kld] = divergence_KL(P,Q)
    N = length(P);
    % this must be the same as length(Q)
    kld = 0;
    % Now, we compute the KL-divergence
    for x=1:N
        kld = kld + P(x) * log(P(x)/Q(x));
    end
