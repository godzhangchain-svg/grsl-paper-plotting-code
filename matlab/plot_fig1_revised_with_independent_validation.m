%% Revised GRSL Fig. 1: study areas, ICESat-2 tracks, and independent validation samples
% Standalone consolidated replacement candidate for the original
% plot_study_area.m and plot_study_area_hawaii.m scripts.
%
% Wanning independent reference: wncz1.tif only.
% Oahu independent reference: the exact ALB sampling/filtering rules used
% by paper_all_figures_v6_boundaries.m.

clear; clc; close all;
warning('off', 'map:removing:map2pix');

%% Paths and locked settings
outDir = fileparts(mfilename('fullpath'));
outPng = fullfile(outDir, 'fig1_revised_with_independent_validation.png');
outFig = fullfile(outDir, 'fig1_revised_with_independent_validation.fig');

wanning.baseMap = 'D:\MATLKAB\三月\多波束验证\wanning730.tif';
wanning.trackFolder = 'D:\MATLKAB\三月\多波束验证\kml文件';
wanning.referenceFile = 'D:\MATLKAB\三月\多波束验证\wncz1.tif';
wanning.sdbFile = 'D:\MATLKAB\三月\多波束验证\wanningBathy.tif';
wanning.lonLim = [110.359, 110.627];
wanning.latLim = [18.601, 18.802];
wanning.regionLonLim = [98.0, 125.0];
wanning.regionLatLim = [0.0, 25.0];
wanning.studyLon = 110.5;
wanning.studyLat = 18.7;
wanning.waterSurface = -6.6;
wanning.minDepth = 0;
wanning.maxReferenceDepth = 100;
wanning.plotMaxDepth = 35;

oahu.baseMap = 'D:\baiduyunpan\data_clckd\hawaii\hawaiipart.tif';
oahu.trackFolder = 'D:\baiduyunpan\data_clckd\hawaii\处理后数据';
oahu.referenceFile = 'D:\baiduyunpan\data_clckd\hawaii\hawaii_laz_bathy.mat';
oahu.sdbFile = 'D:\baiduyunpan\data_clckd\hawaii\HAWAIIBathy2.tif';
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
oahu.randomSeed = 2026;

fontName = 'Times New Roman';
trackColor = [0.90 0.12 0.12];
referenceColor = [0.00 0.72 0.86];
referenceEdgeColor = [0.00 0.34 0.48];

%% Extract the exact independent-validation sample positions
fprintf('Extracting Wanning validation positions from wncz1.tif only...\n');
[wanLat, wanLon] = extract_wanning_validation_positions(wanning);
fprintf('Wanning displayed validation samples: N=%d\n', numel(wanLat));

fprintf('Extracting Oahu validation positions using production rules...\n');
[oahLat, oahLon] = extract_oahu_validation_positions(oahu);
fprintf('Oahu displayed validation samples: N=%d\n', numel(oahLat));

if numel(wanLat) ~= 10178
    warning('Expected Wanning N=10178 but obtained N=%d.', numel(wanLat));
end
if numel(oahLat) ~= 210273
    warning('Expected Oahu N=210273 but obtained N=%d.', numel(oahLat));
end

%% Figure layout: regional locations and independent-validation detail maps
fig = figure('Color', 'white', 'Position', [40 40 1500 1200], ...
    'PaperPositionMode', 'auto', 'Visible', 'off');

% All four panel frames are equal-sized and slightly wider than square in
% physical pixels (the figure itself is 1500-by-1200 pixels).
panelAspect = 1.10;
panelWidth = 0.340;
panelHeight = panelWidth * 1500 / 1200 / panelAspect;
posA = [0.095 0.515 panelWidth panelHeight];
posB = [0.495 0.515 panelWidth panelHeight];
posC = [0.095 0.080 panelWidth panelHeight];
posD = [0.495 0.080 panelWidth panelHeight];

% (a) Regional location of Wanning on the original online land-cover map
axA = geoaxes(fig, 'Position', posA);
plot_regional_location(axA, wanning.regionLonLim, wanning.regionLatLim, ...
    wanning.studyLon, wanning.studyLat, 'Wanning', fontName);

% (b) Wanning detail with exact independent-validation samples
axB = axes(fig, 'Position', posB);
plot_detail_panel(axB, wanning.baseMap, wanning.lonLim, wanning.latLim, ...
    wanning.trackFolder, 1, wanLat, wanLon, ...
    'MBES validation', ...
    fontName, trackColor, referenceColor, referenceEdgeColor, 5, true);

% (c) Regional location of Oahu on the original online land-cover map
axC = geoaxes(fig, 'Position', posC);
plot_regional_location(axC, oahu.regionLonLim, oahu.regionLatLim, ...
    oahu.studyLon, oahu.studyLat, 'Oahu', fontName);

% (d) Oahu detail with exact independent-validation samples
axD = axes(fig, 'Position', posD);
plot_detail_panel(axD, oahu.baseMap, oahu.lonLim, oahu.latLim, ...
    oahu.trackFolder, 15, oahLat, oahLon, ...
    'ALB validation', ...
    fontName, trackColor, referenceColor, referenceEdgeColor, 5, false);

% Figure-level labels give (a)-(d) exactly the same relative position,
% independent of whether the panel uses geographic or Cartesian axes.
panelLabelFontSize = 28;
add_figure_panel_label(fig, posA, '(a)', fontName, 'k', panelLabelFontSize);
add_figure_panel_label(fig, posB, '(b)', fontName, 'w', panelLabelFontSize);
add_figure_panel_label(fig, posC, '(c)', fontName, 'k', panelLabelFontSize);
add_figure_panel_label(fig, posD, '(d)', fontName, 'w', panelLabelFontSize);

print(fig, outPng, '-dpng', '-r350');
try
    savefig(fig, outFig);
catch ME
    warning('Could not save FIG file: %s', ME.message);
end
fprintf('Revised Fig. 1 saved: %s\n', outPng);

%% ------------------------------------------------------------------------
function plot_regional_location(ax, lonLim, latLim, studyLon, studyLat, ...
        siteName, fontName)
    cla(ax);
    geolimits(ax, latLim, lonLim);
    geobasemap(ax, 'landcover');
    hold(ax, 'on');

    geoscatter(ax, studyLat, studyLon, 70, [0.90 0.05 0.05], 'filled', ...
        'MarkerEdgeColor', 'k', 'LineWidth', 1.0);

    if studyLon > 0
        siteLabelLat = studyLat + 0.5;
        siteLabelLon = studyLon + 1.5;
    else
        siteLabelLat = studyLat + 0.5;
        siteLabelLon = studyLon + 0.2;
    end
    text(ax, siteLabelLat, siteLabelLon, siteName, ...
        'FontName', fontName, 'FontSize', 17, 'FontWeight', 'bold', ...
        'Color', [0.85 0.00 0.00]);

    ax.LongitudeLabel.String = '';
    ax.LatitudeLabel.String = '';
    ax.FontName = fontName;
    ax.FontSize = 16;
    hold(ax, 'off');
end

function plot_detail_panel(ax, baseMapFile, lonLim, latLim, ...
        trackFolder, trackStride, sampleLat, sampleLon, ...
        referenceLegendText, fontName, trackColor, ...
        referenceColor, referenceEdgeColor, scaleKm, drawBoundary)
    axes(ax);
    cla(ax);
    [rgb, imageLonLim, imageLatDir] = stretch_rgb( ...
        baseMapFile, lonLim, latLim);
    imagesc(ax, imageLonLim, imageLatDir, rgb);
    set(ax, 'YDir', 'normal');
    hold(ax, 'on');

    % Dense ALB samples remain translucent below the ICESat-2 tracks.
    % The narrow Wanning MBES swath is drawn last with a dark halo so it
    % remains visible where it overlaps a training track.
    if numel(sampleLat) > 60000
        markerSize = 2.2;
        faceAlpha = 0.10;
        edgeAlpha = 0.02;
    else
        markerSize = 6.5;
        faceAlpha = 0.95;
        edgeAlpha = 0.20;
    end
    if ~drawBoundary
        scatter(ax, sampleLon, sampleLat, markerSize, referenceColor, ...
            'filled', 'MarkerFaceAlpha', faceAlpha, ...
            'MarkerEdgeColor', referenceEdgeColor, ...
            'MarkerEdgeAlpha', edgeAlpha, 'HandleVisibility', 'off');
    end

    plot_kml_tracks(ax, trackFolder, trackStride, trackColor);

    if drawBoundary
        scatter(ax, sampleLon, sampleLat, 12, referenceEdgeColor, ...
            'filled', 'MarkerFaceAlpha', 0.72, ...
            'MarkerEdgeColor', 'none', 'HandleVisibility', 'off');
        scatter(ax, sampleLon, sampleLat, markerSize, referenceColor, ...
            'filled', 'MarkerFaceAlpha', faceAlpha, ...
            'MarkerEdgeColor', 'none', 'HandleVisibility', 'off');

        outline_step = max(1, ceil(numel(sampleLon) / 12000));
        outline_lon = sampleLon(1:outline_step:end);
        outline_lat = sampleLat(1:outline_step:end);
        order = boundary(outline_lon, outline_lat, 0.83);
        plot(ax, outline_lon(order), outline_lat(order), '-', ...
            'Color', referenceEdgeColor, 'LineWidth', 3.0, ...
            'HandleVisibility', 'off');
        plot(ax, outline_lon(order), outline_lat(order), '-', ...
            'Color', referenceColor, 'LineWidth', 1.6, ...
            'HandleVisibility', 'off');
    end

    hTrack = plot(ax, nan, nan, '-', 'Color', trackColor, ...
        'LineWidth', 1.4);
    hReference = plot(ax, nan, nan, 'o', ...
        'MarkerFaceColor', referenceColor, ...
        'MarkerEdgeColor', referenceEdgeColor, ...
        'MarkerSize', 6, 'LineStyle', 'none');
    legend(ax, [hTrack hReference], ...
        {'ICESat-2 tracks', referenceLegendText}, ...
        'Location', 'southwest', 'FontName', fontName, ...
        'FontSize', 16, 'Box', 'on', 'Color', [1 1 1]);

    % Restrict the displayed map to the portion actually covered by the
    % cropped Sentinel-2 image so that raster-edge gaps do not appear as
    % blank bands inside the axes.
    displayLonLim = sort(imageLonLim);
    displayLatLim = sort(imageLatDir);
    % Preserve an approximately equal ground scale in x and y.  When the
    % source raster is wider than the common panel shape, crop only the
    % excess ocean on the right rather than squeezing the whole raster.
    panelMapAspect = 1.10;
    targetLonSpan = panelMapAspect * diff(displayLatLim) / ...
        cosd(mean(displayLatLim));
    if targetLonSpan < diff(displayLonLim)
        displayLonLim(2) = displayLonLim(1) + targetLonSpan;
    end
    xlim(ax, displayLonLim);
    ylim(ax, displayLatLim);
    if mean(displayLonLim) < 0
        xticks(ax, -157.9:0.1:-157.5);
        yticks(ax, 21.2:0.1:21.5);
    else
        xticks(ax, 110.40:0.05:110.60);
        yticks(ax, 18.65:0.05:18.80);
    end
    axis(ax, 'normal');
    % Fill the same panel frame as the regional maps.  The right-side crop
    % above controls the map extent, so no additional plot-box compression
    % is applied here.
    box(ax, 'on');
    set(ax, 'FontName', fontName, 'FontSize', 16, ...
        'LineWidth', 1.2, 'TickLength', [0 0], ...
        'XTickLabelRotation', 0);
    format_geo_ticks(ax, mean(displayLonLim) < 0);

    add_scale_bar(ax, scaleKm, mean(displayLatLim), fontName);
    hold(ax, 'off');
end

function [rgb, imageLonLim, imageLatDir] = ...
        stretch_rgb(filename, lonLim, latLim)
    [img, R] = geotiffread(filename);

    lonCorners = lonLim([1 2 2 1]);
    latCorners = latLim([1 1 2 2]);
    isProjected = isa(R, 'map.rasterref.MapCellsReference');
    if isProjected
        crs = R.ProjectedCRS;
        [xCorners, yCorners] = projfwd(crs, latCorners, lonCorners);
        [colIntrinsic, rowIntrinsic] = worldToIntrinsic( ...
            R, xCorners, yCorners);
    else
        [colIntrinsic, rowIntrinsic] = geographicToIntrinsic( ...
            R, latCorners, lonCorners);
    end

    rowStart = max(1, floor(min(rowIntrinsic)) - 1);
    rowEnd = min(size(img,1), ceil(max(rowIntrinsic)) + 1);
    colStart = max(1, floor(min(colIntrinsic)) - 1);
    colEnd = min(size(img,2), ceil(max(colIntrinsic)) + 1);
    assert(rowStart <= rowEnd && colStart <= colEnd, ...
        'Requested map window does not overlap %s.', filename);
    img = img(rowStart:rowEnd, colStart:colEnd, :);

    midRow = (rowStart + rowEnd)/2;
    midCol = (colStart + colEnd)/2;
    if isProjected
        [xEdge, yEdge] = intrinsicToWorld( ...
            R, [colStart colEnd], [midRow midRow]);
        [~, lonEdge] = projinv(crs, xEdge, yEdge);
        [xEdge, yEdge] = intrinsicToWorld( ...
            R, [midCol midCol], [rowStart rowEnd]);
        [latEdge, ~] = projinv(crs, xEdge, yEdge);
    else
        [~, lonEdge] = intrinsicToGeographic( ...
            R, [colStart colEnd], [midRow midRow]);
        [latEdge, ~] = intrinsicToGeographic( ...
            R, [midCol midCol], [rowStart rowEnd]);
    end
    imageLonLim = [lonEdge(1), lonEdge(2)];
    imageLatDir = [latEdge(1), latEdge(2)];

    if size(img, 3) >= 3
        rgb = double(img(:, :, 1:3));
        for ch = 1:3
            band = rgb(:, :, ch);
            valid = band(isfinite(band) & band > 0);
            if isempty(valid)
                continue;
            end
            low = prctile(valid, 2);
            high = prctile(valid, 98);
            if high > low
                rgb(:, :, ch) = (band - low) ./ (high - low);
            end
        end
    else
        band = double(img(:, :, 1));
        valid = band(isfinite(band) & band > 0);
        low = prctile(valid, 2);
        high = prctile(valid, 98);
        band = (band - low) ./ (high - low);
        rgb = repmat(band, 1, 1, 3);
    end
    rgb = max(0, min(1, rgb));
end

function plot_kml_tracks(ax, folder, stride, color)
    files = dir(fullfile(folder, '*.kml'));
    for i = 1:stride:numel(files)
        txt = fileread(fullfile(files(i).folder, files(i).name));
        tokens = regexp(txt, '<coordinates>(.*?)</coordinates>', 'tokens');
        if isempty(tokens)
            continue;
        end
        parts = strsplit(strtrim(tokens{1}{1}));
        lon = nan(numel(parts), 1);
        lat = nan(numel(parts), 1);
        for j = 1:numel(parts)
            xyz = strsplit(parts{j}, ',');
            if numel(xyz) >= 2
                lon(j) = str2double(xyz{1});
                lat(j) = str2double(xyz{2});
            end
        end
        valid = isfinite(lat) & isfinite(lon);
        if any(valid)
            plot(ax, lon(valid), lat(valid), '-', ...
                'Color', color, 'LineWidth', 0.9, ...
                'HandleVisibility', 'off');
        end
    end
end

function format_geo_ticks(ax, westLongitude)
    xt = get(ax, 'XTick');
    yt = get(ax, 'YTick');
    if westLongitude
        xLabels = arrayfun(@(x) sprintf('%.2f°W', abs(x)), xt, ...
            'UniformOutput', false);
    else
        xLabels = arrayfun(@(x) sprintf('%.2f°E', x), xt, ...
            'UniformOutput', false);
    end
    yLabels = arrayfun(@(y) sprintf('%.2f°N', y), yt, ...
        'UniformOutput', false);
    set(ax, 'XTickLabel', xLabels, 'YTickLabel', yLabels);
end

function add_scale_bar(ax, scaleKm, meanLatitude, fontName)
    xBounds = xlim(ax);
    yBounds = ylim(ax);
    scaleDegrees = scaleKm / (111*cosd(meanLatitude));
    x0 = xBounds(2) - 0.06*diff(xBounds) - scaleDegrees;
    x1 = xBounds(2) - 0.06*diff(xBounds);
    y0 = yBounds(1) + 0.065*diff(yBounds);
    cap = 0.012*diff(yBounds);

    plot(ax, [x0 x1], [y0 y0], '-', 'Color', [0 0 0], 'LineWidth', 5, ...
        'HandleVisibility', 'off');
    plot(ax, [x0 x1], [y0 y0], '-', 'Color', [1 1 1], 'LineWidth', 2.5, ...
        'HandleVisibility', 'off');
    plot(ax, [x0 x0], [y0-cap y0+cap], '-', 'Color', [1 1 1], ...
        'LineWidth', 2.5, 'HandleVisibility', 'off');
    plot(ax, [x1 x1], [y0-cap y0+cap], '-', 'Color', [1 1 1], ...
        'LineWidth', 2.5, 'HandleVisibility', 'off');
    text(ax, mean([x0 x1]), y0 + 0.026*diff(yBounds), ...
        sprintf('%d km', scaleKm), 'HorizontalAlignment', 'center', ...
        'Color', 'white', 'FontName', fontName, 'FontSize', 16, ...
        'FontWeight', 'bold');
end

function add_north_arrow(ax, fontName)
    xBounds = xlim(ax);
    yBounds = ylim(ax);
    x = xBounds(2) - 0.055*diff(xBounds);
    y0 = yBounds(2) - 0.15*diff(yBounds);
    dy = 0.065*diff(yBounds);
    quiver(ax, x, y0, 0, dy, 0, 'Color', 'white', ...
        'LineWidth', 2, 'MaxHeadSize', 0.75, ...
        'HandleVisibility', 'off');
    text(ax, x, y0 + 1.22*dy, 'N', 'HorizontalAlignment', 'center', ...
        'Color', 'white', 'FontName', fontName, 'FontSize', 11, ...
        'FontWeight', 'bold', 'BackgroundColor', [0 0 0 0.35]);
end

function add_figure_panel_label(fig, panelPosition, label, fontName, ...
        labelColor, fontSize)
    labelWidth = 0.070;
    labelHeight = 0.065;
    insetX = 0.018;
    insetY = 0.004;
    labelPosition = [ ...
        panelPosition(1) + panelPosition(3) - labelWidth - insetX, ...
        panelPosition(2) + panelPosition(4) - labelHeight - insetY, ...
        labelWidth, labelHeight];
    annotation(fig, 'textbox', labelPosition, 'String', label, ...
        'LineStyle', 'none', 'FitBoxToText', 'off', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontName', fontName, 'FontSize', fontSize, 'FontWeight', 'bold', ...
        'Color', labelColor, 'Margin', 0);
end

%% ------------------------------------------------------------------------
function [validationLat, validationLon] = ...
        extract_wanning_validation_positions(cfg)
    [bottomElevation, Rref] = geotiffread(cfg.referenceFile);
    [sdb, Rsdb] = geotiffread(cfg.sdbFile);

    referenceDepth = cfg.waterSurface - double(bottomElevation);
    referenceDepth(referenceDepth > cfg.maxReferenceDepth | ...
        referenceDepth <= 0) = NaN;
    sdb = double(sdb);
    sdb(sdb < 0) = NaN;

    isProjectedRef = isa(Rref, 'map.rasterref.MapCellsReference');
    isProjectedSdb = isa(Rsdb, 'map.rasterref.MapCellsReference');
    if isProjectedRef
        crsRef = Rref.ProjectedCRS;
    else
        crsRef = Rref.GeographicCRS;
    end
    if isProjectedSdb
        crsSdb = Rsdb.ProjectedCRS;
    else
        crsSdb = Rsdb.GeographicCRS;
    end
    hasRefCRS = ~isempty(crsRef);
    hasSdbCRS = ~isempty(crsSdb);
    sameCRS = hasRefCRS && hasSdbCRS && strcmp(crsRef.Name, crsSdb.Name);
    if hasSdbCRS
        targetCRS = crsSdb;
    elseif hasRefCRS
        targetCRS = crsRef;
    else
        targetCRS = [];
    end

    if ~hasRefCRS && ~hasSdbCRS
        lonOverlap = [max(Rref.LongitudeLimits(1), Rsdb.LongitudeLimits(1)), ...
            min(Rref.LongitudeLimits(2), Rsdb.LongitudeLimits(2))];
        latOverlap = [max(Rref.LatitudeLimits(1), Rsdb.LatitudeLimits(1)), ...
            min(Rref.LatitudeLimits(2), Rsdb.LatitudeLimits(2))];
    else
        [refLat, refLon] = reference_corners(Rref, isProjectedRef, crsRef);
        [sdbLat, sdbLon] = reference_corners(Rsdb, isProjectedSdb, crsSdb);
        if sameCRS && isProjectedRef && isProjectedSdb
            refX = Rref.XWorldLimits([1 2 2 1]);
            refY = Rref.YWorldLimits([1 1 2 2]);
            sdbX = Rsdb.XWorldLimits([1 2 2 1]);
            sdbY = Rsdb.YWorldLimits([1 1 2 2]);
        else
            [refX, refY] = projfwd(targetCRS, refLat, refLon);
            [sdbX, sdbY] = projfwd(targetCRS, sdbLat, sdbLon);
        end
        xOverlap = [max(min(refX), min(sdbX)), ...
            min(max(refX), max(sdbX))];
        yOverlap = [max(min(refY), min(sdbY)), ...
            min(max(refY), max(sdbY))];
        [cornerLat, cornerLon] = projinv(targetCRS, ...
            xOverlap([1 2 2 1]), yOverlap([1 1 2 2]));
        lonOverlap = [min(cornerLon), max(cornerLon)];
        latOverlap = [min(cornerLat), max(cornerLat)];
    end

    [refCrop, refXVec, refYVec] = crop_raster( ...
        referenceDepth, Rref, latOverlap, lonOverlap, ...
        isProjectedRef, crsRef);
    [sdbCrop, sdbXVec, sdbYVec] = crop_raster( ...
        sdb, Rsdb, latOverlap, lonOverlap, isProjectedSdb, crsSdb);

    [XqSdb, YqSdb] = meshgrid(sdbXVec, sdbYVec);
    if sameCRS || (~hasRefCRS && ~hasSdbCRS)
        XqRef = XqSdb;
        YqRef = YqSdb;
    else
        if isProjectedSdb
            [latQ, lonQ] = projinv(crsSdb, XqSdb, YqSdb);
        else
            lonQ = XqSdb;
            latQ = YqSdb;
        end
        if isProjectedRef
            [XqRef, YqRef] = projfwd(crsRef, latQ, lonQ);
        else
            XqRef = lonQ;
            YqRef = latQ;
        end
    end

    [Xref, Yref] = meshgrid(refXVec, refYVec);
    resampledReference = interp2(Xref, Yref, refCrop, ...
        XqRef, YqRef, 'linear', NaN);
    resampledReference(resampledReference <= 0) = NaN;

    sdbVector = sdbCrop(:);
    refVector = resampledReference(:);
    xVector = XqSdb(:);
    yVector = YqSdb(:);
    finite = isfinite(sdbVector) & isfinite(refVector) & ...
        sdbVector > 0 & refVector > 0;
    sdbVector = sdbVector(finite);
    refVector = refVector(finite);
    xVector = xVector(finite);
    yVector = yVector(finite);

    selected = refVector >= cfg.minDepth & sdbVector >= cfg.minDepth & ...
        refVector <= cfg.plotMaxDepth & sdbVector <= cfg.plotMaxDepth;
    xVector = xVector(selected);
    yVector = yVector(selected);
    if isProjectedSdb
        [validationLat, validationLon] = projinv(crsSdb, xVector, yVector);
    else
        validationLon = xVector;
        validationLat = yVector;
    end
end

function [validationLat, validationLon] = ...
        extract_oahu_validation_positions(cfg)
    [sdbGrid, Rsdb] = geotiffread(cfg.sdbFile);
    sdbGrid = double(sdbGrid);
    [nRows, nCols] = size(sdbGrid);

    d = load(cfg.referenceFile);
    lat = d.lat(:);
    lon = d.lon(:);
    depth = d.depth(:);

    validDepth = depth > 0 & depth <= cfg.maxReferenceDepth;
    lat = lat(validDepth);
    lon = lon(validDepth);
    depth = depth(validDepth);

    rng(cfg.randomSeed);
    nPoints = numel(depth);
    nSample = round(nPoints*cfg.sampleRatio);
    selection = randperm(nPoints, nSample);
    lat = lat(selection);
    lon = lon(selection);
    depth = depth(selection);

    if isa(Rsdb, 'map.rasterref.MapCellsReference')
        crsSdb = Rsdb.ProjectedCRS;
        [x, y] = projfwd(crsSdb, lat, lon);
        col = floor((x - Rsdb.XWorldLimits(1)) / ...
            Rsdb.CellExtentInWorldX) + 1;
        row = floor((Rsdb.YWorldLimits(2) - y) / ...
            Rsdb.CellExtentInWorldY) + 1;
    else
        col = floor((lon - Rsdb.LongitudeLimits(1)) / ...
            Rsdb.CellExtentInLongitude) + 1;
        row = floor((Rsdb.LatitudeLimits(2) - lat) / ...
            Rsdb.CellExtentInLatitude) + 1;
    end

    inBounds = row >= 1 & row <= nRows & col >= 1 & col <= nCols;
    row = row(inBounds);
    col = col(inBounds);
    lat = lat(inBounds);
    lon = lon(inBounds);
    depth = depth(inBounds);

    linearIndex = sub2ind([nRows nCols], row, col);
    sdbAtPoint = sdbGrid(linearIndex);
    validPair = isfinite(sdbAtPoint) & sdbAtPoint > 0 & isfinite(depth);
    sdbAtPoint = sdbAtPoint(validPair);
    depth = depth(validPair);
    lat = lat(validPair);
    lon = lon(validPair);

    seaSurface = (sdbAtPoint - depth) > 12;
    sdbAtPoint = sdbAtPoint(~seaSurface);
    depth = depth(~seaSurface);
    lat = lat(~seaSurface);
    lon = lon(~seaSurface);

    selected = depth >= cfg.minDepth & sdbAtPoint >= cfg.minDepth & ...
        depth <= cfg.plotMaxDepth & sdbAtPoint <= cfg.plotMaxDepth;
    validationLat = lat(selected);
    validationLon = lon(selected);
end

function [lat, lon] = reference_corners(R, isProjected, crs)
    if isProjected
        [lat, lon] = projinv(crs, ...
            R.XWorldLimits([1 2 2 1]), R.YWorldLimits([1 1 2 2]));
    else
        lon = R.LongitudeLimits([1 2 2 1]);
        lat = R.LatitudeLimits([1 1 2 2]);
    end
end

function [crop, xVec, yVec] = crop_raster(data, R, latOverlap, ...
        lonOverlap, isProjected, crs)
    if isProjected
        [overlapX, overlapY] = projfwd(crs, latOverlap, lonOverlap);
        xOverlap = [min(overlapX), max(overlapX)];
        yOverlap = [min(overlapY), max(overlapY)];
        [c1, r1] = worldToIntrinsic(R, xOverlap(1), yOverlap(2));
        [c2, r2] = worldToIntrinsic(R, xOverlap(2), yOverlap(1));
    else
        latCrop = [max(latOverlap(1), R.LatitudeLimits(1)), ...
            min(latOverlap(2), R.LatitudeLimits(2))];
        lonCrop = [max(lonOverlap(1), R.LongitudeLimits(1)), ...
            min(lonOverlap(2), R.LongitudeLimits(2))];
        [c1, r1] = geographicToIntrinsic(R, latCrop(2), lonCrop(1));
        [c2, r2] = geographicToIntrinsic(R, latCrop(1), lonCrop(2));
    end

    rowIndex = round(sort([r1 r2]));
    colIndex = round(sort([c1 c2]));
    rowIndex(1) = max(1, rowIndex(1));
    rowIndex(2) = min(size(data, 1), rowIndex(2));
    colIndex(1) = max(1, colIndex(1));
    colIndex(2) = min(size(data, 2), colIndex(2));

    crop = double(data(rowIndex(1):rowIndex(2), ...
        colIndex(1):colIndex(2), 1));
    if isProjected
        xFull = linspace(R.XWorldLimits(1) + R.CellExtentInWorldX/2, ...
            R.XWorldLimits(2) - R.CellExtentInWorldX/2, size(data, 2));
        yFull = linspace(R.YWorldLimits(2) - R.CellExtentInWorldY/2, ...
            R.YWorldLimits(1) + R.CellExtentInWorldY/2, size(data, 1));
    else
        xFull = linspace(R.LongitudeLimits(1) + ...
            R.CellExtentInLongitude/2, ...
            R.LongitudeLimits(2) - R.CellExtentInLongitude/2, ...
            size(data, 2));
        yFull = linspace(R.LatitudeLimits(2) - ...
            R.CellExtentInLatitude/2, ...
            R.LatitudeLimits(1) + R.CellExtentInLatitude/2, ...
            size(data, 1));
    end
    xVec = xFull(colIndex(1):colIndex(2));
    yVec = yFull(rowIndex(1):rowIndex(2));
end
