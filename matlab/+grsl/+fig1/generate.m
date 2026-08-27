function outputs = generate(cfg)
% Generate the four-panel revised study-area map.
required = {cfg.wanning.fig1BaseMapFile, cfg.wanning.referenceFile, ...
    cfg.wanning.sdbFile, cfg.oahu.trainingSatelliteFile, cfg.oahu.albFile, ...
    cfg.oahu.sdbFile};
grsl.config.require_files(required);
assert(isfolder(cfg.wanning.trackKmlFolder), 'Missing Wanning KML folder.');
assert(isfolder(cfg.oahu.trackKmlFolder), 'Missing Oahu KML folder.');
grsl.config.ensure_dir(cfg.fig1.outputDir);

wanning.baseMap = cfg.wanning.fig1BaseMapFile;
wanning.trackFolder = cfg.wanning.trackKmlFolder;
wanning.referenceFile = cfg.wanning.referenceFile;
wanning.sdbFile = cfg.wanning.sdbFile;
wanning.lonLim = [110.359, 110.627];
wanning.latLim = [18.601, 18.802];
wanning.regionLonLim = [98.0, 125.0];
wanning.regionLatLim = [0.0, 25.0];
wanning.studyLon = 110.5;
wanning.studyLat = 18.7;
wanning.waterSurface = cfg.wanning.referenceWaterSurface;
wanning.minDepth = 0;
wanning.maxReferenceDepth = 100;
wanning.plotMaxDepth = 35;

oahu.baseMap = cfg.oahu.trainingSatelliteFile;
oahu.trackFolder = cfg.oahu.trackKmlFolder;
oahu.referenceFile = cfg.oahu.albFile;
oahu.sdbFile = cfg.oahu.sdbFile;
oahu.lonLim = [-157.904, -157.468];
oahu.latLim = [21.171, 21.503];
oahu.regionLonLim = [-162.0, -154.0];
oahu.regionLatLim = [18.0, 24.0];
oahu.studyLon = -157.7;
oahu.studyLat = 21.3;
oahu.minDepth = 0;
oahu.maxReferenceDepth = 60;
oahu.plotMaxDepth = 55;
oahu.sampleRatio = 0.25;
oahu.randomSeed = cfg.randomSeed;

[wanLat, wanLon] = grsl.fig1.extract_wanning_positions(wanning);
[oahLat, oahLon] = grsl.fig1.extract_oahu_positions(oahu);
fontName = 'Times New Roman';
trackColor = [0.90 0.12 0.12];
referenceColor = [0.00 0.72 0.86];
referenceEdgeColor = [0.00 0.34 0.48];
fig = figure('Color', 'white', 'Position', [40 40 1500 1200], ...
    'PaperPositionMode', 'auto', 'Visible', 'off');
panelAspect = 1.10;
panelWidth = 0.340;
panelHeight = panelWidth * 1500 / 1200 / panelAspect;
positions = [0.095 0.515 panelWidth panelHeight; ...
    0.495 0.515 panelWidth panelHeight; ...
    0.095 0.080 panelWidth panelHeight; ...
    0.495 0.080 panelWidth panelHeight];

axA = geoaxes(fig, 'Position', positions(1,:));
grsl.fig1.plot_regional_location(axA, wanning.regionLonLim, ...
    wanning.regionLatLim, wanning.studyLon, wanning.studyLat, 'Wanning', fontName);
axB = axes(fig, 'Position', positions(2,:));
grsl.fig1.plot_detail_panel(axB, wanning.baseMap, wanning.lonLim, ...
    wanning.latLim, wanning.trackFolder, 1, wanLat, wanLon, ...
    'MBES validation', fontName, trackColor, referenceColor, ...
    referenceEdgeColor, 5, true);
axC = geoaxes(fig, 'Position', positions(3,:));
grsl.fig1.plot_regional_location(axC, oahu.regionLonLim, ...
    oahu.regionLatLim, oahu.studyLon, oahu.studyLat, 'Oahu', fontName);
axD = axes(fig, 'Position', positions(4,:));
grsl.fig1.plot_detail_panel(axD, oahu.baseMap, oahu.lonLim, oahu.latLim, ...
    oahu.trackFolder, 15, oahLat, oahLon, 'ALB validation', fontName, ...
    trackColor, referenceColor, referenceEdgeColor, 5, false);
for i = 1:4
    grsl.fig1.add_panel_label(fig, positions(i,:), sprintf('(%c)', 'a' + i - 1), ...
        fontName, i == 1 || i == 3, 28);
end

pngPath = fullfile(cfg.fig1.outputDir, 'fig1_revised_with_independent_validation.png');
figPath = fullfile(cfg.fig1.outputDir, 'fig1_revised_with_independent_validation.fig');
grsl.io.export_png(fig, pngPath, 350);
savefig(fig, figPath);
close(fig);
outputs = struct('WanningValidationN', numel(wanLat), ...
    'OahuValidationN', numel(oahLat), 'PngFile', pngPath, 'FigFile', figPath);
end
