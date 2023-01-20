%Social working script
% mw 1-20-23

%cd into target directory first. then:
outputdir=pwd;

PlotPosteriorProbs(outputdir)
PrintFigs(outputdir)
PruneTPM(outputdir)
PlotTPM(outputdir)
PrintFigs(outputdir)
PlotEPM_Social(outputdir) %I still need to change azimuths to sin/cosine and convert back to angles
PrintFigs(outputdir)

%GenerateStateEpochClips(outputdir, local_movie_root)
%TileVideoClips(outputdir)
% LabelMovieStates(outputdir)
%PlotStatePSTH(outputdir)
