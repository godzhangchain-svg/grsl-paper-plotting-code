function [validationLat, validationLon] = extract_oahu_positions(cfg)
% Return Oahu ALB positions retained by the production validation rules.
[sdbGrid, R] = geotiffread(cfg.sdbFile);
sdbGrid = double(sdbGrid);
[nRows, nCols] = size(sdbGrid);
d = load(cfg.referenceFile);
lat = d.lat(:); lon = d.lon(:); depth = d.depth(:);
validDepth = depth > 0 & depth <= cfg.maxReferenceDepth;
lat = lat(validDepth); lon = lon(validDepth); depth = depth(validDepth);
rng(cfg.randomSeed, 'twister');
nSample = round(numel(depth) * cfg.sampleRatio);
selection = randperm(numel(depth), nSample);
lat = lat(selection); lon = lon(selection); depth = depth(selection);
if isa(R, 'map.rasterref.MapCellsReference')
    [x, y] = projfwd(R.ProjectedCRS, lat, lon);
    col = floor((x - R.XWorldLimits(1)) / R.CellExtentInWorldX) + 1;
    row = floor((R.YWorldLimits(2) - y) / R.CellExtentInWorldY) + 1;
else
    col = floor((lon - R.LongitudeLimits(1)) / R.CellExtentInLongitude) + 1;
    row = floor((R.LatitudeLimits(2) - lat) / R.CellExtentInLatitude) + 1;
end
inBounds = row >= 1 & row <= nRows & col >= 1 & col <= nCols;
row = row(inBounds); col = col(inBounds);
lat = lat(inBounds); lon = lon(inBounds); depth = depth(inBounds);
sdbAtPoint = sdbGrid(sub2ind([nRows nCols], row, col));
validPair = isfinite(sdbAtPoint) & sdbAtPoint > 0 & isfinite(depth);
sdbAtPoint = sdbAtPoint(validPair); depth = depth(validPair);
lat = lat(validPair); lon = lon(validPair);
notSurface = (sdbAtPoint - depth) <= 12;
sdbAtPoint = sdbAtPoint(notSurface); depth = depth(notSurface);
lat = lat(notSurface); lon = lon(notSurface);
selected = depth >= cfg.minDepth & sdbAtPoint >= cfg.minDepth & ...
    depth <= cfg.plotMaxDepth & sdbAtPoint <= cfg.plotMaxDepth;
validationLat = lat(selected);
validationLon = lon(selected);
end
