function assert_reference_compatible(a, b)
% Assert compatible raster grids before transferring a mask.
if isnumeric(a) || isnumeric(b)
    assert(isnumeric(a) && isnumeric(b) && isequal(size(a), size(b)), ...
        'Legacy raster referencing matrices have incompatible types or sizes.');
    assert(max(abs(a(:) - b(:))) < 1e-9, ...
        'Legacy raster referencing matrices differ.');
    return;
end
assert(isequal(a.RasterSize, b.RasterSize), 'Raster reference sizes differ.');
if isprop(a, 'XWorldLimits') && isprop(b, 'XWorldLimits')
    assert(max(abs(a.XWorldLimits - b.XWorldLimits)) < 1e-6 && ...
        max(abs(a.YWorldLimits - b.YWorldLimits)) < 1e-6, ...
        'Raster world limits differ.');
elseif isprop(a, 'LatitudeLimits') && isprop(b, 'LatitudeLimits')
    assert(max(abs(a.LatitudeLimits - b.LatitudeLimits)) < 1e-9 && ...
        max(abs(a.LongitudeLimits - b.LongitudeLimits)) < 1e-9, ...
        'Raster geographic limits differ.');
end
end
