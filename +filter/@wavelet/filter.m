function [x, obj] = filter(obj, x, varargin)

import misc.eta;

verbose         = is_verbose(obj) && size(x,1) > 10;
verboseLabel 	= get_verbose_label(obj);


if verbose,
    fprintf( [verboseLabel, 'Filtering %d signals...'], size(x,1));
end

if verbose,
    tinit = tic;
    clear +misc/eta;
end


for i = 1:size(x,1),
   
    dc = x(i,1);   
    y = wden(x(i,:)-dc,'sqtwolog','s','mln', obj.NbLevels, obj.WName) + dc;
    x(i,:) = y;    
    
    
    if verbose,
        eta(tinit, size(x,1), i, 'remaintime', false);
    end
    
end

if verbose, 
    fprintf('\n\n'); 
    clear +misc/eta;
end

end