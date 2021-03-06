function myPipe = create_pipeline(varargin)

myNode1 = meegpipe.node.physioset_import.new(...
    'Importer', physioset.import.eeglab);

myNode2 = aar.eog.regression('Order', 5);

myNode3 = meegpipe.node.physioset_export.new('Exporter', ...
    physioset.export.eeglab);

myPipe = meegpipe.node.pipeline.new(...
    'NodeList',         {myNode1, myNode2, myNode3}, ...
    'GenerateReport',   true, ...
    'Name', 'eog_removal_with_export');
end