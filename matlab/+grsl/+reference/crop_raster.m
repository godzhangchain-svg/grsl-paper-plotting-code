function [crop, x_vec, y_vec] = crop_raster(data, R, lat_ol, lon_ol, isP, crs)
if isP
    [ox, oy] = projfwd(crs, lat_ol, lon_ol);
    x_ol = [min(ox), max(ox)]; y_ol = [min(oy), max(oy)];
    [c1, r1] = worldToIntrinsic(R, x_ol(1), y_ol(2));
    [c2, r2] = worldToIntrinsic(R, x_ol(2), y_ol(1));
else
    lat_c = [max(lat_ol(1), R.LatitudeLimits(1)), min(lat_ol(2), R.LatitudeLimits(2))];
    lon_c = [max(lon_ol(1), R.LongitudeLimits(1)), min(lon_ol(2), R.LongitudeLimits(2))];
    [c1, r1] = geographicToIntrinsic(R, lat_c(2), lon_c(1));
    [c2, r2] = geographicToIntrinsic(R, lat_c(1), lon_c(2));
end
ri = round(sort([r1, r2])); ci = round(sort([c1, c2]));
ri(1) = max(1, ri(1)); ri(2) = min(size(data, 1), ri(2));
ci(1) = max(1, ci(1)); ci(2) = min(size(data, 2), ci(2));
crop = double(data(ri(1):ri(2), ci(1):ci(2), :));
crop = crop(:,:,1);
if isP
    x_full = linspace(R.XWorldLimits(1) + R.CellExtentInWorldX/2, ...
        R.XWorldLimits(2) - R.CellExtentInWorldX/2, size(data, 2));
    y_full = linspace(R.YWorldLimits(2) - R.CellExtentInWorldY/2, ...
        R.YWorldLimits(1) + R.CellExtentInWorldY/2, size(data, 1));
else
    x_full = linspace(R.LongitudeLimits(1) + R.CellExtentInLongitude/2, ...
        R.LongitudeLimits(2) - R.CellExtentInLongitude/2, size(data, 2));
    y_full = linspace(R.LatitudeLimits(2) - R.CellExtentInLatitude/2, ...
        R.LatitudeLimits(1) + R.CellExtentInLatitude/2, size(data, 1));
end
x_vec = x_full(ci(1):ci(2));
y_vec = y_full(ri(1):ri(2));
end
