function X = feature_matrix(bands4, row, col, nRows, nCols, mode)
% Build the selected Wanning feature matrix for arbitrary raster pixels.
rowNorm = double(row(:)) ./ nRows;
colNorm = double(col(:)) ./ nCols;
switch string(mode)
    case "bands4"
        X = double(bands4);
    case "bands4_row"
        X = [double(bands4), rowNorm];
    case "bands4_col"
        X = [double(bands4), colNorm];
    case "bands4_xy"
        X = [double(bands4), rowNorm, colNorm];
    case "bands4_xy10"
        X = [double(bands4), grsl.quantize.coord(rowNorm, 10), ...
            grsl.quantize.coord(colNorm, 10)];
    case "bands4_xy20"
        X = [double(bands4), grsl.quantize.coord(rowNorm, 20), ...
            grsl.quantize.coord(colNorm, 20)];
    case "bands4_xy40"
        X = [double(bands4), grsl.quantize.coord(rowNorm, 40), ...
            grsl.quantize.coord(colNorm, 40)];
    otherwise
        error('Unsupported Wanning feature mode: %s', mode);
end
end
