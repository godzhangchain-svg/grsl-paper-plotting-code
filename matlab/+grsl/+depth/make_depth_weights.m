function w = make_depth_weights(y, d99, rho, power)
% Monotonically non-decreasing depth weights used for weighted FCNN training.
assert(isfinite(d99) && d99 > 0, 'd99 must be positive and finite.');
scaled = min(max(y ./ d99, 0), 1) .^ power;
w = 1 + (rho - 1) .* scaled;
w = w ./ mean(w);
assert(all(isfinite(w)) && all(w > 0), 'Invalid observation weights.');
end
