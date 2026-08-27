function [groups, counts] = split_tracks_balanced(trackPointCounts, nFolds)
% Greedy balanced assignment of tracks to folds by descending point count,
% keeping each fold's total sample count as even as possible.
groups = cell(nFolds, 1);
counts = zeros(nFolds, 1);
[~, order] = sort(trackPointCounts, 'descend');
for i = 1:numel(order)
    idx = order(i);
    [~, f] = min(counts);
    groups{f}(end+1) = idx;
    counts(f) = counts(f) + trackPointCounts(idx);
end
end
