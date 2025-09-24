function TileVidClips(outputdir)
%Usage: TileVidClips(folder)
%load all video clips in folder and tile them into a composite video(s)
% writes output video to the same folder
%
% if not all epochs have the same duration, you can either loop
% the shorter ones or grey them out when they're done


% matlab's VideoWriter is known to be buggy with mp4 (MPEG-4) output,
% because it is heavily dependent on the underlying video codecs and
% libraries installed on your operating system. This is why it may work on
% one computer but not another. Matlab's AVI profiles are much more robust.
% Yet, I like quicktime, which can only play mp4 (and not avi). My solution
% is to use matlab to generate avi files and then convert to mp4 with
% ffmpeg. That way I can play mp4s, or you can play avi with your favorite
% player if you prefer. However, you'll have to specify your ffmpeg path.
ffmpeg_path='/usr/local/bin/ffmpeg';
delete_avifiles=1; %delete the avi files to save disk space if you don't want them

if nargin==0 outputdir=pwd;end
cd(outputdir)

desired_output_fps=200; %just affects playback of composite video
maximum_frames_per_clip=inf; %set this to truncate very long outlier clips if desired
multiple_pages=1; %if there are more clips than will fit in the array, set to 1 to spread across multiple output video files

arraysize='3x3';
%could be '3x3', '4x4', '5x5', '6x6'

fprintf('\ntiling clips in a %s array', arraysize);

% scan directory for number of clips
d=dir(sprintf('clip*.*'));
num_clips=length(d);


tic
% Scan video clips to get number of frames in each clip, and store them in NumFrames(k)
fprintf('\ngetting numFrames for %d clips...', num_clips)
try
    cd(outputdir)
    load NumFrames
    fprintf('\nloaded Numframes from file')
catch
    nbytes = fprintf(' %d', 0);
    for k=1:num_clips
        fprintf(repmat('\b',1,nbytes))
        nbytes = fprintf(' %d', k);
        movie_filename=d(k).name;
        vobj=VideoReader(movie_filename);
        NumFrames(k)=ceil(vobj.FrameRate*vobj.Duration);
        %note that mmfileinfo takes almost exactly as long
    end
    cd(outputdir)
    save NumFrames NumFrames
    toc
end
fprintf(' done\n')



%make a grey dummy frame of the right size
movie_filename=d(1).name;
vobj=VideoReader(movie_filename);
dummy= read(vobj, 1);
dummy=uint8(128*ones(size(dummy)));

%sort NumFrames from longest to shortest clip
[snumframes, snumframesi]=sort(NumFrames, 'descend');


% Main working loop.
% tile the clips into comp video
% This could be either 3x3, 4x4, etc
tic
fprintf('\nTiling video clips...')
switch arraysize
    case '3x3'
        max_num_clips=9;
        for page_num=1:ceil(num_clips/max_num_clips) %multiple pages loop
            if page_num==1 | multiple_pages %if multiple_pages=1 do all pages, otherwise only do page 1
                out_movie_fullfilename=fullfile(outputdir, sprintf('comp%s_%d', arraysize, page_num));
                vout = VideoWriter(out_movie_fullfilename);
                vout.FrameRate=desired_output_fps;
                open(vout);
                clear v
                j=0;
                nbytes =  fprintf('\npage %d, reading clip %d', page_num, 0);
                for k=1+(page_num-1)*max_num_clips:page_num*max_num_clips
                    fprintf(repmat('\b',1,nbytes))
                    nbytes =  fprintf('\npage %d, reading clip %d', page_num, k);
                    j=j+1;
                    if k<=length(d)
                        in_movie_filename=fullfile(outputdir, d(k).name);
                    else
                        in_movie_filename=[]; %not enough clips to fill array, should fill with grey panels
                    end
                    try
                        v{j} = VideoReader(in_movie_filename);
                    catch
                        v{j}=[];
                    end
                end
                maxnumframes=snumframes(1);
                maxnumframes=min(maxnumframes, maximum_frames_per_clip); %trim if requested
                fprintf('\nwriting ')
                nbytes = fprintf(' frame 0 of %d', maxnumframes);
                for f=1:maxnumframes
                    fprintf(repmat('\b',1,nbytes))
                    nbytes = fprintf('\tframe %d of %d', f, maxnumframes);
                    for  ei=1:max_num_clips
                        if isempty(v{ei})
                            vidFrame=dummy;
                            %there is no clip, this epoch doesn't exist
                        else
                            if hasFrame(v{ei})
                                vidFrame = readFrame(v{ei}) ;
                            else %loop or grey out (use dummy)
                                %vidFrame=dummy; %grey out
                                %or loop as follows:
                                %we reached the end, so rewind and start over
                                v{ei}.CurrentTime=0;
                                vidFrame = readFrame(v{ei}) ;
                            end
                        end
                        [h,w,c]=size(vidFrame);
                        if  ei==1
                            newFrame(1:h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==2
                            newFrame(1:h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==3
                            newFrame(1:h, 2*w+1:3*w,:)=vidFrame;

                        elseif ei==4
                            newFrame(h+1:2*h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==5
                            newFrame(h+1:2*h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==6
                            newFrame(h+1:2*h, 2*w+1:3*w,:)=vidFrame;

                        elseif ei==7
                            newFrame(2*h+1:3*h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==8
                            newFrame(2*h+1:3*h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==9
                            newFrame(2*h+1:3*h, 2*w+1:3*w,:)=vidFrame;

                        end
                    end
                    writeVideo(vout,newFrame)
                end
                close(vout)
                fprintf('\nwrote %s\n', vout.Filename)
                %ffmpeg convert from avi to mp4
                str=sprintf('[status]=system(''%s -hide_banner -loglevel warning -stats -y -i %s -c:v libx264 -pix_fmt yuv420p %s'');', ffmpeg_path, vout.Filename, replace(vout.Filename, '.avi', '.mp4'));
                eval(str) %fails silently if the ffmpeg system call doesn't work, you just won't see an mp4 output file
                if ~status fprintf('\nwrote %s', replace(vout.Filename, '.avi', '.mp4')); end
                if delete_avifiles delete(vout.Filename), end
            end %if multiple pages
        end %page loop

    case '4x4'
        max_num_clips=16;
        for page_num=1:ceil(num_clips/max_num_clips) %multiple pages loop
            if page_num==1 | multiple_pages %if multiple_pages=1 do all pages, otherwise only do page 1
                out_movie_fullfilename=fullfile(outputdir, sprintf('comp%s_%d', arraysize, page_num));
                vout = VideoWriter(out_movie_fullfilename);
                vout.FrameRate=desired_output_fps;
                open(vout);
                clear v
                j=0;
                nbytes =  fprintf('\npage %d, reading clip %d', page_num, 0);
                for k=1+(page_num-1)*max_num_clips:page_num*max_num_clips
                    fprintf(repmat('\b',1,nbytes))
                    nbytes =  fprintf('\npage %d, reading clip %d', page_num, k);
                    j=j+1;
                    if k<=length(d)
                        in_movie_filename=fullfile(outputdir, d(k).name);
                    else
                        in_movie_filename=[]; %not enough clips to fill array, should fill with grey panels
                    end
                    try
                        v{j} = VideoReader(in_movie_filename);
                    catch
                        v{j}=[];
                    end
                end
                maxnumframes=snumframes(1);
                maxnumframes=min(maxnumframes, maximum_frames_per_clip); %trim if requested
                fprintf('\nwriting ')
                nbytes = fprintf('\tframe 0 of %d', maxnumframes);
                for f=1:maxnumframes
                    fprintf(repmat('\b',1,nbytes))
                    nbytes = fprintf(' frame %d of %d', f, maxnumframes);
                    for  ei=1:max_num_clips
                        if isempty(v{ei})
                            vidFrame=dummy;
                            %there is no clip, this epoch doesn't exist
                        else
                            if hasFrame(v{ei})
                                vidFrame = readFrame(v{ei}) ;
                            else
                                %vidFrame=dummy;
                                %we reached the end, so rewind and start over
                                v{ei}.CurrentTime=0;
                                vidFrame = readFrame(v{ei}) ;
                            end
                        end
                        [h,w,c]=size(vidFrame);
                        if  ei==1
                            newFrame(1:h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==2
                            newFrame(1:h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==3
                            newFrame(1:h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==4
                            newFrame(1:h, 3*w+1:4*w,:)=vidFrame;

                        elseif ei==5
                            newFrame(h+1:2*h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==6
                            newFrame(h+1:2*h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==7
                            newFrame(h+1:2*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==8
                            newFrame(h+1:2*h, 3*w+1:4*w,:)=vidFrame;

                        elseif ei==9
                            newFrame(2*h+1:3*h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==10
                            newFrame(2*h+1:3*h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==11
                            newFrame(2*h+1:3*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==12
                            newFrame(2*h+1:3*h, 3*w+1:4*w,:)=vidFrame;

                        elseif ei==13
                            newFrame(3*h+1:4*h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==14
                            newFrame(3*h+1:4*h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==15
                            newFrame(3*h+1:4*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==16
                            newFrame(3*h+1:4*h, 3*w+1:4*w,:)=vidFrame;

                        end
                    end
                    writeVideo(vout,newFrame)
                end
                close(vout)
                fprintf('\nwrote %s\n', vout.Filename)
                %ffmpeg convert from avi to mp4
                str=sprintf('[status]=system(''%s -hide_banner -loglevel warning -stats -y -i %s -c:v libx264 -pix_fmt yuv420p %s'');', ffmpeg_path, vout.Filename, replace(vout.Filename, '.avi', '.mp4'));
                eval(str) %fails silently if the ffmpeg system call doesn't work, you just won't see an mp4 output file
                if ~status fprintf('\nwrote %s', replace(vout.Filename, '.avi', '.mp4')); end
                if delete_avifiles delete(vout.Filename), end
            end %if multiple pages
        end %page loop


    case '5x5'
        max_num_clips=25;
        for page_num=1:ceil(num_clips/max_num_clips) %multiple pages loop
            if page_num==1 | multiple_pages %if multiple_pages=1 do all pages, otherwise only do page 1
                out_movie_fullfilename=fullfile(outputdir, sprintf('comp%s_%d', arraysize, page_num));
                vout = VideoWriter(out_movie_fullfilename);
                vout.FrameRate=desired_output_fps;
                open(vout);
                clear v
                j=0;
                nbytes =  fprintf('\npage %d, reading clip %d', page_num, 0);
                for k=1+(page_num-1)*max_num_clips:page_num*max_num_clips
                    fprintf(repmat('\b',1,nbytes))
                    nbytes =  fprintf('\npage %d, reading clip %d', page_num, k);
                    j=j+1;
                    if k<=length(d)
                        in_movie_filename=fullfile(outputdir, d(k).name);
                    else
                        in_movie_filename=[]; %not enough clips to fill array, should fill with grey panels
                    end
                    try
                        v{j} = VideoReader(in_movie_filename);
                    catch
                        v{j}=[];
                    end
                end
                maxnumframes=snumframes(1);
                maxnumframes=min(maxnumframes, maximum_frames_per_clip); %trim if requested
                fprintf('\nwriting ')
                nbytes = fprintf('\tframe 0 of %d', maxnumframes);
                for f=1:maxnumframes
                    fprintf(repmat('\b',1,nbytes))
                    nbytes = fprintf(' frame %d of %d', f, maxnumframes);
                    for  ei=1:max_num_clips
                        if isempty(v{ei})
                            vidFrame=dummy;
                            %there is no clip, this epoch doesn't exist
                        else
                            if hasFrame(v{ei})
                                vidFrame = readFrame(v{ei}) ;
                            else
                                %vidFrame=dummy;
                                %we reached the end, so rewind and start over
                                v{ei}.CurrentTime=0;
                                vidFrame = readFrame(v{ei}) ;
                            end
                        end
                        [h,w,c]=size(vidFrame);
                        if  ei==1
                            newFrame(1:h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==2
                            newFrame(1:h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==3
                            newFrame(1:h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==4
                            newFrame(1:h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==5
                            newFrame(1:h, 4*w+1:5*w,:)=vidFrame;

                        elseif ei==6
                            newFrame(h+1:2*h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==7
                            newFrame(h+1:2*h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==8
                            newFrame(h+1:2*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==9
                            newFrame(h+1:2*h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==10
                            newFrame(h+1:2*h, 4*w+1:5*w,:)=vidFrame;

                        elseif ei==11
                            newFrame(2*h+1:3*h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==12
                            newFrame(2*h+1:3*h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==13
                            newFrame(2*h+1:3*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==14
                            newFrame(2*h+1:3*h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==15
                            newFrame(2*h+1:3*h, 4*w+1:5*w,:)=vidFrame;

                        elseif ei==16
                            newFrame(3*h+1:4*h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==17
                            newFrame(3*h+1:4*h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==18
                            newFrame(3*h+1:4*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==19
                            newFrame(3*h+1:4*h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==20
                            newFrame(3*h+1:4*h, 4*w+1:5*w,:)=vidFrame;

                        elseif ei==21
                            newFrame(4*h+1:5*h, 0*w+1:1*w,:)=vidFrame;
                        elseif ei==22
                            newFrame(4*h+1:5*h, 1*w+1:2*w,:)=vidFrame;
                        elseif ei==23
                            newFrame(4*h+1:5*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==24
                            newFrame(4*h+1:5*h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==25
                            newFrame(4*h+1:5*h, 4*w+1:5*w,:)=vidFrame;
                        end
                    end
                    writeVideo(vout,newFrame)
                end
                close(vout)
                fprintf('\nwrote %s\n', vout.Filename)
                %ffmpeg convert from avi to mp4
                str=sprintf('[status]=system(''%s -hide_banner -loglevel warning -stats -y -i %s -c:v libx264 -pix_fmt yuv420p %s'');', ffmpeg_path, vout.Filename, replace(vout.Filename, '.avi', '.mp4'));
                eval(str) %fails silently if the ffmpeg system call doesn't work, you just won't see an mp4 output file
                if ~status fprintf('\nwrote %s', replace(vout.Filename, '.avi', '.mp4')); end
                if delete_avifiles delete(vout.Filename), end
            end %if multiple pages
        end %page loop

    case '6x6'
        max_num_clips=36;
        for page_num=1:ceil(num_clips/max_num_clips) %multiple pages loop
            if page_num==1 | multiple_pages %if multiple_pages=1 do all pages, otherwise only do page 1
                out_movie_fullfilename=fullfile(outputdir, sprintf('comp%s_%d', arraysize, page_num));
                vout = VideoWriter(out_movie_fullfilename);
                vout.FrameRate=desired_output_fps;
                open(vout);
                clear v
                j=0;
                nbytes =  fprintf('\npage %d, reading clip %d', page_num, 0);
                for k=1+(page_num-1)*max_num_clips:page_num*max_num_clips
                    fprintf(repmat('\b',1,nbytes))
                    nbytes =  fprintf('\npage %d, reading clip %d', page_num, k);
                    j=j+1;
                    if k<=length(d)
                        in_movie_filename=fullfile(outputdir, d(k).name);
                    else
                        in_movie_filename=[]; %not enough clips to fill array, should fill with grey panels
                    end
                    try
                        v{j} = VideoReader(in_movie_filename);
                    catch
                        v{j}=[];
                    end
                end
                maxnumframes=snumframes(1);
                maxnumframes=min(maxnumframes, maximum_frames_per_clip); %trim if requested
                fprintf('\nwriting ')
                nbytes = fprintf('\tframe 0 of %d', maxnumframes);
                for f=1:maxnumframes
                    fprintf(repmat('\b',1,nbytes))
                    nbytes = fprintf(' frame %d of %d', f, maxnumframes);
                    for  ei=1:max_num_clips
                        if isempty(v{ei})
                            vidFrame=dummy;
                            %there is no clip, this epoch doesn't exist
                        else
                            if hasFrame(v{ei})
                                vidFrame = readFrame(v{ei}) ;
                            else
                                %vidFrame=dummy;
                                %we reached the end, so rewind and start over
                                v{ei}.CurrentTime=0;
                                vidFrame = readFrame(v{ei}) ;
                            end
                        end
                        [h,w,c]=size(vidFrame);
                        if  ei==1
                            newFrame(1:h, 1:w,:)=vidFrame;
                        elseif ei==2
                            newFrame(1:h, w+1:2*w,:)=vidFrame;
                        elseif ei==3
                            newFrame(1:h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==4
                            newFrame(1:h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==5
                            newFrame(1:h, 4*w+1:5*w,:)=vidFrame;
                        elseif ei==6
                            newFrame(1:h, 5*w+1:6*w,:)=vidFrame;


                        elseif ei==7
                            newFrame(h+1:2*h, 1:w,:)=vidFrame;
                        elseif ei==8
                            newFrame(h+1:2*h, w+1:2*w,:)=vidFrame;
                        elseif ei==9
                            newFrame(h+1:2*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==10
                            newFrame(h+1:2*h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==11
                            newFrame(h+1:2*h, 4*w+1:5*w,:)=vidFrame;
                        elseif ei==12
                            newFrame(h+1:2*h, 5*w+1:6*w,:)=vidFrame;

                        elseif ei==13
                            newFrame(2*h+1:3*h, 1:w,:)=vidFrame;
                        elseif ei==14
                            newFrame(2*h+1:3*h, w+1:2*w,:)=vidFrame;
                        elseif ei==15
                            newFrame(2*h+1:3*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==16
                            newFrame(2*h+1:3*h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==17
                            newFrame(2*h+1:3*h, 4*w+1:5*w,:)=vidFrame;
                        elseif ei==18
                            newFrame(2*h+1:3*h, 5*w+1:6*w,:)=vidFrame;

                        elseif ei==19
                            newFrame(3*h+1:4*h, 1:w,:)=vidFrame;
                        elseif ei==20
                            newFrame(3*h+1:4*h, w+1:2*w,:)=vidFrame;
                        elseif ei==21
                            newFrame(3*h+1:4*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==22
                            newFrame(3*h+1:4*h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==23
                            newFrame(3*h+1:4*h, 4*w+1:5*w,:)=vidFrame;
                        elseif ei==24
                            newFrame(3*h+1:4*h, 5*w+1:6*w,:)=vidFrame;

                        elseif ei==25
                            newFrame(4*h+1:5*h, 1:w,:)=vidFrame;
                        elseif ei==26
                            newFrame(4*h+1:5*h, w+1:2*w,:)=vidFrame;
                        elseif ei==27
                            newFrame(4*h+1:5*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==28
                            newFrame(4*h+1:5*h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==29
                            newFrame(4*h+1:5*h, 4*w+1:5*w,:)=vidFrame;
                        elseif ei==30
                            newFrame(4*h+1:5*h, 5*w+1:6*w,:)=vidFrame;

                        elseif ei==31
                            newFrame(5*h+1:6*h, 1:w,:)=vidFrame;
                        elseif ei==32
                            newFrame(5*h+1:6*h, w+1:2*w,:)=vidFrame;
                        elseif ei==33
                            newFrame(5*h+1:6*h, 2*w+1:3*w,:)=vidFrame;
                        elseif ei==34
                            newFrame(5*h+1:6*h, 3*w+1:4*w,:)=vidFrame;
                        elseif ei==35
                            newFrame(5*h+1:6*h, 4*w+1:5*w,:)=vidFrame;
                        elseif ei==36
                            newFrame(5*h+1:6*h, 5*w+1:6*w,:)=vidFrame;
                        end
                    end
                    writeVideo(vout,newFrame)
                end
                close(vout)
                fprintf('\nwrote %s\n', vout.Filename)
                %ffmpeg convert from avi to mp4
                str=sprintf('[status]=system(''%s -hide_banner -loglevel warning -stats -y -i %s -c:v libx264 -pix_fmt yuv420p %s'');', ffmpeg_path, vout.Filename, replace(vout.Filename, '.avi', '.mp4'));
                eval(str) %fails silently if the ffmpeg system call doesn't work, you just won't see an mp4 output file
                if ~status fprintf('\nwrote %s', replace(vout.Filename, '.avi', '.mp4')); end
                if delete_avifiles delete(vout.Filename), end
            end %if multiple pages
        end %page loop
end

fprintf('\n')
toc




% resample to lower fps if desired
%note that you can't trust the reported video object FrameRates, they might all be 30 fps
if 0
    orig_fps=vout.FrameRate;
    fps=orig_fps/5; %downsampled fps
    newmoviefilename= sprintf('%s-%dfps.%s',out_movie_fullfilename, fps, ext);
    str=sprintf('!/usr/local/bin/ffmpeg  -i "%s.%s" -r %d "%s"', out_movie_fullfilename, ext, fps, newmoviefilename);
    eval(str)
end




