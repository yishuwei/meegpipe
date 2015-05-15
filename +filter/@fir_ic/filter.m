function [y, z] = filter(obj, x, zi, varargin)

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

delay = get_filter_delay(obj);

if 5*delay > size(x, 2),
    error(['Signal length (%d) must be at least 5 times as long as the ' ...
        'filter (%d)'], size(x,2), delay);
end


if isempty(zi) || isnan(zi)
    thisX = [fliplr(x(:, 1:(2*delay))) x];
    [y, z] = filter(obj.B, obj.A, thisX');
    y = y((2*delay+1):end, :);
else
    [y, z] = filter(obj.B, obj.A, x', zi);
end

if verbose
    eta(tinit, size(x,1), size(x,1), 'remaintime', false);
    fprintf('\n\n'); 
    clear +misc/eta;
end

y=y';

end