function plot_metric(ax, T, site, metricName, yLabel, hMax, p99, isMae)
% Plot one site/metric combination from standardized depth-bin rows.
siteRows = T(T.Site == site, :);
self = siteRows(siteRows.Validation == "Internal Validation", :);
independent = siteRows(siteRows.Validation == "Independent Validation", :);
hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');
selfGood = self.Reliable & isfinite(self.(metricName));
indGood = independent.Reliable & isfinite(independent.(metricName));
hSelf = plot(ax, self.DepthCenter_m(selfGood), self.(metricName)(selfGood), ...
    '-o', 'Color', [0.48 0.20 0.72], 'MarkerFaceColor', [0.48 0.20 0.72], ...
    'LineWidth', 1.6, 'MarkerSize', 4);
hIndependent = plot(ax, independent.DepthCenter_m(indGood), ...
    independent.(metricName)(indGood), '-s', 'Color', [0.08 0.52 0.38], ...
    'MarkerFaceColor', [0.08 0.52 0.38], 'LineWidth', 1.6, 'MarkerSize', 4);
xline(ax, hMax, '-', 'Color', [0 0.45 0.85], 'LineWidth', 1.8);
xline(ax, p99, '-', 'Color', [0.85 0.10 0.10], 'LineWidth', 1.8);
if ~isMae
    yline(ax, 0, '--', 'Color', [0.25 0.25 0.25], 'LineWidth', 1);
end
xlim(ax, [0 max(siteRows.DepthUpper_m)]);
xlabel(ax, 'Reference Depth (m)'); ylabel(ax, yLabel);
title(ax, sprintf('%s: %s', site, erase(yLabel, ' (m)')));
legend(ax, [hSelf hIndependent], {'Internal Validation','Independent Validation'}, ...
    'Location', 'best', 'FontSize', 10, 'Box', 'on');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 12, ...
    'LineWidth', 0.9, 'Layer', 'top');
end
