function [trackData, trackNames, trackCounts] = build_track_pool(folder, builder)
% Build one dataset per MAT track using the supplied path callback.
files = dir(fullfile(folder, '*.mat'));
rawData = cell(numel(files), 1);
names = strings(numel(files), 1);
counts = zeros(numel(files), 1);
for k = 1:numel(files)
    p = fullfile(files(k).folder, files(k).name);
    rawData{k} = builder(p, k);
    names(k) = string(files(k).name);
    counts(k) = size(rawData{k}, 1);
end

valid = counts > 0;
trackData = rawData(valid);
trackNames = names(valid);
trackCounts = counts(valid);
end
