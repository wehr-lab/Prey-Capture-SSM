function ExtractVideoClip_ffmpeg(movfilename, startframe, numframes, outputdir, outputfilename, keyframe)
%extracts frames from a video and writes them to a new video
% usage: ExtractVideoClip_ffmpeg(movfilename, startframe, numframes, outputdir, outputfilename, keyframe)
%        movfilename should be an absolute path, 
%        outputfilename is local to outputdir
%        keyframe is a number between 1 and numframes, to plot a marker (e.g. to reference the time of an event, if your clips starts before the event)
%        


str=sprintf('/usr/local/bin/ffprobe -v 0 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate %s', movfilename);
cmdstr=sprintf('[status,cmdout] = system(''%s'');', str);
eval(cmdstr)
fps=eval(cmdout);
starttime=startframe/fps;
clipname=outputfilename;
if ~endsWith(outputfilename, '.mp4')
    outputfilename=[outputfilename, '.mp4'];
end

% extract clip and add label, write to tmp.mp4
str=sprintf('!/usr/local/bin/ffmpeg -y -loglevel quiet -nostats -ss %f -i %s -vframes %d -vf "drawtext=text=''%s'':fontcolor=red:fontsize=48:x=10:y=10" %s', starttime, movfilename, numframes, clipname, fullfile(outputdir, 'tmp.mp4'));
eval(str)

%add green rectangle to indicate keyframe, write to output file
str=sprintf('!/usr/local/bin/ffmpeg -loglevel quiet -nostats -i %s -vf "drawbox=x=200:y=10:w=1140:h=1050:color=green@1.0:t=20:enable=''between(n,%d,%d)''" %s', fullfile(outputdir,'tmp.mp4'), keyframe, keyframe+20, fullfile(outputdir,outputfilename));
eval(str)
delete(fullfile(outputdir, 'tmp.mp4'))


