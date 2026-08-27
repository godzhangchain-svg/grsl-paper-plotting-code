function rows = build_one_track_dataset(trackPath, waterSurface, R, info, ...
        img4_2d, nRows, nCols, trackId)
% Build Wanning rows: four bands, depth, track id, track row, pixel id.
S = load(trackPath);
assert(isfield(S, 'NHBLCTDH'), 'Track file %s lacks NHBLCTDH.', trackPath);
d = S.NHBLCTDH;
d = d(d(:,5) == 30, :);
if isempty(d), rows = zeros(0, 8); return; end
depth = waterSurface - d(:,8);
[x, y] = projfwd(info, d(:,3), d(:,4));
[row, col] = map2pix(R, x, y);
row = round(row); col = round(col);
inside = row >= 1 & row <= nRows & col >= 1 & col <= nCols;
row = row(inside); col = col(inside); depth = depth(inside);
if isempty(depth), rows = zeros(0, 8); return; end
pixelId = sub2ind([nRows, nCols], row, col);
[uniquePixel, ~, group] = unique(pixelId);
depthMean = accumarray(group, depth, [], @mean);
bands = double(img4_2d(uniquePixel, :));
trackRow = (1:numel(uniquePixel))';
rows = [bands, depthMean, repmat(trackId, numel(uniquePixel), 1), ...
    trackRow, double(uniquePixel)];
bad = rows(:,1) == 0 | any(~isfinite(rows(:,1:5)), 2) | rows(:,5) < 0;
rows(bad, :) = [];
end
