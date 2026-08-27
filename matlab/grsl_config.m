function cfg = grsl_config(dataRoot, outputRoot)
% Build the portable configuration used by all public workflows.
if nargin < 1 || isempty(dataRoot)
    dataRoot = getenv('GRSL_DATA_ROOT');
end
if nargin < 2 || isempty(outputRoot)
    outputRoot = getenv('GRSL_OUTPUT_ROOT');
end
assert(~isempty(dataRoot), ...
    'Provide dataRoot or define the GRSL_DATA_ROOT environment variable.');
if isempty(outputRoot)
    outputRoot = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'outputs');
end

cfg.dataRoot = char(dataRoot);
cfg.outputRoot = char(outputRoot);
cfg.randomSeed = 2026;
cfg.nFolds = 5;
cfg.minReliableN = 5;

cfg.wanning.hMax = 18.78;
cfg.wanning.trainingWaterSurface = -7.1;
cfg.wanning.referenceWaterSurface = -6.1;
cfg.wanning.sourceReferenceWaterSurface = -6.6;
cfg.wanning.trainingSatelliteFile = fullfile(dataRoot, 'wanning', 'wanning731.tif');
cfg.wanning.fig1BaseMapFile = fullfile(dataRoot, 'wanning', 'wanning730.tif');
cfg.wanning.referenceFile = fullfile(dataRoot, 'wanning', 'wncz1.tif');
cfg.wanning.trackMatFolder = fullfile(dataRoot, 'wanning', 'icesat2_mat');
cfg.wanning.trackKmlFolder = fullfile(dataRoot, 'wanning', 'icesat2_kml');
cfg.wanning.outputDir = fullfile(outputRoot, 'wanning_fcnn');
cfg.wanning.modelFile = fullfile(cfg.wanning.outputDir, 'selected_fcnn_models.mat');
cfg.wanning.sdbFile = fullfile(cfg.wanning.outputDir, 'wanning731_fcnn_sdb.tif');
cfg.wanning.internalPairsFile = fullfile(cfg.wanning.outputDir, ...
    'selected_validation_predictions.csv');
cfg.wanning.independentAllPairsFile = fullfile(cfg.wanning.outputDir, ...
    'wanning_fcnn_independent_all_positive_pairs.csv');
cfg.wanning.independentStatPairsFile = fullfile(cfg.wanning.outputDir, ...
    'wanning_fcnn_independent_stat_pairs_2_35m.csv');
cfg.wanning.directPairsFile = fullfile(dataRoot, 'direct_pairs', ...
    'wanning_is2_reference_pairs_minus6p6.csv');

cfg.oahu.hMax = 21.10;
cfg.oahu.waterSurface = 16.3;
cfg.oahu.trainingSatelliteFile = fullfile(dataRoot, 'oahu', 'hawaiipart.tif');
cfg.oahu.inferenceSatelliteFile = fullfile(dataRoot, 'oahu', 'hawaiipart2.tif');
cfg.oahu.oldMaskFile = fullfile(dataRoot, 'oahu', 'HAWAIIBathy2.tif');
cfg.oahu.albFile = fullfile(dataRoot, 'oahu', 'hawaii_laz_bathy.mat');
cfg.oahu.trackMatFolder = fullfile(dataRoot, 'oahu', 'icesat2_mat');
cfg.oahu.trackKmlFolder = fullfile(dataRoot, 'oahu', 'icesat2_kml');
cfg.oahu.outputDir = fullfile(outputRoot, 'oahu_weighted_fcnn');
cfg.oahu.modelFile = fullfile(cfg.oahu.outputDir, 'oahu_weighted_fcnn_model.mat');
cfg.oahu.sdbFile = fullfile(cfg.oahu.outputDir, 'OahuBathy_weighted_fcnn.tif');
cfg.oahu.internalPairsFile = fullfile(cfg.oahu.outputDir, ...
    'selected_internal_oof_pairs.csv');
cfg.oahu.independentAllPairsFile = fullfile(cfg.oahu.outputDir, ...
    'oahu_independent_all_post_residual_pairs.csv');
cfg.oahu.independentStatPairsFile = fullfile(cfg.oahu.outputDir, ...
    'oahu_independent_stat_pairs.csv');
cfg.oahu.directPairsFile = fullfile(dataRoot, 'direct_pairs', ...
    'oahu_is2_alb_pairs_col7.csv');

cfg.fig1.outputDir = fullfile(outputRoot, 'fig1');
cfg.fig3.outputDir = fullfile(outputRoot, 'fig3');
cfg.fig4.outputDir = fullfile(outputRoot, 'fig4');
cfg.fig5.outputDir = fullfile(outputRoot, 'fig5');
end
