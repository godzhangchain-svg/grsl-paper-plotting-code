function export_png(fig, path, resolution)
% Export a white-background PNG with a print fallback.
try
    exportgraphics(fig, path, 'Resolution', resolution, ...
        'BackgroundColor', 'white');
catch
    print(fig, path, '-dpng', sprintf('-r%d', resolution));
end
end
