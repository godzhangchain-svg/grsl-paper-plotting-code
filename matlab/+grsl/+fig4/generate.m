function outputs = generate(cfg)
% Build the two-site 2 m reference-depth-binned MAE/Bias figure.
files = {cfg.wanning.internalPairsFile, cfg.wanning.independentStatPairsFile, ...
    cfg.oahu.internalPairsFile, cfg.oahu.independentStatPairsFile};
grsl.config.require_files(files);
grsl.config.ensure_dir(cfg.fig4.outputDir);

wi = readtable(cfg.wanning.internalPairsFile);
wx = readtable(cfg.wanning.independentStatPairsFile);
oi = readtable(cfg.oahu.internalPairsFile);
ox = readtable(cfg.oahu.independentStatPairsFile);
wanSelf = grsl.metrics.compute_depth_bins(wi.ReferenceDepth_m, ...
    wi.FCNNPrediction_m, 0:2:36, cfg.minReliableN);
wanIndependent = grsl.metrics.compute_depth_bins(wx.ReferenceDepth_m, ...
    wx.SDBPrediction_m, 0:2:36, cfg.minReliableN);
oahuSelf = grsl.metrics.compute_depth_bins(oi.ReferenceDepth_m, ...
    oi.PredictedDepth_m, 0:2:56, cfg.minReliableN);
oahuIndependent = grsl.metrics.compute_depth_bins(ox.ReferenceDepth_m, ...
    ox.PredictedDepth_m, 0:2:56, cfg.minReliableN);
wanSelf.Site = repmat("Wanning", height(wanSelf), 1);
wanSelf.Validation = repmat("Internal Validation", height(wanSelf), 1);
wanIndependent.Site = repmat("Wanning", height(wanIndependent), 1);
wanIndependent.Validation = repmat("Independent Validation", height(wanIndependent), 1);
oahuSelf.Site = repmat("Oahu", height(oahuSelf), 1);
oahuSelf.Validation = repmat("Internal Validation", height(oahuSelf), 1);
oahuIndependent.Site = repmat("Oahu", height(oahuIndependent), 1);
oahuIndependent.Validation = repmat("Independent Validation", height(oahuIndependent), 1);
tables = {wanSelf, wanIndependent, oahuSelf, oahuIndependent};
for i = 1:numel(tables)
    tables{i} = movevars(tables{i}, {'Site','Validation'}, 'Before', 1);
end
allBins = vertcat(tables{:});
writetable(allBins, fullfile(cfg.fig4.outputDir, 'depth_binned_metrics_2m.csv'));

wP99 = prctile(wi.ReferenceDepth_m, 99);
oP99 = prctile(oi.ReferenceDepth_m, 99);
boundaries = table(["Wanning";"Oahu"], ...
    [cfg.wanning.hMax;cfg.oahu.hMax], [wP99;oP99], ...
    'VariableNames', {'Site','Hmax_m','Dtrain99_m'});
writetable(boundaries, fullfile(cfg.fig4.outputDir, 'boundaries.csv'));

fig = figure('Color', 'white', 'Position', [50 40 1120 850]);
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
grsl.fig4.plot_metric(nexttile(layout), allBins, "Wanning", ...
    'MAE_m', 'MAE (m)', cfg.wanning.hMax, wP99, true);
grsl.fig4.plot_metric(nexttile(layout), allBins, "Oahu", ...
    'MAE_m', 'MAE (m)', cfg.oahu.hMax, oP99, true);
grsl.fig4.plot_metric(nexttile(layout), allBins, "Wanning", ...
    'Bias_m', 'Bias (m)', cfg.wanning.hMax, wP99, false);
grsl.fig4.plot_metric(nexttile(layout), allBins, "Oahu", ...
    'Bias_m', 'Bias (m)', cfg.oahu.hMax, oP99, false);
title(layout, 'Depth-binned internal and independent validation', ...
    'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold');
stem = fullfile(cfg.fig4.outputDir, 'combined_depth_binned_mae_bias_2m');
grsl.io.export_png(fig, [stem '.png'], 600);
savefig(fig, [stem '.fig']);
close(fig);
outputs = struct('BinsFile', fullfile(cfg.fig4.outputDir, ...
    'depth_binned_metrics_2m.csv'), 'BoundariesFile', ...
    fullfile(cfg.fig4.outputDir, 'boundaries.csv'), 'PngFile', [stem '.png']);
end
