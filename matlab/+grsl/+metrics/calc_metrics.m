function m = calc_metrics(yTrue, yPred)
% Common regression error metrics. Bias = prediction - reference.
yTrue = yTrue(:);
yPred = yPred(:);
valid = isfinite(yTrue) & isfinite(yPred);
yTrue = yTrue(valid);
yPred = yPred(valid);
m.N = numel(yTrue);
if m.N == 0
    m.RMSE = NaN;
    m.MAE = NaN;
    m.Bias = NaN;
    m.R2 = NaN;
    return;
end
err = yPred - yTrue;
m.RMSE = sqrt(mean(err.^2));
m.MAE = mean(abs(err));
m.Bias = mean(err);
m.R2 = grsl.metrics.calc_r2(yTrue, yPred);
end
