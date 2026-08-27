function result = pair_wanning_rasters(referenceFile, waterSurface, ...
        maxRawDepth, prediction, Rpred, minDepth, maxDepth)
% Resample the shipborne raster to the SDB grid and return matched pairs.
[bottomElevation, Rref] = geotiffread(referenceFile);
referenceDepth = waterSurface - double(bottomElevation);
referenceDepth(referenceDepth > maxRawDepth | referenceDepth <= 0) = NaN;
prediction = double(prediction);
prediction(prediction < 0) = NaN;

isPRef = isa(Rref, 'map.rasterref.MapCellsReference');
isPPred = isa(Rpred, 'map.rasterref.MapCellsReference');
if isPRef, crsRef = Rref.ProjectedCRS; else, crsRef = Rref.GeographicCRS; end
if isPPred, crsPred = Rpred.ProjectedCRS; else, crsPred = Rpred.GeographicCRS; end
hasRefCRS = ~isempty(crsRef);
hasPredCRS = ~isempty(crsPred);
sameCRS = hasRefCRS && hasPredCRS && strcmp(crsRef.Name, crsPred.Name);
if hasPredCRS
    targetCRS = crsPred;
elseif hasRefCRS
    targetCRS = crsRef;
else
    targetCRS = [];
end

if ~hasRefCRS && ~hasPredCRS
    lonOverlap = [max(Rref.LongitudeLimits(1), Rpred.LongitudeLimits(1)), ...
        min(Rref.LongitudeLimits(2), Rpred.LongitudeLimits(2))];
    latOverlap = [max(Rref.LatitudeLimits(1), Rpred.LatitudeLimits(1)), ...
        min(Rref.LatitudeLimits(2), Rpred.LatitudeLimits(2))];
else
    [latRef, lonRef] = grsl.reference.reference_corners(Rref, isPRef, crsRef);
    [latPred, lonPred] = grsl.reference.reference_corners(Rpred, isPPred, crsPred);
    if sameCRS
        xRef = Rref.XWorldLimits([1 2 2 1]);
        yRef = Rref.YWorldLimits([1 1 2 2]);
        xPred = Rpred.XWorldLimits([1 2 2 1]);
        yPred = Rpred.YWorldLimits([1 1 2 2]);
    else
        [xRef, yRef] = projfwd(targetCRS, latRef, lonRef);
        [xPred, yPred] = projfwd(targetCRS, latPred, lonPred);
    end
    xOverlap = [max(min(xRef), min(xPred)), min(max(xRef), max(xPred))];
    yOverlap = [max(min(yRef), min(yPred)), min(max(yRef), max(yPred))];
    [latCorners, lonCorners] = projinv(targetCRS, ...
        xOverlap([1 2 2 1]), yOverlap([1 1 2 2]));
    lonOverlap = [min(lonCorners), max(lonCorners)];
    latOverlap = [min(latCorners), max(latCorners)];
end

[refCrop, xRefVec, yRefVec] = grsl.reference.crop_raster(referenceDepth, ...
    Rref, latOverlap, lonOverlap, isPRef, crsRef);
[predCrop, xPredVec, yPredVec] = grsl.reference.crop_raster(prediction, ...
    Rpred, latOverlap, lonOverlap, isPPred, crsPred);
[XqPred, YqPred] = meshgrid(xPredVec, yPredVec);
if sameCRS || (~hasRefCRS && ~hasPredCRS)
    XqRef = XqPred;
    YqRef = YqPred;
else
    if isPPred
        [latQ, lonQ] = projinv(crsPred, XqPred, YqPred);
    else
        lonQ = XqPred;
        latQ = YqPred;
    end
    if isPRef
        [XqRef, YqRef] = projfwd(crsRef, latQ, lonQ);
    else
        XqRef = lonQ;
        YqRef = latQ;
    end
end
[XrefGrid, YrefGrid] = meshgrid(xRefVec, yRefVec);
referenceResampled = interp2(XrefGrid, YrefGrid, refCrop, ...
    XqRef, YqRef, 'linear', NaN);
referenceResampled(referenceResampled <= 0) = NaN;

refAll = referenceResampled(:);
predAll = predCrop(:);
valid = isfinite(refAll) & isfinite(predAll) & refAll > 0 & predAll > 0;
refAll = refAll(valid);
predAll = predAll(valid);
stat = refAll >= minDepth & predAll >= minDepth & ...
    refAll <= maxDepth & predAll <= maxDepth;
result.ReferenceAll_m = refAll;
result.PredictionAll_m = predAll;
result.ReferenceStat_m = refAll(stat);
result.PredictionStat_m = predAll(stat);
end
