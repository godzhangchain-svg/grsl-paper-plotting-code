function consume_pre_cv_rng(seed, albFile)
% Reproduce the ALB sampling RNG consumption before Oahu five-fold fitting.
rng(seed, 'twister');
d = load(albFile);
depth = d.depth(:);
depth = depth(depth > 0 & depth <= 60);
nSample = round(numel(depth) * 0.25);
randperm(numel(depth), nSample);
end
