function [rgb, imageLonLim, imageLatDir] = stretch_rgb(filename, lonLim, latLim)
% Crop and percentile-stretch the first three raster bands for display.
[img, R] = geotiffread(filename);
lonCorners = lonLim([1 2 2 1]);
latCorners = latLim([1 1 2 2]);
isProjected = isa(R, 'map.rasterref.MapCellsReference');
if isProjected
    crs = R.ProjectedCRS;
    [xCorners, yCorners] = projfwd(crs, latCorners, lonCorners);
    [colIntrinsic, rowIntrinsic] = worldToIntrinsic(R, xCorners, yCorners);
else
    [colIntrinsic, rowIntrinsic] = ...
        geographicToIntrinsic(R, latCorners, lonCorners);
end
rowStart = max(1, floor(min(rowIntrinsic)) - 1);
rowEnd = min(size(img,1), ceil(max(rowIntrinsic)) + 1);
colStart = max(1, floor(min(colIntrinsic)) - 1);
colEnd = min(size(img,2), ceil(max(colIntrinsic)) + 1);
assert(rowStart <= rowEnd && colStart <= colEnd, ...
    'Requested map window does not overlap %s.', filename);
img = img(rowStart:rowEnd, colStart:colEnd, :);
midRow = (rowStart + rowEnd) / 2;
midCol = (colStart + colEnd) / 2;
if isProjected
    [xEdge, yEdge] = intrinsicToWorld(R, [colStart colEnd], [midRow midRow]);
    [~, lonEdge] = projinv(crs, xEdge, yEdge);
    [xEdge, yEdge] = intrinsicToWorld(R, [midCol midCol], [rowStart rowEnd]);
    [latEdge, ~] = projinv(crs, xEdge, yEdge);
else
    [~, lonEdge] = intrinsicToGeographic(R, [colStart colEnd], [midRow midRow]);
    [latEdge, ~] = intrinsicToGeographic(R, [midCol midCol], [rowStart rowEnd]);
end
imageLonLim = [lonEdge(1), lonEdge(2)];
imageLatDir = [latEdge(1), latEdge(2)];
if size(img, 3) >= 3
    rgb = double(img(:,:,1:3));
    for channel = 1:3
        band = rgb(:,:,channel);
        valid = band(isfinite(band) & band > 0);
        if isempty(valid), continue; end
        low = prctile(valid, 2);
        high = prctile(valid, 98);
        if high > low
            rgb(:,:,channel) = (band - low) ./ (high - low);
        end
    end
else
    band = double(img(:,:,1));
    valid = band(isfinite(band) & band > 0);
    low = prctile(valid, 2);
    high = prctile(valid, 98);
    band = (band - low) ./ (high - low);
    rgb = repmat(band, 1, 1, 3);
end
rgb = max(0, min(1, rgb));
end
