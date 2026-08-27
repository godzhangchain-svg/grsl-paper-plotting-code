function T = compute_intervals(ref, pred, hMax, dTrain99)
% Summarize the three depth-support intervals used in the paper.
Interval = ["At or below Hmax"; "Hmax to Dtrain99"; "Above Dtrain99"];
masks = {ref <= hMax; ref > hMax & ref <= dTrain99; ref > dTrain99};
N = zeros(3, 1);
RMSE_m = nan(3, 1);
Bias_m = nan(3, 1);
MAE_m = nan(3, 1);
R2 = nan(3, 1);
for i = 1:3
    m = grsl.metrics.calc_metrics(ref(masks{i}), pred(masks{i}));
    N(i) = m.N;
    if m.N >= 5
        RMSE_m(i) = m.RMSE;
        Bias_m(i) = m.Bias;
        MAE_m(i) = m.MAE;
        R2(i) = m.R2;
    end
end
T = table(Interval, N, RMSE_m, Bias_m, MAE_m, R2);
end
