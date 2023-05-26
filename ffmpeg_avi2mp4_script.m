% convert avis to mp4s with ffmpeg

%moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save_OEablation/2022-10-27_10-40-12_mouse-1211';
% moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save_OEablation/2022-10-27_10-42-48_mouse-1211';

%moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save_OEablationSocial/2022-10-28_14-15-42_mouse-1141';
%moviedir='/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Kip/save_OEablation/2022-10-20_18-45-10_mouse-1142'

movieroot='/home/wehr/wehrlab/save_OEablationSocial/param_search'



cd(movieroot)
d=dir('state-epoch-clips-2023*');
for i=1:length(d)
    d2=dir(sprintf('%s/ssm_state_vid-comp*', d(i).name));
    for j=1:length(d2)
        
        moviefilename=fullfile(d2(j).folder, d2(j).name);
        fps=30; %desired fps
        %targetdir='"/Users/wehr/Documents/Presentations/UCSC 2022/videos/"';
        newmoviefilename=replace(moviefilename, '.avi', sprintf('-%dfps.mp4', fps));
        x5moviefilename=replace(moviefilename, '.mp4', sprintf('-%dfps5x.mp4', fps));
        
        %ffmpeg
        %str=sprintf('!/usr/local/bin/ffmpeg  -i %s -r %d %s', moviefilename, fps, newmoviefilename);
        str=sprintf('!ffmpeg  -i %s -r %d %s', moviefilename, fps, newmoviefilename);
        fprintf('\n%s', str)
        eval(str)
                 
        str=sprintf('!ffmpeg  -i %s -filter:v "setpts=0.2*PTS" %s', newmoviefilename, x5moviefilename);
        %eval(str)
        
        %move to new target dir
        % str=sprintf('!mv %s %s', newmoviefilename, targetdir);
        % eval(str)
        % str=sprintf('!mv %s %s', x5moviefilename, targetdir);
        % eval(str)
        %
        % cd(erase(targetdir, '"'))
        
    end
end