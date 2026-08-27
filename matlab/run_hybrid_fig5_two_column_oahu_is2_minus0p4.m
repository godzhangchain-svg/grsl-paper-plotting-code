function outputs = run_hybrid_fig5_two_column_oahu_is2_minus0p4(cfg)
% Build the corrected direct-reference comparison used for revised Fig. 5.
if nargin < 1
    cfg = grsl_config();
end
grsl.config.add_repository_paths();
outputs = grsl.fig5.generate(cfg);
end
