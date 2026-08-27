function [refStat, predStat, allPairs] = validate_oahu_alb(sdbFile, albFile, seed)
% Apply the production Oahu ALB sampling and filtering order.
[sdb, R] = geotiffread(sdbFile);
sdb = double(sdb);
[nRows, nCols] = size(sdb);
d = load(albFile);
lat = d.lat(:); lon = d.lon(:); depth = d.depth(:);
valid = depth > 0 & depth <= 60;
lat = lat(valid); lon = lon(valid); depth = depth(valid);
rng(seed, 'twister');
nSample = round(numel(depth) * 0.25);
idx = randperm(numel(depth), nSample);
lat = lat(idx); lon = lon(idx); depth = depth(idx);
if isnumeric(R)
    [x, y] = projfwd(projcrs(32604), lat, lon);
    [row, col] = map2pix(R, x, y);
    row = round(row); col = round(col);
elseif isa(R, 'map.rasterref.MapCellsReference')
    [x, y] = projfwd(R.ProjectedCRS, lat, lon);
    col = floor((x - R.XWorldLimits(1)) / R.CellExtentInWorldX) + 1;
    row = floor((R.YWorldLimits(2) - y) / R.CellExtentInWorldY) + 1;
else
    col = floor((lon - R.LongitudeLimits(1)) / R.CellExtentInLongitude) + 1;
    row = floor((R.LatitudeLimits(2) - lat) / R.CellExtentInLatitude) + 1;
end
in = row >= 1 & row <= nRows & col >= 1 & col <= nCols;
row = row(in); col = col(in); depth = depth(in);
sdbAt = sdb(sub2ind([nRows, nCols], row, col));
valid = isfinite(sdbAt) & sdbAt > 0 & isfinite(depth);
sdbAt = sdbAt(valid); depth = depth(valid);
keep = (sdbAt - depth) <= 12;
sdbAt = sdbAt(keep); depth = depth(keep);
allPairs = table(depth, sdbAt, sdbAt - depth, ...
    'VariableNames', {'ReferenceDepth_m', 'PredictedDepth_m', 'Residual_m'});
stat = depth >= 2 & sdbAt >= 2 & depth <= 55 & sdbAt <= 55;
refStat = depth(stat);
predStat = sdbAt(stat);
end
