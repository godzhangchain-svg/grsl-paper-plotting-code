function fig = make_self_validation_figure(ref, pred, hMax, d99, metrics)
% Plot the Wanning FCNN out-of-fold self-validation panel.
plotMax = 30;
edges = 0:0.5:plotMax;
bx = discretize(ref, edges);
by = discretize(pred, edges);
valid = ~isnan(bx) & ~isnan(by);
counts = accumarray([bx(valid), by(valid)], 1, ...
    [numel(edges)-1, numel(edges)-1], @sum, 0);
density = ones(size(ref));
density(valid) = counts(sub2ind(size(counts), bx(valid), by(valid)));

fig = figure('Color', 'white', 'Position', [100 80 760 680]);
ax = axes(fig, 'Position', [0.12 0.12 0.72 0.80]);
hold(ax, 'on');
scatter(ax, ref, pred, 22, density, 'filled', ...
    'MarkerEdgeColor', [1 1 1], 'LineWidth', 0.12, ...
    'MarkerFaceAlpha', 0.92);
colormap(ax, turbo(256));
set(ax, 'ColorScale', 'log');
cb = colorbar(ax);
cb.Label.String = 'Count per 0.5 m x 0.5 m bin';
hOne = plot(ax, [0 plotMax], [0 plotMax], '--', 'Color', [1 0 0], 'LineWidth', 2.2);
hBlue = xline(ax, hMax, '-', 'Color', [0 0.45 0.90], 'LineWidth', 2.0);
hRed = xline(ax, d99, '-', 'Color', [0.85 0 0], 'LineWidth', 2.0);
uistack([hOne hBlue hRed], 'top');
xlim(ax, [0 plotMax]); ylim(ax, [0 plotMax]); axis(ax, 'square');
grid(ax, 'on'); box(ax, 'on');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 13, ...
    'LineWidth', 1, 'TickDir', 'out');
xlabel(ax, 'Reference Depth (m)', 'FontWeight', 'bold');
ylabel(ax, 'Predicted Depth (m)', 'FontWeight', 'bold');
metricText = sprintf('RMSE = %.2f m\nBias = %+.2f m\nR^2 = %.3f', ...
    metrics.RMSE, metrics.Bias, metrics.R2);
text(ax, 0.035, 0.965, metricText, 'Units', 'normalized', ...
    'VerticalAlignment', 'top', 'FontName', 'Consolas', ...
    'FontSize', 15, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.92], ...
    'EdgeColor', [0.3 0.3 0.3], 'Margin', 7);
legend(ax, [hOne hBlue hRed], {'1:1 line', ...
    sprintf('H_{max} = %.2f m', hMax), ...
    sprintf('D_{train,99} = %.2f m', d99)}, ...
    'Location', 'southeast', 'FontName', 'Times New Roman', ...
    'FontSize', 11, 'Box', 'on');
end
