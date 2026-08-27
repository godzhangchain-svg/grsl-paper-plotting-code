function add_scale_bar(ax, scaleKm, meanLatitude, fontName)
% Add a compact two-tone geographic scale bar.
xBounds = xlim(ax); yBounds = ylim(ax);
scaleDegrees = scaleKm / (111 * cosd(meanLatitude));
x0 = xBounds(2) - 0.06 * diff(xBounds) - scaleDegrees;
x1 = xBounds(2) - 0.06 * diff(xBounds);
y0 = yBounds(1) + 0.065 * diff(yBounds);
cap = 0.012 * diff(yBounds);
plot(ax, [x0 x1], [y0 y0], '-', 'Color', [0 0 0], 'LineWidth', 5, ...
    'HandleVisibility', 'off');
plot(ax, [x0 x1], [y0 y0], '-', 'Color', [1 1 1], 'LineWidth', 2.5, ...
    'HandleVisibility', 'off');
plot(ax, [x0 x0], [y0-cap y0+cap], '-', 'Color', [1 1 1], ...
    'LineWidth', 2.5, 'HandleVisibility', 'off');
plot(ax, [x1 x1], [y0-cap y0+cap], '-', 'Color', [1 1 1], ...
    'LineWidth', 2.5, 'HandleVisibility', 'off');
text(ax, mean([x0 x1]), y0 + 0.026 * diff(yBounds), sprintf('%d km', scaleKm), ...
    'HorizontalAlignment', 'center', 'Color', 'white', ...
    'FontName', fontName, 'FontSize', 16, 'FontWeight', 'bold');
end
