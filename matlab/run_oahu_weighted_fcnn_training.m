function result = run_oahu_weighted_fcnn_training(cfg)
% Tune the Oahu depth-weighted FCNN, infer SDB, and build combined Fig. 3.
if nargin < 1
    cfg = grsl_config();
end
grsl.config.add_repository_paths();
result = grsl.oahu.train_weighted(cfg);
end
