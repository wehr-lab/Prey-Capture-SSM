function ExtractVideoClip(movfilename, startframe, numframes, outputdir, outputfilename)
%extracts frames from a video and writes them to a new video
% usage: ExtractVideoClip(movfilename, startframe, numframes, outputdir, outputfilename)
%        movfilename should be an absolute path, 
%        outputfilename is local to outputdir

v = VideoReader(movfilename);
j=0;
for f=startframe:startframe+numframes-1
    j=j+1;
    vidFrames(:,:,:, j) = read(v, f) ;
end
out_movie_fullfilename=fullfile(outputdir, outputfilename);

vout = VideoWriter(out_movie_fullfilename, 'MPEG-4');
open(vout)
writeVideo(vout,vidFrames)
close(vout)

