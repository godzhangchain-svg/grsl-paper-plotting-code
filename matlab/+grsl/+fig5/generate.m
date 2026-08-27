function outputs = generate(cfg)
% Apply the locked Wanning datum and Oahu ICESat-2 shift, then plot Fig. 5.
grsl.config.require_files({cfg.wanning.directPairsFile, cfg.oahu.directPairsFile});
grsl.config.ensure_dir(cfg.fig5.outputDir);
W = readtable(cfg.wanning.directPairsFile, 'TextType', 'string');
O = readtable(cfg.oahu.directPairsFile, 'TextType', 'string');
required = {'track','pixel','is2_depth','reference_depth'};
assert(all(ismember(required, W.Properties.VariableNames)), ...
    'Wanning direct-pair schema mismatch.');
assert(all(ismember(required, O.Properties.VariableNames)), ...
    'Oahu direct-pair schema mismatch.');

wReferenceShift = cfg.wanning.referenceWaterSurface - ...
    cfg.wanning.sourceReferenceWaterSurface;
W.reference_depth_source_minus6p6_m = W.reference_depth;
W.reference_depth = W.reference_depth_source_minus6p6_m + wReferenceShift;
W.residual = W.is2_depth - W.reference_depth;
W.reference_water_surface_m = repmat(cfg.wanning.referenceWaterSurface, height(W), 1);
W.reference_shift_applied_m = repmat(wReferenceShift, height(W), 1);
oahuIs2Shift = -0.4;
O.reference_depth_original_m = O.reference_depth;
O.is2_depth_original_m = O.is2_depth;
O.residual_original_m = O.is2_depth_original_m - O.reference_depth_original_m;
O.is2_depth = O.is2_depth_original_m + oahuIs2Shift;
O.residual = O.is2_depth - O.reference_depth;
O.is2_shift_applied_m = repmat(oahuIs2Shift, height(O), 1);
assert(abs(wReferenceShift - 0.5) < 1e-12, ...
    'The Wanning -6.6 m to -6.1 m reference update must equal +0.5 m.');
assert(height(W) == 133 && numel(unique(W.track)) == 2, ...
    'Wanning direct-pair identity changed.');
assert(height(O) == 2218 && numel(unique(O.track)) == 31, ...
    'Oahu direct-pair identity changed.');

sites = struct('Name', {'Wanning','Oahu'}, ...
    'ReferenceLabel', {'Shipborne MBES','Airborne Lidar Bathymetry'}, ...
    'Pairs', {W,O});
metricsRows = cell(2, 1);
binRows = cell(2, 1);
for i = 1:2
    T = sites(i).Pairs;
    m = grsl.metrics.direct_pair_metrics(T.reference_depth, T.is2_depth);
    sites(i).Metrics = m;
    metricsRows{i} = table(string(sites(i).Name), height(T), ...
        numel(unique(T.track)), m.Bias_m, m.RMSE_m, m.MAE_m, ...
        m.MedianBias_m, m.P90AbsoluteError_m, m.OLS_R2, ...
        m.Predictive_R2, m.Slope, m.Intercept, ...
        string(sites(i).ReferenceLabel), 'VariableNames', { ...
        'Site','N','TrackN','Bias_m','RMSE_m','MAE_m','MedianBias_m', ...
        'P90AbsoluteError_m','OLS_R2','Predictive_R2','OLS_Slope', ...
        'OLS_Intercept_m','IndependentReference'});
    bins = grsl.metrics.compute_depth_bins(T.reference_depth, T.is2_depth, ...
        0:2:30, cfg.minReliableN);
    bins.Site = repmat(string(sites(i).Name), height(bins), 1);
    binRows{i} = movevars(bins, 'Site', 'Before', 1);
end
metricsTable = vertcat(metricsRows{:});
binsTable = vertcat(binRows{:});
stem = 'fig5_two_column_oahu_is2_minus0p4';
writetable(metricsTable, fullfile(cfg.fig5.outputDir, [stem '_overall_metrics.csv']));
writetable(binsTable, fullfile(cfg.fig5.outputDir, [stem '_2m_bins.csv']));
writetable(W, fullfile(cfg.fig5.outputDir, [stem '_pairs_wanning_minus6p1.csv']));
writetable(O, fullfile(cfg.fig5.outputDir, [stem '_pairs_oahu_is2_minus0p4.csv']));

fig = figure('Color', 'white', 'Units', 'pixels', 'Position', [40 40 1180 980]);
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for i = 1:2
    siteBins = binsTable(binsTable.Site == string(sites(i).Name), :);
    grsl.fig5.plot_site_row(layout, sites(i), siteBins);
end
title(layout, 'Direct comparison of ICESat-2 and independent bathymetric references', ...
    'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold');
subtitle(layout, ['Wanning: MBES updated to the -6.1 m water-surface datum. ' ...
    'Oahu: ICESat-2 depths shifted by -0.4 m.'], ...
    'FontName', 'Times New Roman', 'FontSize', 11);
pngPath = fullfile(cfg.fig5.outputDir, [stem '.png']);
figPath = fullfile(cfg.fig5.outputDir, [stem '.fig']);
savefig(fig, figPath);
grsl.io.export_png(fig, pngPath, 600);
close(fig);

notesPath = fullfile(cfg.fig5.outputDir, [stem '_notes.txt']);
fid = fopen(notesPath, 'w');
assert(fid >= 0, 'Cannot create Fig. 5 notes file.');
fprintf(fid, 'Bias and residual = ICESat-2 depth minus independent-reference depth.\n');
fprintf(fid, 'Wanning source pairs used -6.6 m and were shifted by +0.5 m to the current -6.1 m reference datum.\n');
fprintf(fid, 'Oahu ALB references are unchanged; ICESat-2 depths were shifted by -0.4 m.\n');
fprintf(fid, 'No spatial rematching, model fitting, SDB inference, or filtering was applied.\n');
fclose(fid);
outputs = struct('MetricsFile', fullfile(cfg.fig5.outputDir, ...
    [stem '_overall_metrics.csv']), 'BinsFile', fullfile(cfg.fig5.outputDir, ...
    [stem '_2m_bins.csv']), 'PngFile', pngPath, 'FigFile', figPath);
end
