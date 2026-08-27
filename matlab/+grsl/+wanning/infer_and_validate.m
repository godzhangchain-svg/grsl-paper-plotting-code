function result = infer_and_validate(cfg)
% Generate Wanning SDB and apply the locked -6.1 m MBES datum.
w = cfg.wanning;
grsl.config.require_files({w.modelFile, w.trainingSatelliteFile, w.referenceFile});
grsl.config.ensure_dir(w.outputDir);
M = load(w.modelFile, 'foldModels', 'bestSpec', 'hMax', 'dTrain99');
assert(abs(M.hMax - w.hMax) < 1e-12, ...
    'Saved Wanning Hmax does not match the configured 18.78 m value.');

[img, R] = geotiffread(w.trainingSatelliteFile);
info = geotiffinfo(w.trainingSatelliteFile);
img4 = img(:,:,1:4);
[nRows, nCols, ~] = size(img4);
maskSettings.ndwiThreshold = -0.05;
maskSettings.minimumStoredBandValue = 1200;
maskSettings.maximumStoredBandValue = 6000;
maskSettings.minimumObjectPixels = 100;
maskSettings.morphologyRadiusPixels = 2;
waterMask = grsl.raster.wanning_water_mask(img4, maskSettings);
grsl.raster.write_geotiff_like(fullfile(w.outputDir, ...
    'wanning731_fcnn_water_mask.tif'), uint8(waterMask), R, info);

img2d = reshape(img4, nRows * nCols, 4);
validIdx = find(waterMask(:));
sdbVector = nan(nRows * nCols, 1, 'single');
chunkSize = 100000;
for first = 1:chunkSize:numel(validIdx)
    last = min(first + chunkSize - 1, numel(validIdx));
    idx = validIdx(first:last);
    [row, col] = ind2sub([nRows, nCols], idx);
    X = grsl.wanning.feature_matrix(img2d(idx,1:4), row, col, ...
        nRows, nCols, M.bestSpec.FeatureMode);
    chunkPrediction = zeros(numel(idx), numel(M.foldModels));
    for iModel = 1:numel(M.foldModels)
        chunkPrediction(:,iModel) = ...
            grsl.model.predict_fcnn(M.foldModels{iModel}, X);
    end
    sdbVector(idx) = single(mean(chunkPrediction, 2));
end
sdb = reshape(sdbVector, nRows, nCols);
sdb(~waterMask) = NaN;
sdb(~isfinite(sdb) | sdb <= 0 | sdb > 100) = NaN;
grsl.raster.write_geotiff_like(w.sdbFile, sdb, R, info);

fig = figure('Visible', 'off', 'Color', 'white', 'Position', [100 80 1100 760]);
ax = axes(fig);
imagesc(ax, sdb, 'AlphaData', isfinite(sdb));
axis(ax, 'image');
set(ax, 'YDir', 'reverse', 'Color', [0.75 0.75 0.75], ...
    'FontName', 'Times New Roman', 'FontSize', 12);
colormap(ax, turbo(256));
clim(ax, [0 30]);
cb = colorbar(ax); cb.Label.String = 'SDB Depth (m)';
xlabel(ax, 'Column'); ylabel(ax, 'Row');
grsl.io.export_png(fig, fullfile(w.outputDir, 'wanning731_fcnn_sdb.png'), 300);
close(fig);

validation = grsl.raster.pair_wanning_rasters(w.referenceFile, ...
    w.referenceWaterSurface, 100, sdb, R, 2, 35);
metrics = grsl.metrics.calc_metrics(validation.ReferenceStat_m, ...
    validation.PredictionStat_m);
pairTable = table(validation.ReferenceAll_m, validation.PredictionAll_m, ...
    'VariableNames', {'ReferenceDepth_m','SDBPrediction_m'});
writetable(pairTable, w.independentAllPairsFile);
statTable = table(validation.ReferenceStat_m, validation.PredictionStat_m, ...
    validation.PredictionStat_m - validation.ReferenceStat_m, ...
    'VariableNames', {'ReferenceDepth_m','SDBPrediction_m', ...
    'ResidualPredMinusRef_m'});
writetable(statTable, w.independentStatPairsFile);
metricTable = table(metrics.N, metrics.RMSE, metrics.Bias, metrics.MAE, ...
    metrics.R2, w.referenceWaterSurface, ...
    'VariableNames', {'N','RMSE_m','Bias_m','MAE_m','R2', ...
    'ReferenceWaterSurface_m'});
writetable(metricTable, fullfile(w.outputDir, ...
    'wanning_fcnn_independent_metrics.csv'));
bins = grsl.metrics.compute_depth_bins(validation.ReferenceStat_m, ...
    validation.PredictionStat_m, 0:2:36, cfg.minReliableN);
writetable(bins, fullfile(w.outputDir, 'wanning_fcnn_independent_2m_bins.csv'));
fig = grsl.wanning.make_independent_scatter(validation.ReferenceAll_m, ...
    validation.PredictionAll_m, metrics, M.hMax, M.dTrain99, 30);
grsl.io.export_png(fig, fullfile(w.outputDir, ...
    'wanning_fcnn_independent_validation_scatter.png'), 600);
close(fig);

result = struct('Metrics', metrics, 'Hmax_m', M.hMax, ...
    'Dtrain99_m', M.dTrain99, 'SdbFile', w.sdbFile, ...
    'AllPairsFile', w.independentAllPairsFile, ...
    'StatPairsFile', w.independentStatPairsFile);
end
