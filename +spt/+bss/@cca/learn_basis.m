function obj = learn_basis(obj, X, varargin)

import misc.process_arguments;

opt.SamplingRate = [];
[~, opt] = process_arguments(opt, varargin);

T = size(X, 2);
delay = obj.Delay;

if isa(delay, 'function_handle'),
    % Delay can be a function_handle of the input to the
    % filter. This is handy when we want delay to be expressed
    % in seconds. It also allows for adaptive-delay schemes in
    % which the delay is obtained as a function of the input
    % data.
    if isa(X, 'physioset.physioset'),
        delay = delay(X.SamplingRate);
    elseif ~isempty(opt.SamplingRate),
        delay = delay(opt.SamplingRate);
    else
        error('Invalid/missing CCA delay');
    end
end
% Special case, Delay is an array of possible delays. Pick that
% delay that maximizes auto-correlation in the SUM dataset
if numel(delay) > 1,
    corrF = zeros(size(X,1), numel(delay));
    for i = 1:numel(delay)
        for j = 1:size(X,1),
            thisX = X(j,:) - mean(X(j,:));
            thisX = thisX./sqrt(var(thisX));
            thisCorr = ...
                thisX(1:end-delay(i))*thisX(delay(i)+1:end)';
            thisCorr = thisCorr/(numel(thisX)-delay(i));
            corrF(j,i) = thisCorr;
        end
    end
    corrF = prctile(abs(corrF), .75, 1);
    [~, Imax] = max(corrF);
    delay = delay(Imax);
end

% correlation matrices
if isa(X, 'pset.mmappset'),
    select(X, [], delay+1:T);
    Y = subset(X);
    clear_selection(X);
    select(X, [], 1:T-delay);
    center(X);
    center(Y);
    Ytrans = transpose(copy(Y));
    Xtrans = transpose(copy(X));
else
    Y = X(:,delay+1:end);
    X = X(:,1:end-delay);
    X = X - repmat(mean(X,2), 1, size(X,2));
    Y = Y - repmat(mean(Y,2), 1, size(Y,2));
    Ytrans = transpose(Y);
    Xtrans = transpose(X);
end

Cyy = (1/T)*(Y*Ytrans);
Cxx = (1/T)*(X*Xtrans);
Cxy = (1/T)*(X*Ytrans);
Cyx = (Cxy');
invCyy = pinv(Cyy);

if isa(X, 'pset.mmappset'),
    restore_selection(X);
end

% calculate W
[W,r] = eig(pinv(Cxx)*Cxy*invCyy*Cyx);
r = sqrt(abs(real(r)));
if obj.TopCorrFirst,
    [r, I] = sort(diag(r),'descend');
else
    [r, I] = sort(diag(r),'ascend');
end
obj.W = W(:,I)';
obj.A = pinv(obj.W);
obj.ComponentSelection = 1:size(obj.W,1);
obj.DimSelection       = 1:size(X,1);
obj.CorrVal = r;

% pick only a subset of components
selected = true(1, numel(r));
if isa(obj.MaxCorr, 'function_handle'),
    maxTh = obj.MaxCorr(r);
else
    maxTh = obj.MaxCorr;
end
selected(r > maxTh) = false;

if isa(obj.MinCorr, 'function_handle'),
    minTh = obj.MinCorr(r);
else
    minTh = obj.MinCorr;
end
selected(r < minTh) = false;

if isa(obj.MinCard, 'function_handle')
    minCard = obj.MinCard(featVal);
else
    minCard = obj.MinCard;
end
if minCard > 0,
    minCard = min(numel(r), minCard);
    selected(1:minCard) = true;
end

if isa(obj.MaxCard, 'function_handle'),
    maxCard = obj.MaxCard(featVal);
else
    maxCard = obj.MaxCard;
end

if maxCard < Inf,
    selected((maxCard+1):end) = false;
end
obj = select_component(obj, selected);

end