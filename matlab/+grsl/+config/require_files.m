function require_files(paths)
% Assert that each required input file exists.
for i = 1:numel(paths)
    assert(isfile(paths{i}), 'Missing required input: %s', paths{i});
end
end
