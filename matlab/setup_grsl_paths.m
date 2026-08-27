function setup_grsl_paths()
% Add the repository MATLAB folder so package functions resolve.
matlabRoot = fileparts(mfilename('fullpath'));
addpath(matlabRoot);
end
