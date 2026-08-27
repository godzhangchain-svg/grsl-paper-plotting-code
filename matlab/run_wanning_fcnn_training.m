function result = run_wanning_fcnn_training(cfg)
% Rebuild the Wanning pool, tune FCNN candidates, and save five fold models.
if nargin < 1
    cfg = grsl_config();
end
grsl.config.add_repository_paths();
result = grsl.wanning.train(cfg);
end
