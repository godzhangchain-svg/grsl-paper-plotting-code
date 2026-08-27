function result = run_wanning_fcnn_sdb_validation(cfg)
% Apply the selected Wanning FCNN ensemble and validate it against wncz1.
if nargin < 1
    cfg = grsl_config();
end
grsl.config.add_repository_paths();
result = grsl.wanning.infer_and_validate(cfg);
end
