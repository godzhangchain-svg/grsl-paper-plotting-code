function validation_panel(ax, ref, pred, fixedMax, binWidth, ...
        boundaries, isIndependent, label, metricOverride)
% Draw one density-colored validation panel with Hmax and Dtrain99 lines.
if nargin < 9 || isempty(metricOverride)
    metrics = grsl.metrics.calc_metrics(ref, pred);
else
    metrics = metricOverride;
end
if isempty(fixedMax)
    dataMax = ceil(max([ref; pred]) / binWidth) * binWidth;
    plotMax = ceil(max([dataMax, boundaries.Hmax, boundaries.Dtrain99]) / binWidth) * binWidth;
else
    plotMax = ceil(max([fixedMax, boundaries.Hmax, boundaries.Dtrain99]) / binWidth) * binWidth;
    in = ref <= plotMax & pred <= plotMax;
    ref = ref(in); pred = pred(in);
end
edges = 0:binWidth:plotMax;
[counts, ~, ~, xBin, yBin] = histcounts2(ref, pred, edges, edges);
pointCount = nan(size(ref));
inside = xBin > 0 & yBin > 0;
pointCount(inside) = counts(sub2ind(size(counts), xBin(inside), yBin(inside)));
colorValue = log10(pointCount + 1);
[~, order] = sort(pointCount, 'descend', 'MissingPlacement', 'last');
hold(ax, 'on');
hRed = line(ax, [boundaries.Dtrain99 boundaries.Dtrain99], [0 plotMax], ...
    'Color', [0.85 0.10 0.10], 'LineWidth', 1.8);
hBlue = line(ax, [boundaries.Hmax boundaries.Hmax], [0 plotMax], ...
    'Color', [0 0.45 0.85], 'LineWidth', 1.8);
scatter(ax, ref(order), pred(order), 14, colorValue(order), 'filled', ...
    'MarkerEdgeColor', [1 1 1], 'LineWidth', 0.1, 'MarkerFaceAlpha', 0.92);
hOne = plot(ax, [0 plotMax], [0 plotMax], '--', ...
    'Color', [0.35 0.35 0.35], 'LineWidth', 1.5);
uistack([hRed hBlue hOne], 'top');
colormap(ax, turbo(256));
cb = colorbar(ax);
cb.Label.String = 'Count per 0.5 m x 0.5 m bin';
legend(ax, hOne, {'1:1 line'}, 'Location', 'southeast', ...
    'FontSize', 13, 'Box', 'on');
if isIndependent
    annotationText = {sprintf('RMSE_{all} = %.2f m', metrics.RMSE), ...
        sprintf('R^2_{all} = %.3f', metrics.R2)};
    yLabel = 'SDB Derived Depth (m)';
else
    annotationText = {sprintf('RMSE = %.2f m', metrics.RMSE), ...
        sprintf('R^2 = %.3f', metrics.R2)};
    yLabel = 'Predicted Depth (m)';
end
text(ax, 0.04, 0.96, annotationText, 'Units', 'normalized', ...
    'VerticalAlignment', 'top', 'BackgroundColor', [1 1 1 0.92], ...
    'EdgeColor', [0.3 0.3 0.3], 'Margin', 5, 'FontSize', 14, ...
    'FontName', 'Consolas', 'FontWeight', 'bold');
text(ax, 0.96, 0.96, label, 'Units', 'normalized', ...
    'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
    'FontSize', 16, 'FontWeight', 'bold', 'FontName', 'Times New Roman');
xlabel(ax, 'Reference Depth (m)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel(ax, yLabel, 'FontSize', 13, 'FontWeight', 'bold');
grid(ax, 'on'); box(ax, 'on'); axis(ax, 'equal');
xlim(ax, [0 plotMax]); ylim(ax, [0 plotMax]);
set(ax, 'FontSize', 12, 'FontName', 'Times New Roman', ...
    'LineWidth', 1, 'TickDir', 'out');
hold(ax, 'off');
end
