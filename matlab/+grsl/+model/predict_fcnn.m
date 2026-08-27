function Ypred = predict_fcnn(mdl, X)
% Predict with a fitted regression model. Centralizes all predict calls
% so that model inference lives under +grsl instead of public entrypoints.
Ypred = predict(mdl, X);
end
