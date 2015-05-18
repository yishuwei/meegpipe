function [data, dataNew] = process(obj, data, varargin)
% PROCESS - Main processing method for filter nodes

import goo.globals;
import misc.eta;
import meegpipe.node.filter.filter;

dataNew = [];

verbose         = is_verbose(obj);
verboseLabel    = get_verbose_label(obj);

%% Configuration options
filtObj         = get_config(obj, 'Filter');
retRes          = get_config(obj, 'ReturnResiduals');
nbChannelsRep   = get_config(obj, 'NbChannelsReport');
% epochDurRep     = get_config(obj, 'EpochDurReport');
showDiffRep     = get_config(obj, 'ShowDiffReport');
pca             = get_config(obj, 'PCA');

if isa(filtObj, 'function_handle'),
    try
        filtObj = filtObj(data.SamplingRate);
    catch ME
        if strcmp(ME.identifier, 'MATLAB:nonStrucReference'),
            filtObj = filtObj(data);
        else
            rethrow(ME);
        end        
    end
end

if isa(filtObj,'filter.ba') && numel(filtObj.A)==1
    filtObj = filter.fir_ic(filtObj.B);
elseif isprop(filtObj,'BAFilter') && numel(filtObj.BAFilter.A)==1
    filtObj = filter.fir_ic(filtObj.BAFilter.B);
end

if isa(filtObj,'filter.fir_ic')
    delay = get_filter_delay(filtObj);
    z = [];
end


%% Find chop boundaries
chunkDur = obj.MaxChunkSamples;
chunkSample = 1:chunkDur:size(data,2);


tinit = tic;
if verbose,
    clear +misc/eta.m;
end

%% Select a representative set of channels for the report
if do_reporting(obj)
    
    if nbChannelsRep > 0,
        channelSel = ceil(linspace(1, size(data,1), nbChannelsRep+1));
        channelSel = unique(channelSel);
        channelSel = channelSel(1:end-1);
    else
        channelSel = [];
    end
    
    iterSel = linspace(1, numel(chunkSample), 5);
    iterSel = unique([floor(iterSel) ceil(iterSel)]);
    
    rep = get_report(obj);
    print_title(rep, 'Data processing report', get_level(rep) + 1);
end

%% Filter each segment separately
for segItr = 1:numel(chunkSample)
    
    if verbose && numel(chunkSample) > 1,
        
        fprintf( [verboseLabel ...
            '%s filtering for epoch %d/%d...\n\n'], ...
            get_name(filtObj), segItr, numel(chunkSample));
        origVerboseLabel = globals.get.VerboseLabel;
        globals.set('VerboseLabel', ['\t' origVerboseLabel]);
        
    end
    
    first = chunkSample(segItr);
    last  = min(chunkSample(segItr)+chunkDur-1, size(data,2));

    %filtObj = set_verbose(filtObj, false);
    
    if do_reporting(obj) && ismember(segItr, iterSel)
        thisRep = childof(report.generic.generic, rep);
        % Set the title of this (sub-)report
        if numel(chunkSample) > 1,
            % Multiple chops
            title  =  sprintf('Window %d/%d: %4.1f-%4.1f secs', ...
                segItr, ...
                numel(chunkSample), ...
                get_sampling_time(data, first), ... % Time of first sample
                get_sampling_time(data, last)...    % Time of last sample
                );
        else
            % All data at once
            title = 'Filtering report';
        end
        set_title(thisRep, title);
        initialize(thisRep);
        print_link2report(rep, thisRep);
        
    end
    
    %% Project to PCS, if required
    select(data, 1:size(data,1), first:last);
    if ~isempty(pca),
        if verbose,
            fprintf([verboseLabel 'PCA decomposition...\n\n']);
        end
        pca = learn(pca, data);
        pcs = proj(pca, data(:,:));
    else
        pcs = data(:,:);
    end
    
    %% Filter every principal component
    if verbose,
        if isempty(pca),
            pcsStr = 'channel(s)';
        else
            pcsStr = 'principal component(s)';
        end
        fprintf([verboseLabel 'Filtering %d %s with %s filter...\n\n'], ...
            size(pcs,1), pcsStr, class(filtObj));
    end
    
    if isa(filtObj,'filter.fir_ic')
        [pcs, z] = filtfilt(filtObj, pcs, z);
        
        % Delay correction
        if segItr == 1
            first_d = first;
            pcs = pcs(:,delay+1:end);
        else
            first_d = first - delay;
        end
        
        if segItr == numel(chunkSample)
            last_d = last;
            pcs = [pcs z(1:delay,:)'];
        else
            last_d = last - delay;
        end

        restore_selection(data);
        select(data, 1:size(data,1), first_d:last_d);
        
    else
        pcs = filtfilt(filtObj, pcs);
    end
    
    %% Filter the actual data channels
    if ~isempty(pca),
        pcs = bproj(pca, pcs);
    end
    
    if do_reporting(obj) && ismember(segItr, iterSel)
        if verbose,
            fprintf([verboseLabel 'Generating report for %d channels ...'], ...
                numel(channelSel));
        end
        tinit2 = tic;
        chanCount = 0;
        galleryArray = {};
        for i = channelSel
            
            select(data, i);
            
            % Select a subset of data for the report
%             sr = data.SamplingRate;
%             epochDur = floor(epochDurRep*sr);
%             if epochDur >= evDur(segItr),
%                 firstRepSampl = 1;
%                 lastRepSampl  = evDur(segItr);
%             else
%                 firstRepSampl = randi(evDur(segItr)-epochDur);
%                 lastRepSampl  = firstRepSampl + epochDur - 1;
%             end
            
            firstRepSampl = 1;
            lastRepSampl  = size(data,2);
            
            % Get the begin/end time for the reported epoch
            samplTime = get_sampling_time(data, [firstRepSampl lastRepSampl]);
            select(data, [], firstRepSampl:lastRepSampl);
            attach_figure(obj);
            galleryArray = filter.generate_filt_plot(thisRep, ...
                i, ...
                data, ...
                pcs(i, firstRepSampl:lastRepSampl), ...
                samplTime, ...
                galleryArray, ...
                showDiffRep ...
                );
            restore_selection(data); % plotted epoch time range
            
            restore_selection(data);  % data channel
            
            chanCount = chanCount + 1;
            if verbose,
                eta(tinit2, numel(channelSel), chanCount, 'remaintime', true);
            end
            
        end
    end
    
    if retRes,
        data = data - pcs;
    else
        data(:,:) = pcs;
    end
    
    restore_selection(data);
    
    if verbose, fprintf('\n\n'); end
    
    if do_reporting(obj) && ismember(segItr, iterSel)
        for i = 1:numel(galleryArray),
            fprintf(thisRep, galleryArray{i});
        end
    end
    
    if verbose && numel(chunkSample) > 1,
        clear +misc/eta.m;
        verboseLabel = origVerboseLabel;
        globals.set('VerboseLabel', verboseLabel);
        
        fprintf( [verboseLabel, ...
            'done %s filtering epoch %d/%d...'], get_name(filtObj), ...
            segItr, numel(chunkSample));
        
        eta(tinit, numel(chunkSample), segItr, 'remaintime', true);
        fprintf('\n\n');
    end
    
end

if verbose,
    clear +misc/eta.m;
end


end
