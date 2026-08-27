function ensure_dir(path)
% Create an output directory when it does not already exist.
if ~exist(path, 'dir')
    mkdir(path);
end
end
