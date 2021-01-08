%Main workflow for running SSM on prey capture data
% Oct 2020 mw

% machine-specific settings
switch char(java.net.InetAddress.getLocalHost.getHostName)
    case 'Transporter.local'
        % path and filename(s) of group data with DLC tracks
        groupdatadir='/Users/mikewehr/Documents/Analysis/PreyCapture data';
        groupdatafilename{1}='preycapture_groupdata_saline_1.mat'; %cell array of filenames
        %root directory for source movies
        local_movie_root='/Users/mikewehr/Documents/Analysis/PreyCapture data/';
        %output directory for results and generated video clips
        outputroot='/Users/mikewehr/Documents/Analysis/PreyCapture data';
        %local path to python3
        pypath='/usr/local/bin/python3';
    case 'DESKTOP-4NTC7RV'
        % path and filename(s) of group data with DLC tracks
        groupdatadir='C:\Users\Kat\Resilio Sync\Prey Capture\';
        groupdatafilename{1}='preycapture_groupdata_saline_1.mat'; %cell array of filenames
        local_movie_root='C:\Users\Kat\Resilio Sync\Prey Capture\source videos\';
        %output directory for results and generated video clips
        outputroot='C:\Users\Kat\Resilio Sync\Prey Capture\';
        %local path to python3
        pypath='C:\Users\Kat\python'
        %'/usr/local/bin/anaconda3.exe';
    otherwise
        fprintf('don''t recognize computer %s', java.net.InetAddress.getLocalHost.getHostName)
        return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% let's try to keep everything else machine-independent
    
%make a new output directory with today's date:
outputdir=sprintf('%s%sstate_epoch_clips-%s',outputroot, filesep, datestr(today));
%OR
%use an existing output directory
%outputdir=sprintf('%s%sstate_epoch_clips-%s',outputroot, filesep, datestr('10-10-2020'));

cd(outputroot)
mkdir(outputdir)
cd(outputdir)
output_data = ConvertTracksToObservations(groupdatadir, groupdatafilename, outputdir);

[repositorydir,~,~]=fileparts(which(mfilename));
ssmfilename=fullfile(repositorydir, 'ssm_preycap_posterior.py');

%run hmm python code in a system shell
cmdstr=sprintf('%s %s', pypath, ssmfilename);
%system(cmdstr)

PlotPosteriorProbs(outputdir)

PruneTPM(outputdir)
GenerateStateEpochClips(local_movie_root, outputdir)
TileVideoClips(outputdir)


