function tracks = load_tracks(groupdatadir, groupdatafilename)

cd (groupdatadir)


tracks = {};

% iterate through the filenames we are given
for sourcefilenum=1:length(groupdatafilename)
    % create full path
    abs_path = fullfile(groupdatadir, groupdatafilename{sourcefilenum});
    
    % load data into return cell array
    tracks{sourcefilenum} = load(abs_path);
    
    % TODO: make data return without needing to know it is called
    % 'groupdata'
end

end

