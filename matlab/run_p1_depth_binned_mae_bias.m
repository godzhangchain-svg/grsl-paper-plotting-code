function outputs = run_p1_depth_binned_mae_bias(cfg)
% Recompute the 2 m MAE/Bias figure from the latest FCNN pair tables.
if nargin < 1
    cfg = grsl_config();
end
grsl.config.add_repository_paths();
outputs = grsl.fig4.generate(cfg);
end
