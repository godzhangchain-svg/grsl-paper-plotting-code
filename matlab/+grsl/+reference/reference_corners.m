function [lat, lon] = reference_corners(R, isProjected, crs)
if isProjected
    [lat, lon] = projinv(crs, ...
        R.XWorldLimits([1 2 2 1]), R.YWorldLimits([1 1 2 2]));
else
    lon = R.LongitudeLimits([1 2 2 1]);
    lat = R.LatitudeLimits([1 1 2 2]);
end
end
