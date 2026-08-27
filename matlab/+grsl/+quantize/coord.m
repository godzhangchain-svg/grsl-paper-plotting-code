function q = coord(x, nBins)
% Quantize a normalized coordinate in [0,1] into nBins equal-width bins.
q = floor(min(max(x, 0), 1) .* nBins) ./ nBins;
end
