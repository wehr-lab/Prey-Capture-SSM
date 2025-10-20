function ExtractVideoClip(movfilename, startframe, numframes, outputdir, outputfilename, keyframe)
%extracts frames from a video and writes them to a new video
% usage: ExtractVideoClip(movfilename, startframe, numframes, outputdir, outputfilename, keyframe)
%        movfilename should be an absolute path, 
%        outputfilename is local to outputdir
%        keyframe is a number between 1 and numframes, to plot a marker (e.g. to reference the time of an event, if your clips starts before the event)
%        


v = VideoReader(movfilename);
vidFrames = read(v, [startframe startframe+numframes-1]);

if 0 %if desired, add text with clip name, which takes an extra couple seconds 
    for f=1:numframes
        vidFrames(:,:,:, f) = insertText(vidFrames(:,:,:, f),[20,125],outputfilename,...
            'FontSize',48, 'BoxColor', 'g',  ...
            'BoxOpacity',0.0,'TextColor','red');
    end
end
if 1 %if desired, add keyframe marker 
    if nargin==6
        for f=0:9
            vidFrames(:,:,:, keyframe+f) = insertShape(vidFrames(:,:,:, keyframe+f),"filled-circle",[v.Width-90,90 80], ShapeColor=["green"]);
            %keyframe marker is an 80-pixel green dot in upper right corner for 10 frames
        end
    end
        vidFrames(:,:,:, 1) = insertText(vidFrames(:,:,:, f),[20,125],outputfilename,...
            'FontSize',48, 'BoxColor', 'g',  ...
            'BoxOpacity',0.0,'TextColor','red');

end

out_movie_fullfilename=fullfile(outputdir, outputfilename);

vout = VideoWriter(out_movie_fullfilename, 'MPEG-4');
open(vout)
writeVideo(vout,vidFrames)
close(vout)
clear v

