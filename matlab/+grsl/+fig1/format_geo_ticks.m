function format_geo_ticks(ax, westLongitude)
% Format coordinate ticks without axis-title words.
xt = get(ax, 'XTick'); yt = get(ax, 'YTick');
if westLongitude
    xLabels = arrayfun(@(x) sprintf('%.2f W', abs(x)), xt, 'UniformOutput', false);
else
    xLabels = arrayfun(@(x) sprintf('%.2f E', x), xt, 'UniformOutput', false);
end
yLabels = arrayfun(@(y) sprintf('%.2f N', y), yt, 'UniformOutput', false);
set(ax, 'XTickLabel', xLabels, 'YTickLabel', yLabels);
end
