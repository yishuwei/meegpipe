function galArray = generate_filt_plot(rep, channelIdx, data1, data2, xTime, galArray, showDiff)


import meegpipe.node.globals;
import mperl.file.spec.catfile;
import misc.unique_filename;
import plot2svg.plot2svg;
import inkscape.svg2png;
import misc.resample;

% Maximum length in point of the time series that will be plotted
MAX_LENGTH = 20000;
LINE_WIDTH = globals.get.LineWidth;

if isempty(galArray),
    gal = clone(globals.get.Gallery);
    gal = set_title(gal, 'Filter input vs filter output');
    galArray = {gal};
end
if showDiff && numel(galArray) < 2,
    % An additional gallery showing the filter input vs the different
    % input and output
    gal = clone(globals.get.Gallery);
    gal = set_title(gal, 'Filter input vs difference input-output');
    galArray = [galArray {gal}];
end

visible = globals.get.VisibleFigures;
if visible,
    visibleStr = 'on';
else
    visibleStr = 'off';
end

if isa(data1,'physioset.physioset')
    time_begin = get_sampling_time(data1, 1);
    time_end = get_sampling_time(data1, size(data1,2));
elseif isa(data2,'physioset.physioset')
    time_begin = get_sampling_time(data1, 1);
    time_end = get_sampling_time(data1, size(data1,2));
else
    time_begin = xTime(1);
    time_end = xTime(2);
end

% IMPORTANT: The current statble version of Inkscape (0.48.2) crashes when
% attempting to convert very large .svg files to .png. The downsampling
% here is to prevent the inkscape crash, but anyways it's a good idea to
% downsample for making the svg to png conversion faster.
Q = ceil(size(data1,2)/MAX_LENGTH);
data1 = resample(data1(:,:)', 1, Q);
data2 = resample(data2(:,:)', 1, Q);
% Realize that only the first and last sampling instants in samplTime 
% below are guaranteed to be correct. The reason is that sampling instants
% do not need to be contiguous (e.g. due to data selections). 
samplTime = linspace(time_begin, time_end, size(data1,1));

for i=1:numel(channelIdx)
idx = channelIdx(i);

figure('Visible', visibleStr);
plot(samplTime, data1(:,i), 'k', 'LineWidth', LINE_WIDTH);
hold on;
plot(samplTime, data2(:,i), 'r', 'LineWidth', 0.75*LINE_WIDTH);
xlim(xTime);
xlabel('Time from beginning of recording (s)');
ylabel(['Channel ' num2str(idx)]);

% Print to .svg and .png format
rootPath = get_rootpath(rep);
fileName = catfile(rootPath, ['filt-report-channel' num2str(idx) '.svg']);
fileName = unique_filename(fileName);
evalc('plot2svg(fileName, gcf);');
svg2png(fileName);

close;

caption = ['Filter input (black) vs output (red) for channel ' num2str(idx)];
galArray{1} = add_figure(galArray{1}, fileName, caption);

if showDiff,
    
    figure('Visible', visibleStr);
    plot(samplTime, data1(:,i), 'k', 'LineWidth', LINE_WIDTH);
    hold on;
    plot(samplTime, data1(:,i)-data2(:,i), 'r', 'LineWidth', 0.75*LINE_WIDTH);
    xlim(xTime);
    xlabel('Time from beginning of recording (s)');
    ylabel(['Channel ' num2str(idx)]);
    
    % Print to .svg and .png format
    rootPath = get_rootpath(rep);
    fileName = catfile(rootPath, ['filt-report-channel' num2str(idx) '.svg']);
    fileName = unique_filename(fileName);
    evalc('plot2svg(fileName, gcf);');
    svg2png(fileName);
    
    close;
    caption = ['Raw data (black), and input/output difference (red) ' ...
        'for channel ' num2str(idx)];
    
    galArray{2} = add_figure(galArray{2}, fileName, caption);
   
end

end
end