function outputs = run_current_fig3_depth_binned_rmse_bias_2m(cfg)
% Recompute the current two-site 2 m depth-binned RMSE/Bias figure.
if nargin < 1
    cfg = grsl_config();
end
grsl.config.add_repository_paths();
outputs = grsl.fig3.generate_depth_binned_rmse_bias_2m(cfg);
end
