function plot_detail_panel(ax, baseMapFile, lonLim, latLim, ...
        trackFolder, trackStride, sampleLat, sampleLon, referenceLegendText, ...
        fontName, trackColor, referenceColor, referenceEdgeColor, ...
        scaleKm, drawBoundary)
% Plot one detailed Sentinel-2 panel with tracks and validation coverage.
[rgb, imageLonLim, imageLatDir] = ...
    grsl.fig1.stretch_rgb(baseMapFile, lonLim, latLim);
imagesc(ax, imageLonLim, imageLatDir, rgb);
set(ax, 'YDir', 'normal');
hold(ax, 'on');
if numel(sampleLat) > 60000
    markerSize = 2.2; faceAlpha = 0.10; edgeAlpha = 0.02;
else
    markerSize = 6.5; faceAlpha = 0.95; edgeAlpha = 0.20;
end
if ~drawBoundary
    scatter(ax, sampleLon, sampleLat, markerSize, referenceColor, ...
        'filled', 'MarkerFaceAlpha', faceAlpha, ...
        'MarkerEdgeColor', referenceEdgeColor, 'MarkerEdgeAlpha', edgeAlpha, ...
        'HandleVisibility', 'off');
end
grsl.fig1.plot_kml_tracks(ax, trackFolder, trackStride, trackColor);
if drawBoundary
    scatter(ax, sampleLon, sampleLat, 12, referenceEdgeColor, ...
        'filled', 'MarkerFaceAlpha', 0.72, 'MarkerEdgeColor', 'none', ...
        'HandleVisibility', 'off');
    scatter(ax, sampleLon, sampleLat, markerSize, referenceColor, ...
        'filled', 'MarkerFaceAlpha', faceAlpha, 'MarkerEdgeColor', 'none', ...
        'HandleVisibility', 'off');
    step = max(1, ceil(numel(sampleLon) / 12000));
    outlineLon = sampleLon(1:step:end);
    outlineLat = sampleLat(1:step:end);
    order = boundary(outlineLon, outlineLat, 0.83);
    plot(ax, outlineLon(order), outlineLat(order), '-', ...
        'Color', referenceEdgeColor, 'LineWidth', 3.0, 'HandleVisibility', 'off');
    plot(ax, outlineLon(order), outlineLat(order), '-', ...
        'Color', referenceColor, 'LineWidth', 1.6, 'HandleVisibility', 'off');
end
hTrack = plot(ax, nan, nan, '-', 'Color', trackColor, 'LineWidth', 1.4);
hReference = plot(ax, nan, nan, 'o', 'MarkerFaceColor', referenceColor, ...
    'MarkerEdgeColor', referenceEdgeColor, 'MarkerSize', 6, 'LineStyle', 'none');
legend(ax, [hTrack hReference], {'ICESat-2 tracks', referenceLegendText}, ...
    'Location', 'southwest', 'FontName', fontName, 'FontSize', 16, ...
    'Box', 'on', 'Color', [1 1 1]);

displayLonLim = sort(imageLonLim);
displayLatLim = sort(imageLatDir);
targetLonSpan = 1.10 * diff(displayLatLim) / cosd(mean(displayLatLim));
if targetLonSpan < diff(displayLonLim)
    displayLonLim(2) = displayLonLim(1) + targetLonSpan;
end
xlim(ax, displayLonLim); ylim(ax, displayLatLim);
if mean(displayLonLim) < 0
    xticks(ax, -157.9:0.1:-157.5); yticks(ax, 21.2:0.1:21.5);
else
    xticks(ax, 110.40:0.05:110.60); yticks(ax, 18.65:0.05:18.80);
end
axis(ax, 'normal'); box(ax, 'on');
set(ax, 'FontName', fontName, 'FontSize', 16, 'LineWidth', 1.2, ...
    'TickLength', [0 0], 'XTickLabelRotation', 0);
grsl.fig1.format_geo_ticks(ax, mean(displayLonLim) < 0);
grsl.fig1.add_scale_bar(ax, scaleKm, mean(displayLatLim), fontName);
hold(ax, 'off');
end
