function outputs = plot_fig1_revised_with_independent_validation(cfg)
% Plot study areas, ICESat-2 tracks, and independent-validation coverage.
if nargin < 1
    cfg = grsl_config();
end
grsl.config.add_repository_paths();
outputs = grsl.fig1.generate(cfg);
end
