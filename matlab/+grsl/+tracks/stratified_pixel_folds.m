function [foldId, audit] = stratified_pixel_folds(depth, pixelId, ...
        nFolds, binWidth, seed)
% Assign every Sentinel pixel to one deterministic depth-stratified fold.
[uniquePixel, ~, group] = unique(pixelId, 'stable');
groupDepth = accumarray(group, depth, [], @mean);
stratum = floor(groupDepth ./ binWidth);
strata = unique(stratum, 'sorted');
foldGroup = zeros(size(uniquePixel));
stream = RandStream('mt19937ar', 'Seed', seed);
for k = 1:numel(strata)
    groupIndex = find(stratum == strata(k));
    shuffled = groupIndex(randperm(stream, numel(groupIndex)));
    foldOrder = randperm(stream, nFolds);
    for j = 1:numel(shuffled)
        foldGroup(shuffled(j)) = foldOrder(mod(j-1, nFolds) + 1);
    end
end
assert(all(foldGroup > 0), 'At least one control group has no fold.');
foldId = foldGroup(group);

rows = cell(numel(strata) * nFolds, 1);
p = 0;
for k = 1:numel(strata)
    rowStratum = floor(depth ./ binWidth) == strata(k);
    for f = 1:nFolds
        p = p + 1;
        DepthLower_m = strata(k) * binWidth;
        DepthUpper_m = (strata(k) + 1) * binWidth;
        Fold = f;
        GroupN = sum(stratum == strata(k) & foldGroup == f);
        RowN = sum(rowStratum & foldId == f);
        FoldSeed = seed;
        rows{p} = table(DepthLower_m, DepthUpper_m, Fold, GroupN, RowN, FoldSeed);
    end
end
audit = vertcat(rows{:});
for f = 1:nFolds
    assert(any(foldId == f), 'Fold %d is empty.', f);
end
for g = 1:numel(uniquePixel)
    assert(numel(unique(foldId(group == g))) == 1, ...
        'A Sentinel pixel spans folds.');
end
end
