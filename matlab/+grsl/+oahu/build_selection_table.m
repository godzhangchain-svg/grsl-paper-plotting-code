function T = build_selection_table(overall, intervals)
% Join overall and Hmax-to-Dtrain99 metrics for internal-only selection.
n = height(overall);
TransitionRMSE_m = nan(n, 1);
TransitionBias_m = nan(n, 1);
for i = 1:n
    q = intervals.SpecID == overall.SpecID(i) & ...
        intervals.Interval == "Hmax to Dtrain99";
    assert(sum(q) == 1, 'Oahu transition interval is incomplete.');
    TransitionRMSE_m(i) = intervals.RMSE_m(q);
    TransitionBias_m(i) = intervals.Bias_m(q);
end
SpecID = overall.SpecID;
Rho = overall.Rho;
WeightPower = overall.WeightPower;
OverallRMSE_m = overall.RMSE_m;
AbsTransitionBias_m = abs(TransitionBias_m);
T = table(SpecID, Rho, WeightPower, TransitionRMSE_m, ...
    TransitionBias_m, AbsTransitionBias_m, OverallRMSE_m);
end
