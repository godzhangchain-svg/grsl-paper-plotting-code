function r2 = calc_r2(yTrue, yPred)
% Coefficient of determination with empty / zero-variance guards.
yTrue = yTrue(:);
yPred = yPred(:);
valid = isfinite(yTrue) & isfinite(yPred);
yTrue = yTrue(valid);
yPred = yPred(valid);
if numel(yTrue) < 2
    r2 = NaN;
    return;
end
sse = sum((yTrue - yPred).^2);
sst = sum((yTrue - mean(yTrue)).^2);
if sst == 0
    r2 = NaN;
else
    r2 = 1 - sse/sst;
end

end
