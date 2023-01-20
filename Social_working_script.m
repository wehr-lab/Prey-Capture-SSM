%Social working script
% mw 1-20-23

%might have to load Prefs/keyboard/windows default set each time

local_movie_root='/gpfs/projects/wehrlab/wehr/save_OEablationSocial';
cd '/gpfs/projects/wehrlab/wehr/save_OEablationSocial/state_epoch_clips-19-Jan-2023-20-1e14-20'


%cd into target directory first. then:
outputdir=pwd;

if 0
    PlotPosteriorProbs(outputdir)
PrintFigs(outputdir)
PruneTPM(outputdir)
PlotTPM(outputdir)
PrintFigs(outputdir)
PlotEPM_Social(outputdir) %I still need to change azimuths to sin/cosine and convert back to angles
PrintFigs(outputdir)
end

GenerateStateEpochClips(outputdir, local_movie_root)
TileVideoClips(outputdir)
% LabelMovieStates(outputdir)
%PlotStatePSTH(outputdir)
