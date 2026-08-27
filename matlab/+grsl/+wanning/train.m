function result = train(cfg)
% Reproduce the latest Wanning FCNN tuning and self-validation workflow.
w = cfg.wanning;
grsl.config.require_files({w.trainingSatelliteFile});
assert(isfolder(w.trackMatFolder), 'Missing Wanning track folder: %s', w.trackMatFolder);
grsl.config.ensure_dir(w.outputDir);
rng(cfg.randomSeed, 'twister');

[img, R] = geotiffread(w.trainingSatelliteFile);
info = geotiffinfo(w.trainingSatelliteFile);
assert(size(img, 3) >= 4, 'Wanning raster must contain at least four bands.');
img4 = img(:,:,1:4);
[nRows, nCols, ~] = size(img4);
img4_2d = reshape(img4, nRows * nCols, 4);
builder = @(path, trackId) grsl.tracks.build_one_track_dataset(path, ...
    w.trainingWaterSurface, R, info, img4_2d, nRows, nCols, trackId);
[trackData, trackNames, trackCounts] = ...
    grsl.tracks.build_track_pool(w.trackMatFolder, builder);
rawRows = vertcat(trackData{:});
assert(size(rawRows, 1) == 1365, ...
    'Expected 1365 Wanning aggregated controls; found %d.', size(rawRows, 1));
[foldIdRaw, foldAudit] = grsl.tracks.stratified_pixel_folds( ...
    rawRows(:,5), rawRows(:,8), cfg.nFolds, 2, 62026);

excludedRawRows = [710; 711; (1070:1077)'];
keep = true(size(rawRows, 1), 1);
keep(excludedRawRows) = false;
rows = rawRows(keep, :);
foldId = foldIdRaw(keep);
rawRow = find(keep);
assert(size(rows, 1) == 1355, 'Expected 1355 clean controls.');

X4 = rows(:,1:4);
y = rows(:,5);
featureSets = grsl.wanning.build_feature_sets(X4, rows(:,8), nRows, nCols);
dTrain99 = prctile(y, 99);
hMax = w.hMax;
specs = grsl.wanning.candidate_specs();
predictions = nan(numel(y), numel(specs));
candidateMetrics = table();

for iSpec = 1:numel(specs)
    spec = specs(iSpec);
    X = featureSets.(spec.FeatureMode);
    pred = grsl.model.run_fixed_fivefold(X, y, foldId, ...
        cfg.nFolds, spec, 50000);
    predictions(:, iSpec) = pred;
    overall = grsl.metrics.calc_metrics(y, pred);
    shallow = grsl.metrics.calc_metrics(y(y < hMax), pred(y < hMax));
    transitionMask = y >= hMax & y < dTrain99;
    transition = grsl.metrics.calc_metrics(y(transitionMask), pred(transitionMask));
    firstUpper = ceil(hMax / 2) * 2;
    firstMask = y >= hMax & y < firstUpper;
    firstTransition = grsl.metrics.calc_metrics(y(firstMask), pred(firstMask));
    tailMask = y >= dTrain99;
    tail = grsl.metrics.calc_metrics(y(tailMask), pred(tailMask));
    bins2 = grsl.metrics.compute_depth_bins(y, pred, 0:2:30, cfg.minReliableN);
    transitionBins = bins2.DepthUpper_m > hMax & ...
        bins2.DepthUpper_m <= 26 & bins2.Reliable;
    maxAbsTransitionBinBias = max(abs(bins2.Bias_m(transitionBins)), ...
        [], 'omitnan');
    score = grsl.wanning.candidate_score(overall, shallow, transition, ...
        firstTransition, maxAbsTransitionBinBias);
    row = table(string(spec.ID), string(spec.FeatureMode), ...
        string(mat2str(spec.LayerSizes)), string(spec.Activation), ...
        spec.Lambda, spec.IterationLimit, spec.DepthWeightRho, ...
        spec.DepthWeightPower, score, overall.N, overall.RMSE, ...
        overall.Bias, overall.MAE, overall.R2, shallow.N, shallow.RMSE, ...
        shallow.Bias, shallow.MAE, transition.N, transition.RMSE, ...
        transition.Bias, transition.MAE, firstTransition.N, ...
        firstTransition.RMSE, firstTransition.Bias, tail.N, tail.RMSE, ...
        tail.Bias, maxAbsTransitionBinBias, 'VariableNames', { ...
        'SpecID','FeatureMode','LayerSizes','Activation','Lambda', ...
        'IterationLimit','DepthWeightRho','DepthWeightPower','Score', ...
        'OverallN','OverallRMSE_m','OverallBias_m','OverallMAE_m','OverallR2', ...
        'ShallowN','ShallowRMSE_m','ShallowBias_m','ShallowMAE_m', ...
        'TransitionN','TransitionRMSE_m','TransitionBias_m','TransitionMAE_m', ...
        'FirstTransitionN','FirstTransitionRMSE_m','FirstTransitionBias_m', ...
        'TailN','TailRMSE_m','TailBias_m','MaxAbsTransition2mBinBias_m'});
    candidateMetrics = [candidateMetrics; row]; %#ok<AGROW>
end

candidateMetrics = sortrows(candidateMetrics, 'Score', 'ascend');
writetable(candidateMetrics, fullfile(w.outputDir, 'candidate_metrics.csv'));
bestID = candidateMetrics.SpecID(1);
bestIndex = find(string({specs.ID}) == bestID, 1);
bestSpec = specs(bestIndex);
bestPred = predictions(:, bestIndex);
Xbest = featureSets.(bestSpec.FeatureMode);
overall = grsl.metrics.calc_metrics(y, bestPred);
intervals = grsl.metrics.compute_intervals(y, bestPred, hMax, dTrain99);
bins2m = grsl.metrics.compute_depth_bins(y, bestPred, 0:2:30, cfg.minReliableN);
bins1m = grsl.metrics.compute_depth_bins(y, bestPred, 0:1:30, cfg.minReliableN);

predictionTable = table(rawRow, foldId, y, bestPred, bestPred - y, ...
    'VariableNames', {'RawRow','Fold','ReferenceDepth_m', ...
    'FCNNPrediction_m','ResidualPredMinusRef_m'});
writetable(predictionTable, w.internalPairsFile);
writetable(intervals, fullfile(w.outputDir, 'selected_interval_metrics.csv'));
writetable(bins2m, fullfile(w.outputDir, 'selected_2m_bins.csv'));
writetable(bins1m, fullfile(w.outputDir, 'selected_1m_bins.csv'));
writetable(candidateMetrics(1,:), fullfile(w.outputDir, 'selected_overall_metrics.csv'));
writetable(foldAudit, fullfile(w.outputDir, 'fold_assignment_audit.csv'));
writetable(table(trackNames, trackCounts), fullfile(w.outputDir, 'track_counts.csv'));

foldModels = cell(cfg.nFolds, 1);
for iFold = 1:cfg.nFolds
    trainMask = foldId ~= iFold;
    trainD99 = prctile(y(trainMask), 99);
    weights = grsl.depth.make_depth_weights(y(trainMask), trainD99, ...
        bestSpec.DepthWeightRho, bestSpec.DepthWeightPower);
    rng(50000 + iFold, 'twister');
    foldModels{iFold} = grsl.model.train_fcnn(Xbest(trainMask,:), y(trainMask), ...
        'LayerSizes', bestSpec.LayerSizes, 'Activations', bestSpec.Activation, ...
        'Standardize', true, 'Lambda', bestSpec.Lambda, ...
        'IterationLimit', bestSpec.IterationLimit, 'Weights', weights);
end
save(w.modelFile, 'foldModels', 'bestSpec', 'hMax', 'dTrain99', ...
    'excludedRawRows', 'trackNames', 'trackCounts', '-v7.3');

fig = grsl.wanning.make_self_validation_figure(y, bestPred, hMax, dTrain99, overall);
grsl.io.export_png(fig, fullfile(w.outputDir, 'wanning_fcnn_self_validation.png'), 600);
savefig(fig, fullfile(w.outputDir, 'wanning_fcnn_self_validation.fig'));
close(fig);

result = struct('BestSpec', bestSpec, 'Metrics', overall, ...
    'Hmax_m', hMax, 'Dtrain99_m', dTrain99, 'PairFile', w.internalPairsFile, ...
    'ModelFile', w.modelFile);
end
