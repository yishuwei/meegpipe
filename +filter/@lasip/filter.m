function [data, obj] = filter(obj, data, varargin)

import misc.eta;
import misc.resample;

verbose         = is_verbose(obj);
verboseLabel    = get_verbose_label(obj);

%% Do the actual filtering
tinit = tic;
if verbose,
    if isa(data, 'goo.named_object') || isa(data, 'goo.named_object_handle'),
        name = get_name(data);
    else
        name = '';
    end
    fprintf([verboseLabel, 'LPA Filtering %s...'], name);
end

warning('off', 'MATLAB:oldPfileVersion');

dataD = nan(size(data,1), ceil(size(data,2)/obj.Decimation));
for i = 1:size(dataD, 1)
    if ~all(abs(data(i,:)-mean(data(i,:))) < eps),
        
        if obj.Decimation > 1,
            dataDi = downsample(data(i,:), obj.Decimation);
        else
            dataDi = data(i,:);
        end
        dataD(i, :) = lasip1d(dataDi, ...
            obj.Order, ...
            obj.Scales, ...
            obj.Gamma, ...
            obj.WindowType, ...
            obj.WeightsMedian, ...
            obj.ExpandBoundary);
    end
    if verbose,
        eta(tinit, size(dataD, 1), i, 'remaintime', true);
    end
end
warning('on', 'MATLAB:oldPfileVersion');

if verbose,
    fprintf('\n\n');
    clear misc.eta;
end

%% Interpolation
if obj.Decimation > 1,
    
    if verbose,
        if isa(dataD, 'physioset.physioset'),
            name = get_name(dataD);
        else
            name = '';
        end
        fprintf([verboseLabel, 'Interpolating %s...'], name);
    end
    x  = 1:obj.Decimation:size(data, 2);
    xi = 1:size(data, 2);
    tinit = tic;
    for i = 1:size(data,1)
        
        if ~any(isnan(dataD(i,:))),
            yi = interp1(x, dataD(i,:), xi, obj.InterpMethod);
            
            % Take care of the border effects (use 1% as "border epoch")
            diffSig = abs(data(i,:) - yi);
            medDiff = median(diffSig);
            madDiff = mad(diffSig);
            
            idx = find(diffSig > (medDiff + 30*madDiff));
            
            if ~isempty(idx),
                
                firstBndry = max(idx(idx < ceil(0.01*size(data,2))));
                lastBndry = min(idx(idx > (size(data,2) - ...
                    floor(0.01*size(data,2)))));
                
                if ~isempty(firstBndry),
                    weights = [ones(1, firstBndry) linspace(1, 0, firstBndry)];
                    yi(1:numel(weights)) = weights.*data(i,1:numel(weights)) + ...
                        (1-weights).*yi(1:numel(weights));
                end
                
                if ~isempty(lastBndry),
                    bndryLength = size(data,2) - lastBndry + 1;
                    weights = [linspace(0, 1, bndryLength) ones(1, bndryLength)];
                    yi(end-numel(weights)+1:end) = ...
                        weights.*data(i,end-numel(weights)+1:end) + ...
                        (1-weights).*yi(end-numel(weights)+1:end);
                end
            end
            
            % Check if the variance threshold has been exceeded
            varRatio = 100*var(yi)/var(data(i,:));
            
            if obj.GetNoise
                if (varRatio > obj.VarTh),
                    data(i, :) = data(i, :) - yi;
                end
            elseif varRatio > obj.VarTh
                data(i, :) = yi;
            else
                data(i,:) = 0;
            end
            
        end
        
        if verbose,
            eta(tinit, size(data, 1), i, 'remaintime', true);
        end
    end
    
else
    
    for i = 1:size(data,1)
        if any(isnan(dataD(i, :))),
            warning('filter:NaN', ['Filter output for channel %d ' ...
                'contains NaNs: the channel will not be filtered'], i);
            continue;
        end

        % Check if the variance threshold has been exceeded
        varRatio = var(dataD(i,:))/var(data(i,:));
        
        if obj.GetNoise
            if varRatio > obj.VarTh,
                data(i,:) = data(i,:) - dataD(i,:);
            end
        elseif varRatio > obj.VarTh
            data(i,:) = dataD(i,:);
        else
            data(i,:) = 0;
        end
   
    end
    
end

if verbose,
    fprintf('\n\n');
    clear misc.eta;
end

end