function sets = build_feature_sets(bands4, pixelId, nRows, nCols)
% Construct every fixed spatial-feature variant used during tuning.
[pixelRow, pixelCol] = ind2sub([nRows, nCols], round(pixelId));
rowNorm = pixelRow ./ nRows;
colNorm = pixelCol ./ nCols;
sets.bands4 = bands4;
sets.bands4_row = [bands4, rowNorm];
sets.bands4_col = [bands4, colNorm];
sets.bands4_xy = [bands4, rowNorm, colNorm];
sets.bands4_xy10 = [bands4, grsl.quantize.coord(rowNorm, 10), ...
    grsl.quantize.coord(colNorm, 10)];
sets.bands4_xy20 = [bands4, grsl.quantize.coord(rowNorm, 20), ...
    grsl.quantize.coord(colNorm, 20)];
sets.bands4_xy40 = [bands4, grsl.quantize.coord(rowNorm, 40), ...
    grsl.quantize.coord(colNorm, 40)];
end
