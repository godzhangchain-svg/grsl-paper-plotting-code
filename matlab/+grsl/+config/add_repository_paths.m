function add_repository_paths()
% Add only the MATLAB root; package directories resolve automatically.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(root);
end
