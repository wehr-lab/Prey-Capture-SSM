% convert all-states avis to mp4s with ffmpeg


movieroot='/Volumes/Projects/Social Approach/save_OEablationSocial/param_search'



cd(movieroot)
d=dir('state-epoch-clips-2023*');
for i=1:length(d)
    d2=dir(sprintf('%s/all_states*.avi', d(i).name));
    for j=1:length(d2)
        
        moviefilename=fullfile(d2(j).folder, d2(j).name);
        fps=30; %desired fps
        %targetdir='"/Users/wehr/Documents/Presentations/UCSC 2022/videos/"';
        newmoviefilename=replace(moviefilename, '.mp4.avi', sprintf('-%dfps.mp4', fps));
        x5moviefilename=replace(newmoviefilename, '.mp4', 'x5.mp4');
        
        %ffmpeg
        %str=sprintf('!/usr/local/bin/ffmpeg  -i %s -r %d %s', moviefilename, fps, newmoviefilename);
        str=sprintf('!/usr/local/bin/ffmpeg  -i "%s" -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" -r %d "%s"', moviefilename, fps, newmoviefilename);
        fprintf('\n%s', str)
        eval(str)
                 
%         str=sprintf('!/usr/local/bin/ffmpeg  -i "%s" -filter:v "setpts=0.2*PTS" "%s"', newmoviefilename, x5moviefilename);
%         eval(str)
        
        %move to new target dir
        % str=sprintf('!mv %s %s', newmoviefilename, targetdir);
        % eval(str)
        % str=sprintf('!mv %s %s', x5moviefilename, targetdir);
        % eval(str)
        %
        % cd(erase(targetdir, '"'))
        
    end
end