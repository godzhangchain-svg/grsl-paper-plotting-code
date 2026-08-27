function T = build_fold_assignment(names, counts, groups)
% Convert a cell-array fold assignment into a track-level table.
fold = zeros(numel(names), 1);
for f = 1:numel(groups)
    fold(groups{f}) = f;
end
T = table(names(:), counts(:), fold, ...
    'VariableNames', {'Track', 'MatchedPixelN', 'Fold'});
end
