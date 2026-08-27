function fig = make_independent_scatter(ref, pred, metrics, hMax, d99, plotMax)
% Plot Wanning independent MBES validation with depth boundaries.
inRange = ref <= plotMax & pred <= plotMax;
ref = ref(inRange); pred = pred(inRange);
edges = 0:0.5:plotMax;
[countGrid, ~, ~, xBin, yBin] = histcounts2(ref, pred, edges, edges);
pointCount = nan(size(ref));
inside = xBin > 0 & yBin > 0;
pointCount(inside) = countGrid(sub2ind(size(countGrid), xBin(inside), yBin(inside)));
colorValue = log10(pointCount + 1);
[~, order] = sort(pointCount, 'descend', 'MissingPlacement', 'last');
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [100 80 760 680]);
ax = axes(fig, 'Position', [0.12 0.12 0.72 0.80]);
hold(ax, 'on');
hBlue = xline(ax, hMax, '-', 'Color', [0 0.45 0.85], 'LineWidth', 1.8);
hRed = xline(ax, d99, '-', 'Color', [0.85 0.10 0.10], 'LineWidth', 1.8);
scatter(ax, ref(order), pred(order), 14, colorValue(order), 'filled', ...
    'MarkerEdgeColor', [1 1 1], 'LineWidth', 0.1, 'MarkerFaceAlpha', 0.92);
hOne = plot(ax, [0 plotMax], [0 plotMax], '--', 'Color', [1 0 0], 'LineWidth', 2.2);
uistack([hBlue hRed hOne], 'top');
colormap(ax, turbo(256));
cb = colorbar(ax);
cb.Label.String = 'Count per 0.5 m x 0.5 m bin';
legend(ax, hOne, {'1:1 line'}, 'Location', 'southeast', 'FontSize', 13, 'Box', 'on');
text(ax, 0.04, 0.96, {sprintf('RMSE_{all} = %.2f m', metrics.RMSE), ...
    sprintf('R^2_{all} = %.3f', metrics.R2)}, 'Units', 'normalized', ...
    'VerticalAlignment', 'top', 'BackgroundColor', [1 1 1 0.92], ...
    'EdgeColor', [0.3 0.3 0.3], 'Margin', 5, 'FontSize', 14, ...
    'FontName', 'Consolas', 'FontWeight', 'bold');
xlabel(ax, 'Reference Depth (m)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel(ax, 'SDB Derived Depth (m)', 'FontSize', 13, 'FontWeight', 'bold');
grid(ax, 'on'); box(ax, 'on'); axis(ax, 'equal');
xlim(ax, [0 plotMax]); ylim(ax, [0 plotMax]);
set(ax, 'FontSize', 12, 'FontName', 'Times New Roman', ...
    'LineWidth', 1, 'TickDir', 'out');
end
