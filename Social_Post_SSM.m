function Social_Post_SSM(outputdir)
%run post-ssm analysis on Social Approach data
% Jan 2023 mw
% designed to run on talapas from a batch script that passes directory
% names as absolute paths

local_movie_root = '/home/wehr/wehrlab/save_OEablationSocial';
cd /home/wehr/wehrlab/save_OEablationSocial/param_search

copyfile('training_data.mat', outputdir)

cd(outputdir)

% since we decimated ConvertGeometryToObservations, now we un-decimate the Z returned by the hmm
fprintf('\nundecimating...')
load ssm_posterior_probs
td=load('training_data');
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


PlotPosteriorProbs(outputdir)
PrintFigs(outputdir)
PruneTPM(outputdir)
PlotTPM(outputdir)
PrintFigs(outputdir)
PlotEPM_Social(outputdir) %I still need to change azimuths to sin/cosine and convert back to angles
PrintFigs(outputdir)
PlotStateTracksSocial(outputdir)
PrintFigs(outputdir)


GenerateStateEpochClips(outputdir, local_movie_root)
TileVideoClips(outputdir)
%  LabelMovieStates(outputdir)
% PlotStatePSTH(outputdir)

