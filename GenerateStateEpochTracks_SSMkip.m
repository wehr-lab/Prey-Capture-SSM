function GenerateStateEpochTracks_HHMM(outputdir)
% slice source videos into video clips for each state and epoch (up to some
% max num epochs)
%
% looks in the original data dirs (from pruned_tpm/datadirs) for the source videos
% then slices them into states and epochs based on
% pruned_tpm.mat generated by PruneTPM
%40 minutes on mac
%VideoReader can't read the mp4s on talapas

cd (outputdir)
load('pruned_tpm.mat')
    %rootdir= '/Users/wehr/Documents/Analysis/myHHMM/kip';

if nargin==0
    outputdir=sprintf('%s%sstate_epoch_tracks-%s',rootdir, filesep, datestr(today));
end

%hard coded for Kip's dataFrame
cd('/Volumes/Projects/PreyCapture/A1Suppression')
load dataFrame

%for PlotStateTracks
ptParam.transform = 'xaxis';%'none'; %'xaxis';
ptParam.MarkerSize = 10;
ptParam.alpha = .05;
% 
% cd (rootdir)
% load('pruned_tpm_5_5.mat')
%load('kip_data.mat')
%mkdir(outputdir)
%cd(outputdir)
%save pruned_tpm

ntrials = length(dataFrame);
States=struct;
for trial=1:ntrials
    for k=1:pruned_num_states
        framerange=[];
        for e=1: pruned_tpm{trial}.pruned_epochs(k).num_epochs
            startframe=pruned_tpm{trial}.pruned_epochs(k).starts(e); %these are relative to X
            stopframe=pruned_tpm{trial}.pruned_epochs(k).stops(e);
            framerange=[framerange startframe:stopframe];
        end
        States=setfield(States, sprintf('s%d',surviving_states(k)),{trial}, 'trial', trial);
        States=setfield(States, sprintf('s%d',surviving_states(k)),{trial}, 'framerange', framerange);

    end
end

States

fieldnames = fields(States);
numstates = size(fieldnames,1);
for statenum = 1:1%numstates
    StateName = fieldnames{statenum};
    [fig{statenum}] = PlotStateTracks(dataFrame,States.(StateName),ptParam);
    title(['State: ',num2str(statenum)]);
end










