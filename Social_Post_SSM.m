function Social_Post_SSM(outputdir)
%run post-ssm analysis on Social Approach data
% Jan 2023 mw
% designed to run on talapas from a batch script that passes directory
% names as absolute paths

fprintf('\nSocial_Post_SSM %s',outputdir)


%talapas specific
addpath /home/wehr/wehrlab/Prey-Capture-SSM
local_movie_root = '/home/wehr/wehrlab/save_OEablationSocial';
cd /home/wehr/wehrlab/save_OEablationSocial/param_search

%mac
%cd ("/Volumes/Projects/Social Approach/save_OEablationSocial/param_search")

copyfile('training_data.mat', outputdir)

cd(outputdir)

% since we decimated ConvertGeometryToObservations, now we un-decimate the Z returned by the hmm
load ssm_posterior_probs
td=load('training_data');
if exist('Zundec')==1
    fprintf('\nalready undecimated.')
else
    fprintf('\nundecimating...')
    post_probs=Ps{1};
    j=0;
    for i=1:length(Z)
        post_probs_undec(j+1:j+td.decimate_factor,:)=repmat(post_probs(i,:),td.decimate_factor,1);
        Zundec(j+1:j+td.decimate_factor)=Z(i);
        j=j+td.decimate_factor;
    end
    Zundec=Zundec(1:length(td.undecX));
    post_probs_undec=post_probs_undec(1:length(td.undecX),:);
    save ssm_posterior_probs Ps  TM Z Zundec post_probs post_probs_undec hmm_lls num_states obs_dim run_from run_on ...
        transitions kappa AR_lags observation_class
end

if exist('./pruned_tpm.mat', 'file')~=2
    PlotPosteriorProbs(outputdir)
    PrintFigs(outputdir)
    PruneTPM(outputdir)
    PlotTPM(outputdir)
    PrintFigs(outputdir)
    PlotEPM_Social(outputdir) %I still need to change azimuths to sin/cosine and convert back to angles
    PrintFigs(outputdir)
    PlotStateTracksSocial_2018(outputdir) %talapas uses matlab r2018
    PrintFigs(outputdir)
end

load pruned_tpm.mat

%do we have as many avis as we expect already?
d=dir([outputdir, '/*.avi']);
exp_num_avis=0;
for k=1:pruned_num_states
    for e=1:min(25, pruned_epochs(k).num_epochs)
        exp_num_avis=exp_num_avis+1;
    end
end
fprintf('\nfound %d avi files in this directory', length(d))

if length(d)>=exp_num_avis
    fprintf('\nalready found %d avi files in this directory, not doing any additional video processing', length(d))
else
    fprintf('\nonly found %d avi files in this directory, but expected at  least %d, proceeding with all video processing',  length(d), exp_num_avis)

    GenerateStateEpochClips(outputdir, local_movie_root)
    TileVideoClips(outputdir)
    %  LabelMovieStates(outputdir)
    % PlotStatePSTH(outputdir)
end
