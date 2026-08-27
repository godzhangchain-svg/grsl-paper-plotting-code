function mdl = train_fcnn(X, y, varargin)
% Train a feedforward neural network regression model.
mdl = fitrnet(X, y, varargin{:});
end
