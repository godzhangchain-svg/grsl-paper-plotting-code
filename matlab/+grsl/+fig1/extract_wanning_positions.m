function [validationLat, validationLon] = extract_wanning_positions(cfg)
% Return positions of Wanning pairs retained by independent validation.
[bottomElevation, Rref] = geotiffread(cfg.referenceFile);
[sdb, Rsdb] = geotiffread(cfg.sdbFile);
referenceDepth = cfg.waterSurface - double(bottomElevation);
referenceDepth(referenceDepth > cfg.maxReferenceDepth | referenceDepth <= 0) = NaN;
sdb = double(sdb); sdb(sdb < 0) = NaN;
isPRef = isa(Rref, 'map.rasterref.MapCellsReference');
isPSdb = isa(Rsdb, 'map.rasterref.MapCellsReference');
if isPRef, crsRef = Rref.ProjectedCRS; else, crsRef = Rref.GeographicCRS; end
if isPSdb, crsSdb = Rsdb.ProjectedCRS; else, crsSdb = Rsdb.GeographicCRS; end
hasRefCRS = ~isempty(crsRef);
hasSdbCRS = ~isempty(crsSdb);
sameCRS = hasRefCRS && hasSdbCRS && strcmp(crsRef.Name, crsSdb.Name);

if (~hasRefCRS && ~hasSdbCRS) || (~isPRef && ~isPSdb)
    lonOverlap = [max(Rref.LongitudeLimits(1), Rsdb.LongitudeLimits(1)), ...
        min(Rref.LongitudeLimits(2), Rsdb.LongitudeLimits(2))];
    latOverlap = [max(Rref.LatitudeLimits(1), Rsdb.LatitudeLimits(1)), ...
        min(Rref.LatitudeLimits(2), Rsdb.LatitudeLimits(2))];
else
    if hasSdbCRS, targetCRS = crsSdb; else, targetCRS = crsRef; end
    [refLat, refLon] = grsl.reference.reference_corners(Rref, isPRef, crsRef);
    [sdbLat, sdbLon] = grsl.reference.reference_corners(Rsdb, isPSdb, crsSdb);
    if sameCRS && isPRef && isPSdb
        refX = Rref.XWorldLimits([1 2 2 1]); refY = Rref.YWorldLimits([1 1 2 2]);
        sdbX = Rsdb.XWorldLimits([1 2 2 1]); sdbY = Rsdb.YWorldLimits([1 1 2 2]);
    else
        [refX, refY] = projfwd(targetCRS, refLat, refLon);
        [sdbX, sdbY] = projfwd(targetCRS, sdbLat, sdbLon);
    end
    xOverlap = [max(min(refX), min(sdbX)), min(max(refX), max(sdbX))];
    yOverlap = [max(min(refY), min(sdbY)), min(max(refY), max(sdbY))];
    [cornerLat, cornerLon] = projinv(targetCRS, ...
        xOverlap([1 2 2 1]), yOverlap([1 1 2 2]));
    lonOverlap = [min(cornerLon), max(cornerLon)];
    latOverlap = [min(cornerLat), max(cornerLat)];
end

[refCrop, refXVec, refYVec] = grsl.reference.crop_raster(referenceDepth, ...
    Rref, latOverlap, lonOverlap, isPRef, crsRef);
[sdbCrop, sdbXVec, sdbYVec] = grsl.reference.crop_raster(sdb, ...
    Rsdb, latOverlap, lonOverlap, isPSdb, crsSdb);
[XqSdb, YqSdb] = meshgrid(sdbXVec, sdbYVec);
if sameCRS || (~hasRefCRS && ~hasSdbCRS) || (~isPRef && ~isPSdb)
    XqRef = XqSdb; YqRef = YqSdb;
else
    if isPSdb
        [latQ, lonQ] = projinv(crsSdb, XqSdb, YqSdb);
    else
        lonQ = XqSdb; latQ = YqSdb;
    end
    if isPRef
        [XqRef, YqRef] = projfwd(crsRef, latQ, lonQ);
    else
        XqRef = lonQ; YqRef = latQ;
    end
end
[Xref, Yref] = meshgrid(refXVec, refYVec);
resampledReference = interp2(Xref, Yref, refCrop, XqRef, YqRef, 'linear', NaN);
resampledReference(resampledReference <= 0) = NaN;
sdbVector = sdbCrop(:);
refVector = resampledReference(:);
xVector = XqSdb(:);
yVector = YqSdb(:);
finitePair = isfinite(sdbVector) & isfinite(refVector) & ...
    sdbVector > 0 & refVector > 0;
sdbVector = sdbVector(finitePair);
refVector = refVector(finitePair);
xVector = xVector(finitePair);
yVector = yVector(finitePair);
selected = refVector >= cfg.minDepth & sdbVector >= cfg.minDepth & ...
    refVector <= cfg.plotMaxDepth & sdbVector <= cfg.plotMaxDepth;
xVector = xVector(selected); yVector = yVector(selected);
if isPSdb
    [validationLat, validationLon] = projinv(crsSdb, xVector, yVector);
else
    validationLon = xVector; validationLat = yVector;
end
end
