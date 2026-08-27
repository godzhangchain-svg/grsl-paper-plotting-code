function result = train_weighted(cfg)
% Reproduce the latest Oahu weighted-FCNN experiment with Hmax = 21.10 m.
o = cfg.oahu;
required = {o.trainingSatelliteFile, o.inferenceSatelliteFile, ...
    o.oldMaskFile, o.albFile, cfg.wanning.internalPairsFile, ...
    cfg.wanning.independentAllPairsFile, cfg.wanning.independentStatPairsFile};
grsl.config.require_files(required);
assert(isfolder(o.trackMatFolder), 'Missing Oahu track folder: %s', o.trackMatFolder);
assert(numel(dir(fullfile(o.trackMatFolder, '*.mat'))) == 31, ...
    'Expected 31 Oahu MAT tracks.');
grsl.config.ensure_dir(o.outputDir);
writetable(grsl.io.input_audit(required), fullfile(o.outputDir, 'input_audit.csv'));

seed = cfg.randomSeed;
nFolds = cfg.nFolds;
rhoCandidates = [1.05, 1.1, 1.2, 1.5, 2, 3, 4, 6];
powerCandidates = [1, 2, 4];
layerSizes = [10 10];
iterationLimit = 1000;

[trainingSatellite, trainingR] = geotiffread(o.trainingSatelliteFile);
trainingSatellite = double(trainingSatellite);
trainingImg4 = trainingSatellite(:,:,1:4);
[trainingRows, trainingCols, ~] = size(trainingImg4);
training2d = reshape(trainingImg4, trainingRows * trainingCols, 4);
builder = @(path, ~) grsl.tracks.build_one_track_dataset_oahu(path, ...
    o.waterSurface, trainingR, projcrs(32604), training2d, ...
    trainingRows, trainingCols);
[trackData, trackNames, trackCounts] = ...
    grsl.tracks.build_track_pool(o.trackMatFolder, builder);
assert(numel(trackData) == 31, 'Expected 31 valid Oahu tracks.');
[foldGroups, ~] = grsl.tracks.split_tracks_balanced(trackCounts, nFolds);
pool = vertcat(trackData{:});
poolDepth = pool(:,5);
poolD99 = prctile(poolDepth, 99);
poolMax = max(poolDepth);
writetable(grsl.tracks.build_fold_assignment(trackNames, trackCounts, foldGroups), ...
    fullfile(o.outputDir, 'track_fold_assignment.csv'));

[rhoGrid, powerGrid] = ndgrid(rhoCandidates, powerCandidates);
candidateRho = [1; rhoGrid(:)];
candidatePower = [1; powerGrid(:)];
nCandidate = numel(candidateRho);
candidatePairs = cell(nCandidate, 1);
overallTable = table();
intervalAll = table();
binsAll = table();
foldAudit = table();
foldRngStates = cell(nFolds, 1);
grsl.oahu.consume_pre_cv_rng(seed, o.albFile);

for iCandidate = 1:nCandidate
    rho = candidateRho(iCandidate);
    power = candidatePower(iCandidate);
    obsRaw = [];
    predRaw = [];
    foldRaw = [];
    for iFold = 1:nFolds
        valTracks = foldGroups{iFold};
        trainTracks = setdiff(1:numel(trackData), valTracks);
        trainSet = vertcat(trackData{trainTracks});
        valSet = vertcat(trackData{valTracks});
        Xtrain = trainSet(:,1:4); Ytrain = trainSet(:,5);
        Xval = valSet(:,1:4); Yval = valSet(:,5);
        foldD99 = prctile(Ytrain, 99);
        weights = grsl.depth.make_depth_weights(Ytrain, foldD99, rho, power);
        if iCandidate == 1
            foldRngStates{iFold} = rng;
        else
            rng(foldRngStates{iFold});
        end
        if rho == 1
            mdl = grsl.model.train_fcnn(Xtrain, Ytrain, ...
                'LayerSizes', layerSizes, 'Activations', 'relu', ...
                'Standardize', true, 'Lambda', 0, ...
                'IterationLimit', iterationLimit);
        else
            mdl = grsl.model.train_fcnn(Xtrain, Ytrain, ...
                'LayerSizes', layerSizes, 'Activations', 'relu', ...
                'Standardize', true, 'Lambda', 0, ...
                'IterationLimit', iterationLimit, 'Weights', weights);
        end
        Ypred = grsl.model.predict_fcnn(mdl, Xval);
        obsRaw = [obsRaw; Yval]; %#ok<AGROW>
        predRaw = [predRaw; Ypred]; %#ok<AGROW>
        foldRaw = [foldRaw; repmat(iFold, numel(Yval), 1)]; %#ok<AGROW>
        fm = grsl.metrics.calc_metrics(Yval, Ypred);
        foldRow = table(iCandidate, rho, power, iFold, numel(Ytrain), ...
            numel(Yval), foldD99, min(weights), max(weights), mean(weights), ...
            fm.RMSE, fm.Bias, fm.MAE, fm.R2, 'VariableNames', { ...
            'SpecID','Rho','WeightPower','Fold','TrainN','ValidationN', ...
            'TrainD99_m','WeightMin','WeightMax','WeightMean','RMSE_m', ...
            'Bias_m','MAE_m','R2'});
        foldAudit = [foldAudit; foldRow]; %#ok<AGROW>
    end
    keep = isfinite(obsRaw) & isfinite(predRaw) & obsRaw > 0 & ...
        (predRaw ./ obsRaw) <= 4;
    obs = obsRaw(keep); pred = predRaw(keep); fold = foldRaw(keep);
    pairs = table(obs, pred, pred - obs, fold, ...
        'VariableNames', {'ReferenceDepth_m','PredictedDepth_m','Residual_m','Fold'});
    candidatePairs{iCandidate} = pairs;
    writetable(pairs, fullfile(o.outputDir, sprintf( ...
        'candidate_%02d_rho_%s_power_%s_oof_pairs.csv', iCandidate, ...
        grsl.io.rho_tag(rho), grsl.io.rho_tag(power))));
    m = grsl.metrics.calc_metrics(obs, pred);
    overallRow = table(iCandidate, rho, power, m.N, m.RMSE, m.Bias, ...
        m.MAE, m.R2, 'VariableNames', {'SpecID','Rho','WeightPower', ...
        'N','RMSE_m','Bias_m','MAE_m','R2'});
    overallTable = [overallTable; overallRow]; %#ok<AGROW>
    intervals = grsl.metrics.compute_intervals(obs, pred, o.hMax, poolD99);
    intervals.SpecID = repmat(iCandidate, height(intervals), 1);
    intervals.Rho = repmat(rho, height(intervals), 1);
    intervals.WeightPower = repmat(power, height(intervals), 1);
    intervals = movevars(intervals, {'SpecID','Rho','WeightPower'}, 'Before', 1);
    intervalAll = [intervalAll; intervals]; %#ok<AGROW>
    bins = grsl.metrics.compute_depth_bins(obs, pred, 0:2:56, cfg.minReliableN);
    bins.SpecID = repmat(iCandidate, height(bins), 1);
    bins.Rho = repmat(rho, height(bins), 1);
    bins.WeightPower = repmat(power, height(bins), 1);
    bins.Validation = repmat("Internal", height(bins), 1);
    bins = movevars(bins, {'SpecID','Rho','WeightPower','Validation'}, 'Before', 1);
    binsAll = [binsAll; bins]; %#ok<AGROW>
end

writetable(overallTable, fullfile(o.outputDir, 'candidate_internal_overall_metrics.csv'));
writetable(foldAudit, fullfile(o.outputDir, 'candidate_fold_audit.csv'));
writetable(intervalAll, fullfile(o.outputDir, 'candidate_internal_interval_metrics.csv'));
writetable(binsAll, fullfile(o.outputDir, 'candidate_internal_2m_bins.csv'));
baseline = overallTable(overallTable.SpecID == 1, :);
assert(baseline.N == 5022, 'Oahu unweighted baseline N changed.');

selection = grsl.oahu.build_selection_table(overallTable, intervalAll);
selection = selection(selection.Rho > 1, :);
selection = sortrows(selection, {'TransitionRMSE_m','OverallRMSE_m', ...
    'AbsTransitionBias_m','Rho','WeightPower'}, ...
    {'ascend','ascend','ascend','ascend','ascend'});
selection.Rank = (1:height(selection))';
writetable(selection, fullfile(o.outputDir, 'candidate_internal_selection.csv'));
selectedRho = selection.Rho(1);
selectedPower = selection.WeightPower(1);
selectedIndex = selection.SpecID(1);
selectedPairs = candidatePairs{selectedIndex};
writetable(selectedPairs, o.internalPairsFile);
selectedBins = binsAll(binsAll.SpecID == selectedIndex, :);
writetable(selectedBins, fullfile(o.outputDir, 'selected_internal_2m_bins.csv'));

Xall = pool(:,1:4); Yall = pool(:,5);
weights = grsl.depth.make_depth_weights(Yall, poolD99, selectedRho, selectedPower);
rng(seed, 'twister');
finalModel = grsl.model.train_fcnn(Xall, Yall, 'LayerSizes', layerSizes, ...
    'Activations', 'relu', 'Standardize', true, 'Lambda', 0, ...
    'IterationLimit', iterationLimit, 'Weights', weights);
[inferenceSatellite, inferenceR] = geotiffread(o.inferenceSatelliteFile);
inferenceInfo = geotiffinfo(o.inferenceSatelliteFile);
inferenceSatellite = double(inferenceSatellite);
img4 = inferenceSatellite(:,:,1:4);
[nRows, nCols, ~] = size(img4);
img2d = reshape(img4, nRows * nCols, 4);
predAll = nan(nRows * nCols, 1);
chunk = 500000;
for first = 1:chunk:size(img2d, 1)
    last = min(first + chunk - 1, size(img2d, 1));
    Xblock = img2d(first:last, :);
    valid = all(isfinite(Xblock), 2);
    blockPred = nan(size(Xblock, 1), 1);
    blockPred(valid) = grsl.model.predict_fcnn(finalModel, Xblock(valid, :));
    predAll(first:last) = blockPred;
end
predGrid = reshape(predAll, nRows, nCols);
[oldSdb, oldR] = geotiffread(o.oldMaskFile);
assert(isequal(size(oldSdb), size(predGrid)), 'Oahu mask dimensions changed.');
grsl.raster.assert_reference_compatible(inferenceR, oldR);
predGrid(double(oldSdb) == 0) = 0;
grsl.raster.write_geotiff_like(o.sdbFile, single(predGrid), inferenceR, inferenceInfo);
save(o.modelFile, 'finalModel', 'selectedRho', 'selectedPower', ...
    'poolD99', 'poolMax', 'trackNames', 'trackCounts', 'foldGroups', '-v7.3');

[albRef, albPred, albAllPairs] = ...
    grsl.raster.validate_oahu_alb(o.sdbFile, o.albFile, seed);
writetable(albAllPairs, o.independentAllPairsFile);
albPairs = table(albRef, albPred, albPred - albRef, ...
    'VariableNames', {'ReferenceDepth_m','PredictedDepth_m','Residual_m'});
writetable(albPairs, o.independentStatPairsFile);
albMetrics = grsl.metrics.calc_metrics(albRef, albPred);
albBins = grsl.metrics.compute_depth_bins(albRef, albPred, 0:2:56, cfg.minReliableN);
writetable(albBins, fullfile(o.outputDir, 'oahu_independent_2m_bins.csv'));

wanInternal = readtable(cfg.wanning.internalPairsFile);
wanAll = readtable(cfg.wanning.independentAllPairsFile);
wanStat = readtable(cfg.wanning.independentStatPairsFile);
wanRefI = wanInternal.ReferenceDepth_m;
wanPredI = wanInternal.FCNNPrediction_m;
wanRefAll = wanAll.ReferenceDepth_m;
wanPredAll = wanAll.SDBPrediction_m;
wanRefStat = wanStat.ReferenceDepth_m;
wanPredStat = wanStat.SDBPrediction_m;
wanD99 = prctile(wanRefI, 99);
wanMetrics = grsl.metrics.calc_metrics(wanRefStat, wanPredStat);
oahRefI = selectedPairs.ReferenceDepth_m;
oahPredI = selectedPairs.PredictedDepth_m;
bW = struct('Hmax', cfg.wanning.hMax, 'Dtrain99', wanD99);
bO = struct('Hmax', o.hMax, 'Dtrain99', poolD99);
grsl.config.ensure_dir(cfg.fig3.outputDir);
fig = figure('Color', 'white', 'Position', [100 50 1100 950]);
positions = [0.06 0.56 0.40 0.40; 0.52 0.56 0.40 0.40; ...
    0.06 0.08 0.40 0.40; 0.52 0.08 0.40 0.40];
grsl.plots.validation_panel(axes('Position', positions(1,:)), ...
    wanRefI, wanPredI, [], 0.5, bW, false, '(a)', []);
grsl.plots.validation_panel(axes('Position', positions(2,:)), ...
    oahRefI, oahPredI, [], 0.5, bO, false, '(b)', []);
grsl.plots.validation_panel(axes('Position', positions(3,:)), ...
    wanRefAll, wanPredAll, 35, 0.5, bW, true, '(c)', wanMetrics);
grsl.plots.validation_panel(axes('Position', positions(4,:)), ...
    albAllPairs.ReferenceDepth_m, albAllPairs.PredictedDepth_m, ...
    55, 0.5, bO, true, '(d)', albMetrics);
figStem = fullfile(cfg.fig3.outputDir, 'fig3_combined_latest_fcnn');
grsl.io.export_png(fig, [figStem '.png'], 600);
savefig(fig, [figStem '.fig']);
close(fig);

panel = ["Wanning internal"; "Oahu internal"; ...
    "Wanning independent"; "Oahu independent"];
metrics = [grsl.metrics.calc_metrics(wanRefI, wanPredI); ...
    grsl.metrics.calc_metrics(oahRefI, oahPredI); wanMetrics; albMetrics];
N = arrayfun(@(m) m.N, metrics);
RMSE_m = arrayfun(@(m) m.RMSE, metrics);
Bias_m = arrayfun(@(m) m.Bias, metrics);
MAE_m = arrayfun(@(m) m.MAE, metrics);
R2 = arrayfun(@(m) m.R2, metrics);
Hmax_m = [cfg.wanning.hMax; o.hMax; cfg.wanning.hMax; o.hMax];
Dtrain99_m = [wanD99; poolD99; wanD99; poolD99];
writetable(table(panel, N, RMSE_m, Bias_m, MAE_m, R2, Hmax_m, Dtrain99_m), ...
    fullfile(cfg.fig3.outputDir, 'fig3_four_panel_metrics.csv'));
writetable(table(["Wanning";"Oahu"], ...
    [cfg.wanning.hMax;o.hMax], [wanD99;poolD99], ...
    'VariableNames', {'Site','Hmax_m','Dtrain99_m'}), ...
    fullfile(cfg.fig3.outputDir, 'fig3_boundaries.csv'));

result = struct('SelectedRho', selectedRho, ...
    'SelectedWeightPower', selectedPower, 'Dtrain99_m', poolD99, ...
    'IndependentMetrics', albMetrics, 'SdbFile', o.sdbFile, ...
    'InternalPairsFile', o.internalPairsFile, ...
    'IndependentPairsFile', o.independentStatPairsFile, ...
    'Fig3Png', [figStem '.png']);
end
