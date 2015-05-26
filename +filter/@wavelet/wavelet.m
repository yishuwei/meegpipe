classdef wavelet < ...
        filter.dfilt             & ...
        goo.verbose              & ...
        goo.abstract_setget      & ...
        goo.abstract_named_object
    % WAVELET - A wrapper for MATLAB's wden (Wavelet toolbox required)
    %
    %
    %   myFilter = filter.wavelet(wavelet_name, levels)
    %
    %   Default to Daubechies order 4 wavelet (db4), 8 levels
    %
    
    properties (SetAccess = private, GetAccess = public)
        WName;
        NbLevels;
    end
    
    methods
        % filter.dfilt interface
        [y, obj] = filter(obj, x, varargin);
        
        function [y, obj] = filtfilt(obj, x, varargin)
            
            [y, obj] = filter(obj, x, varargin{:});
            
        end
        
        % Constructor    
        function obj = wavelet(WName, NbLevels, varargin)
            
            import misc.process_arguments;
            
            if nargin < 1, WName = 'db4'; end
            if nargin < 2, NbLevels = 8; end
            
            opt.Name = 'wavelet';
            opt.Verbose = true;
            [~, opt] = process_arguments(opt, varargin);
            
            obj.WName = WName;
            obj.NbLevels = NbLevels;
            obj = set_name(obj, opt.Name);
            obj = set_verbose(obj, opt.Verbose);
            
        end
        
        
    end
    
    
end
