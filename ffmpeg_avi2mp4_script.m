% convert avis to mp4s with ffmpeg

%moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save_OEablation/2022-10-27_10-40-12_mouse-1211';
% moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save_OEablation/2022-10-27_10-42-48_mouse-1211';

%moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save_OEablationSocial/2022-10-28_14-15-42_mouse-1141';
%moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save_OEablation/2022-10-20_18-45-10_mouse-1142'

moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save/2021-10-07_15-16-41_mouse-0602'

moviedir=    '/Volumes/Projects/PreyCapture/A1Suppression/save-deafening/2022-09-09_9-37-01_mouse-1211'


cd(moviedir)
d=dir('Sky*labeled.mp4');
moviefilename=d(1).name;
fps=30; %desired fps
targetdir='"/Users/wehr/Documents/Presentations/UCSC 2022/videos/"';
newmoviefilename=replace(moviefilename, '.mp4', sprintf('-%dfps.mp4', fps));
x5moviefilename=replace(moviefilename, '.mp4', sprintf('-%dfps5x.mp4', fps));

%ffmpeg
str=sprintf('!/usr/local/bin/ffmpeg  -i %s -r %d %s', moviefilename, fps, newmoviefilename);
eval(str)

str=sprintf('!/usr/local/bin/ffmpeg  -i %s -filter:v "setpts=0.2*PTS" %s', newmoviefilename, x5moviefilename);
eval(str)
%ffmpeg -i Sky_mouse-1211_2022-10-27T10_40_12-30fps.mp4 -filter:v "setpts=0.5*PTS" Sky_mouse-1211_2022-10-27T10_40_12-30fpsFF.mp4

%move to new target dir
str=sprintf('!mv %s %s', newmoviefilename, targetdir);
eval(str)
str=sprintf('!mv %s %s', x5moviefilename, targetdir);
eval(str)

cd(erase(targetdir, '"'))

% % OE ablation social
% moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save_OEablationSocial/2022-10-26_19-10-00_mouse-1141';
% moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save_OEablationSocial/2022-10-28_14-15-42_mouse-1141';
