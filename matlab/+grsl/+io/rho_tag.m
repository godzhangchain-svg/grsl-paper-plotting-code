function tag = rho_tag(value)
% Convert a numeric candidate value into a filename-safe token.
tag = strrep(sprintf('%.1f', value), '.', 'p');
end
