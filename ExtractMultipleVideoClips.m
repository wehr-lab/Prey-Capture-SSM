function ExtractMultipleVideoClips(movfilename, startframes, numframes, outputdir, outputfilename)
% handles multiple startframes and numframes from the same video 
% (startframes and numframes must be of the same length)
% requires outputfilename to end in '_numeric' (e.g. _01) that will be incremented for
% each successive clip after the first one
%
% extracts frames from a video and writes them to a new video
% usage: ExtractVideoClip(movfilename, startframe, numframes, outputdir, outputfilename)
%        movfilename should be an absolute path,
%        outputfilename is local to outputdir

n = strfind(outputfilename,'_');
if isempty(n)
    fprintf('ERROR: outputfilename requires ending in _d\n')
    help ExtractMultipleVideoClips
    return
else
    n = n(end);
    outputfilenumber = str2double(outputfilename(n+1:end));
    if isempty(outputfilenumber)
        outputfilenumber = 1;
    end
    outputfilename = outputfilename(1:n);
end

v = VideoReader(movfilename);

for iClip = 1: length(startframes)
    if numframes(iClip) < 4000      % having trouble with clips that are too long
        % clear vidFrames
        % j=0;
        % for f=startframes(iClip):startframes(iClip)+numframes(iClip)-1
        %     j=j+1;
        %     vidFrames(:,:,:, j) = read(v, f) ;
        % end

        vidFrames = read(v,[startframes(iClip) startframes(iClip)+numframes(iClip)-1]);
        out_movie_fullfilename=fullfile(outputdir, [outputfilename num2str(outputfilenumber+iClip)]);

        vout = VideoWriter(out_movie_fullfilename, 'MPEG-4');
        open(vout)
        writeVideo(vout,vidFrames)
        close(vout)
    end
end

clear v
