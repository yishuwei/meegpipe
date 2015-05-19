classdef optimized_filter < meegpipe.node.filter.filter
    % FILTER - Apply digital filter to node input
    % Filter data in 300,000-sample chunks by default
    % Chunks are filtered in memory (no copy of pset)
    % Use fir_ic to reduce border artefacts
    
    % meegpipe.node.node interface
    
    properties
        MaxChunkSamples;
    end
    
    methods
        [data, dataNew] = process(obj, data, varargin)
    end
    
    % Constructor
    methods
        function obj = optimized_filter(varargin)
            import misc.prepend_varargin;
            import misc.split_arguments;
            import misc.process_arguments;
            
            opt.MaxChunkSamples = 300000;
            [thisArgs, varargin] = split_arguments(fieldnames(opt), varargin);
            [~, opt] = process_arguments(opt, thisArgs);
            
            dataSel = pset.selector.good_data;
            varargin = prepend_varargin(varargin, 'DataSelector', dataSel);       
            obj = obj@meegpipe.node.filter.filter(varargin{:});
            
            if nargin > 0 && isa(varargin{1},'meegpipe.node.filter.optimized_filter'),
                % copy construction: keep everything like it is
                obj.MaxChunkSamples = varargin{1}.MaxChunkSamples;
                return;
            end
            
            obj.MaxChunkSamples = opt.MaxChunkSamples;
            
            if isempty(get_name(obj)),
                filtObj = get_config(obj, 'Filter');
                if isempty(filtObj),
                    obj = set_name(obj, 'filter');
                elseif isa(filtObj, 'filter.dfilt') && ...
                        ~isempty(get_name(filtObj)),
                    obj = set_name(obj, ['filter-' get_name(filtObj)]);
                else
                    set_name(obj, 'filter');
                end
            end
            
        end
    end
    
    
end
