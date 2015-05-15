classdef fir_ic < ...
        filter.dfilt             & ...
        goo.verbose              & ...
        goo.abstract_setget      & ...
        goo.abstract_named_object
    % BA - A generic digital filter built from B and A coefficients
    %
    % Adapted from filter.ba
    %
    % This filter handles chunked signals by passing around initial/final
    % conditions.
    %
    %
    % ## CAUTION: DOES NOT CORRECT FOR DELAY! TAKE CARE FOR DELAY MANUALLY
    %
    %
    % ## CONSTRUCTION
    %
    %   myFilter = filter.fir_ic(b)
    %
    
    properties (SetAccess = private, GetAccess = public)
        B;
        A = 1;
    end
    
    methods
        % filter.dfilt interface
        [y, z] = filter(obj, x, zi, varargin);
        
        function [y, z] = filtfilt(obj, x, varargin)
            if nargin < 3
                [y, z] = filter(obj, x, []);
            else
                [y, z] = filter(obj, x, varargin{:});
            end
        end
        
        % In order to be used in combination with filter.cascade
        function H = mdfilt(obj)
            H = dfilt.df1(obj.B, obj.A);
        end
        
        function delay = get_filter_delay(obj)
            delay = ceil((numel(obj.B) - 1)/2);
        end
        
        % Constructor    
        function obj = fir_ic(b, varargin)
            
            import misc.process_arguments;
            
            if nargin < 1, return; end
            
            opt.Name = 'fir_ic';
            opt.Verbose = true;
            [~, opt] = process_arguments(opt, varargin);
            
            obj.B = b;
            obj = set_name(obj, opt.Name);
            obj = set_verbose(obj, opt.Verbose);
            
        end
        
        
    end
    
    
end
