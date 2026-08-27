function plot_regional_location(ax, lonLim, latLim, studyLon, studyLat, ...
        siteName, fontName)
% Plot one regional land-cover location panel.
cla(ax);
geolimits(ax, latLim, lonLim);
geobasemap(ax, 'landcover');
hold(ax, 'on');
geoscatter(ax, studyLat, studyLon, 70, [0.90 0.05 0.05], 'filled', ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.0);
if studyLon > 0
    labelLat = studyLat + 0.5; labelLon = studyLon + 1.5;
else
    labelLat = studyLat + 0.5; labelLon = studyLon + 0.2;
end
text(ax, labelLat, labelLon, siteName, 'FontName', fontName, ...
    'FontSize', 17, 'FontWeight', 'bold', 'Color', [0.85 0 0]);
ax.LongitudeLabel.String = '';
ax.LatitudeLabel.String = '';
ax.FontName = fontName;
ax.FontSize = 16;
hold(ax, 'off');
end
