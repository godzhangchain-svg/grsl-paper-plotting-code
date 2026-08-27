function one = build_one_track_dataset_oahu(path, waterSurface, R, crs, ...
        img4_2d, nRows, nCols)
% Oahu (V6) track dataset builder. Projection forwarding uses an explicit
% projcrs object, matching the Oahu weighted-FCNN workflow.
S = load(path);
assert(isfield(S, 'NHBLCTDH'), 'Track lacks NHBLCTDH: %s', path);
d = S.NHBLCTDH; d = d(d(:,5)==30, :);
if isempty(d), one = zeros(0,5); return; end
depth = waterSurface - d(:,8); lat = d(:,3); lon = d(:,4);
[x, y] = projfwd(crs, lat, lon); [row, col] = map2pix(R, x, y);
row = round(row); col = round(col);
valid = row>=1 & row<=nRows & col>=1 & col<=nCols;
row = row(valid); col = col(valid); depth = depth(valid);
if isempty(depth), one = zeros(0,5); return; end
idx = sub2ind([nRows, nCols], row, col);
[u, ~, ic] = unique(idx); depthMean = accumarray(ic, depth, [], @mean);
one = [img4_2d(u, :), depthMean];
bad = one(:,1)==0 | any(isnan(one(:,1:4)),2) | isnan(one(:,5));
one(bad, :) = [];
end
