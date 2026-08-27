function outputs = generate_depth_binned_rmse_bias_2m(cfg)
% Build the current two-site 2 m depth-binned RMSE/Bias figure.
files = {cfg.wanning.internalPairsFile, cfg.wanning.independentStatPairsFile, ...
    cfg.oahu.internalPairsFile, cfg.oahu.independentStatPairsFile};
grsl.config.require_files(files);
grsl.config.ensure_dir(cfg.fig3.outputDir);

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

tables = {wanSelf, wanIndependent, oahuSelf, oahuIndependent};
sites = ["Wanning", "Wanning", "Oahu", "Oahu"];
validations = ["Self-Validation", "Independent Validation", ...
    "Self-Validation", "Independent Validation"];
for i = 1:numel(tables)
    tables{i}.Site = repmat(sites(i), height(tables{i}), 1);
    tables{i}.Validation = repmat(validations(i), height(tables{i}), 1);
    tables{i} = movevars(tables{i}, {'Site','Validation'}, 'Before', 1);
end
allBins = vertcat(tables{:});

wP99 = prctile(wi.ReferenceDepth_m, 99);
oP99 = prctile(oi.ReferenceDepth_m, 99);
boundaries = table(["Wanning";"Oahu"], ...
    [cfg.wanning.hMax;cfg.oahu.hMax], [wP99;oP99], ...
    'VariableNames', {'Site','Hmax_m','Dtrain99_m'});

binsFile = fullfile(cfg.fig3.outputDir, 'depth_binned_metrics_2m.csv');
boundariesFile = fullfile(cfg.fig3.outputDir, 'depth_boundaries.csv');
writetable(allBins, binsFile);
writetable(boundaries, boundariesFile);

fig = figure('Color', 'white', 'Position', [80 80 1380 600]);
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
grsl.fig3.plot_depth_binned_rmse_bias(nexttile(layout), allBins, ...
    "Wanning", cfg.wanning.hMax, wP99, 30, '(a) Wanning');
grsl.fig3.plot_depth_binned_rmse_bias(nexttile(layout), allBins, ...
    "Oahu", cfg.oahu.hMax, oP99, 36, '(b) Oahu');
title(layout, 'Depth-binned RMSE and Bias (2 m reference-depth bins)', ...
    'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold');

pngFile = fullfile(cfg.fig3.outputDir, 'fig_both_sites_rmse_bias_2m.png');
grsl.io.export_png(fig, pngFile, 600);
close(fig);
outputs = struct('BinsFile', binsFile, 'BoundariesFile', boundariesFile, ...
    'PngFile', pngFile);
end
