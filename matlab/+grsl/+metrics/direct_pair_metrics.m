function m = direct_pair_metrics(ref, pred)
% Metrics for direct ICESat-2 versus independent-reference comparisons.
valid = isfinite(ref) & isfinite(pred);
ref = ref(valid);
pred = pred(valid);
err = pred - ref;
base = grsl.metrics.calc_metrics(ref, pred);
m.Bias_m = base.Bias;
m.RMSE_m = base.RMSE;
m.MAE_m = base.MAE;
m.MedianBias_m = median(err);
m.P90AbsoluteError_m = prctile(abs(err), 90);
p = polyfit(ref, pred, 1);
fitPred = polyval(p, ref);
m.OLS_R2 = 1 - sum((pred - fitPred).^2) / sum((pred - mean(pred)).^2);
m.Predictive_R2 = base.R2;
m.Slope = p(1);
m.Intercept = p(2);
end
