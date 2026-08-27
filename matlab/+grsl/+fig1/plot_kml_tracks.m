function plot_kml_tracks(ax, folder, stride, color)
% Plot every stride-th KML track without adding legend entries.
files = dir(fullfile(folder, '*.kml'));
for i = 1:stride:numel(files)
    text = fileread(fullfile(files(i).folder, files(i).name));
    tokens = regexp(text, '<coordinates>(.*?)</coordinates>', 'tokens');
    if isempty(tokens), continue; end
    parts = strsplit(strtrim(tokens{1}{1}));
    lon = nan(numel(parts), 1); lat = nan(numel(parts), 1);
    for j = 1:numel(parts)
        xyz = strsplit(parts{j}, ',');
        if numel(xyz) >= 2
            lon(j) = str2double(xyz{1});
            lat(j) = str2double(xyz{2});
        end
    end
    valid = isfinite(lat) & isfinite(lon);
    if any(valid)
        plot(ax, lon(valid), lat(valid), '-', 'Color', color, ...
            'LineWidth', 0.9, 'HandleVisibility', 'off');
    end
end
end
