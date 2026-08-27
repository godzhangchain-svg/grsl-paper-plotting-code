function T = compute_depth_bins(ref, pred, edges, minN)
% Compute lower-inclusive, upper-exclusive reference-depth-bin metrics.
if nargin < 4
    minN = 5;
end
ref = ref(:);
pred = pred(:);
nBins = numel(edges) - 1;
DepthLower_m = edges(1:end-1)';
DepthUpper_m = edges(2:end)';
DepthCenter_m = (DepthLower_m + DepthUpper_m) ./ 2;
N = zeros(nBins, 1);
Reliable = false(nBins, 1);
RMSE_m = nan(nBins, 1);
Bias_m = nan(nBins, 1);
MAE_m = nan(nBins, 1);
R2 = nan(nBins, 1);
BiasCI95Low_m = nan(nBins, 1);
BiasCI95High_m = nan(nBins, 1);
finitePair = isfinite(ref) & isfinite(pred);
for i = 1:nBins
    in = finitePair & ref >= edges(i) & ref < edges(i+1);
    N(i) = sum(in);
    Reliable(i) = N(i) >= minN;
    if Reliable(i)
        m = grsl.metrics.calc_metrics(ref(in), pred(in));
        err = pred(in) - ref(in);
        RMSE_m(i) = m.RMSE;
        Bias_m(i) = m.Bias;
        MAE_m(i) = m.MAE;
        R2(i) = m.R2;
        se = std(err) / sqrt(N(i));
        BiasCI95Low_m(i) = m.Bias - 1.96 * se;
        BiasCI95High_m(i) = m.Bias + 1.96 * se;
    end
end
T = table(DepthLower_m, DepthUpper_m, DepthCenter_m, N, Reliable, ...
    RMSE_m, Bias_m, MAE_m, R2, BiasCI95Low_m, BiasCI95High_m);
end
