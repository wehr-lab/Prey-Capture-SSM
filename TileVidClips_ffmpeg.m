function TileVidClips_ffmpeg(outputdir)
%Usage: TileVidClips_ffmpeg(folder)
%load all video clips in folder and tile them into a composite video(s)
% writes output video to the same folder
%
% This is basically the same as TileVidClips but uses ffmpeg and it's 300x
% faster.
% not sure what happens if not all epochs have the same duration 
%
% 4x4 is the only option I have implemented so far

ffmpeg_path='/usr/local/bin/ffmpeg';

if nargin==0 outputdir=pwd;end
cd(outputdir)

desired_output_fps=30; %just affects playback of composite video
maximum_frames_per_clip=inf; %set this to truncate very long outlier clips if desired
multiple_pages=1; %if there are more clips than will fit in the array, set to 1 to spread across multiple output video files


% scan directory for number of clips
% you will probably need specify the filename pattern you used to extract the clips (e.g.
% clip_1.mp4, clip_2.mp4, etc) if it's different than clip*.*
d=dir(sprintf('clip*.*'));
d=natsortfiles(d);
num_clips=length(d);
max_num_clips=16;


for page_num=1:ceil(num_clips/max_num_clips) %multiple pages loop
    if page_num==1 | multiple_pages %if multiple_pages=1 do all pages, otherwise only do page 1
        fprintf('\npage %d', page_num);
        out_movie_filename=sprintf('mosaic4x4_%d.mp4', page_num);
        infilestr=[];
        for k=1+(page_num-1)*max_num_clips:page_num*max_num_clips
            if k<=length(d)
                infilestr=[infilestr sprintf(' -i %s', d(k).name)];
            else
                % in_movie_filename=[]; %not enough clips to fill array, should fill with grey panels%
            end
        end

        % str=sprintf('!/usr/local/bin/ffmpeg %s  -filter_complex " [0:v]scale=480x270[v01]; [1:v]scale=480x270[v02]; [2:v]scale=480x270[v03]; [3:v]scale=480x270[v04];  [4:v]scale=480x270[v05]; [5:v]scale=480x270[v06]; [6:v]scale=480x270[v07]; [7:v]scale=480x270[v08];  [8:v]scale=480x270[v09]; [9:v]scale=480x270[v10]; [10:v]scale=480x270[v11]; [11:v]scale=480x270[v12];  [12:v]scale=480x270[v13]; [13:v]scale=480x270[v14]; [14:v]scale=480x270[v15]; [15:v]scale=480x270[v16];  [v01][v02][v03][v04]xstack=inputs=4:layout=0_0|w0_0|w0+w1_0|w0+w1+w2_0[row1];  [v05][v06][v07][v08]xstack=inputs=4:layout=0_0|w0_0|w0+w1_0|w0+w1+w2_0[row2];  [v09][v10][v11][v12]xstack=inputs=4:layout=0_0|w0_0|w0+w1_0|w0+w1+w2_0[row3];  [v13][v14][v15][v16]xstack=inputs=4:layout=0_0|w0_0|w0+w1_0|w0+w1+w2_0[row4]; [row1][row2][row3][row4]vstack=inputs=4[final]" -map "[final]" -map 0:a? -map 1:a? -map 2:a? -map 3:a? -map 4:a? -map 5:a? -map 6:a? -map 7:a? -map 8:a? -map 9:a? -map 10:a? -map 11:a? -map 12:a? -map 13:a? -map 14:a? -map 15:a? -c:v libx264 -preset veryfast -crf 23 mosaic4x4.mp4 ', fstr);
        str=sprintf('!/usr/local/bin/ffmpeg %s  -y -filter_complex " [0:v]scale=480x270[v01]; [1:v]scale=480x270[v02]; [2:v]scale=480x270[v03]; [3:v]scale=480x270[v04];  [4:v]scale=480x270[v05]; [5:v]scale=480x270[v06]; [6:v]scale=480x270[v07]; [7:v]scale=480x270[v08];  [8:v]scale=480x270[v09]; [9:v]scale=480x270[v10]; [10:v]scale=480x270[v11]; [11:v]scale=480x270[v12];  [12:v]scale=480x270[v13]; [13:v]scale=480x270[v14]; [14:v]scale=480x270[v15]; [15:v]scale=480x270[v16];  [v01][v02][v03][v04]xstack=inputs=4:layout=0_0|w0_0|w0+w1_0|w0+w1+w2_0[row1];  [v05][v06][v07][v08]xstack=inputs=4:layout=0_0|w0_0|w0+w1_0|w0+w1+w2_0[row2];  [v09][v10][v11][v12]xstack=inputs=4:layout=0_0|w0_0|w0+w1_0|w0+w1+w2_0[row3];  [v13][v14][v15][v16]xstack=inputs=4:layout=0_0|w0_0|w0+w1_0|w0+w1+w2_0[row4]; [row1][row2][row3][row4]vstack=inputs=4[final]" -map "[final]" -c:v libx264 -preset veryfast -crf 23 %s', infilestr, out_movie_filename);
        tic
        eval(str)
        fprintf('\nwrote %s in %.0f sec\n', out_movie_filename, toc)
    end %if multiple pages
end %page loop



% 
% 
% %make a grey dummy frame of the right size
% % movie_filename=d(1).name;
% % vobj=VideoReader(movie_filename);
% % dummy= read(vobj, 1);
% % dummy=uint8(128*ones(size(dummy)));
% 
% 
% 
% % Main working loop.
% % tile the clips into comp video
% % This could be either 3x3, 4x4, etc
% tic
% fprintf('\nTiling video clips...')
% switch arraysize
%     case '3x3'
%         max_num_clips=9;
%         for page_num=1:ceil(num_clips/max_num_clips) %multiple pages loop
%             if page_num==1 | multiple_pages %if multiple_pages=1 do all pages, otherwise only do page 1
%                 out_movie_fullfilename=fullfile(outputdir, sprintf('comp%s_%d', arraysize, page_num));
%                 vout = VideoWriter(out_movie_fullfilename);
%                 vout.FrameRate=desired_output_fps;
%                 open(vout);
%                 clear v
%                 j=0;
%                 nbytes =  fprintf('\npage %d, reading clip %d', page_num, 0);
%                 for k=1+(page_num-1)*max_num_clips:page_num*max_num_clips
%                     fprintf(repmat('\b',1,nbytes))
%                     nbytes =  fprintf('\npage %d, reading clip %d', page_num, k);
%                     j=j+1;
%                     if k<=length(d)
%                         in_movie_filename=fullfile(outputdir, d(k).name);
%                     else
%                         in_movie_filename=[]; %not enough clips to fill array, should fill with grey panels
%                     end
%                     try
%                         v{j} = VideoReader(in_movie_filename);
%                     catch
%                         v{j}=[];
%                     end
%                 end
%                 maxnumframes=snumframes(1);
%                 maxnumframes=min(maxnumframes, maximum_frames_per_clip); %trim if requested
%                 fprintf('\nwriting ')
%                 nbytes = fprintf(' frame 0 of %d', maxnumframes);
%                 for f=1:maxnumframes
%                     fprintf(repmat('\b',1,nbytes))
%                     nbytes = fprintf('\tframe %d of %d', f, maxnumframes);
%                     for  ei=1:max_num_clips
%                         if isempty(v{ei})
%                             vidFrame=dummy;
%                             %there is no clip, this epoch doesn't exist
%                         else
%                             if hasFrame(v{ei})
%                                 vidFrame = readFrame(v{ei}) ;
%                             else %loop or grey out (use dummy)
%                                 %vidFrame=dummy; %grey out
%                                 %or loop as follows:
%                                 %we reached the end, so rewind and start over
%                                 v{ei}.CurrentTime=0;
%                                 vidFrame = readFrame(v{ei}) ;
%                             end
%                         end
%                         [h,w,c]=size(vidFrame);
%                         if  ei==1
%                             newFrame(1:h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==2
%                             newFrame(1:h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==3
%                             newFrame(1:h, 2*w+1:3*w,:)=vidFrame;
% 
%                         elseif ei==4
%                             newFrame(h+1:2*h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==5
%                             newFrame(h+1:2*h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==6
%                             newFrame(h+1:2*h, 2*w+1:3*w,:)=vidFrame;
% 
%                         elseif ei==7
%                             newFrame(2*h+1:3*h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==8
%                             newFrame(2*h+1:3*h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==9
%                             newFrame(2*h+1:3*h, 2*w+1:3*w,:)=vidFrame;
% 
%                         end
%                     end
%                     writeVideo(vout,newFrame)
%                 end
%                 close(vout)
%                 fprintf('\nwrote %s\n', vout.Filename)
%                 %ffmpeg convert from avi to mp4
%                 str=sprintf('[status]=system(''%s -hide_banner -loglevel warning -stats -y -i %s -c:v libx264 -pix_fmt yuv420p %s'');', ffmpeg_path, vout.Filename, replace(vout.Filename, '.avi', '.mp4'));
%                 eval(str) %fails silently if the ffmpeg system call doesn't work, you just won't see an mp4 output file
%                 if ~status fprintf('\nwrote %s', replace(vout.Filename, '.avi', '.mp4')); end
%                 if delete_avifiles delete(vout.Filename), end
%             end %if multiple pages
%         end %page loop
% 
%     case '4x4'
%         max_num_clips=16;
%         for page_num=1:ceil(num_clips/max_num_clips) %multiple pages loop
%             if page_num==1 | multiple_pages %if multiple_pages=1 do all pages, otherwise only do page 1
%                 out_movie_fullfilename=fullfile(outputdir, sprintf('comp%s_%d', arraysize, page_num));
%                 vout = VideoWriter(out_movie_fullfilename);
%                 vout.FrameRate=desired_output_fps;
%                 open(vout);
%                 clear v
%                 j=0;
%                 nbytes =  fprintf('\npage %d, reading clip %d', page_num, 0);
%                 for k=1+(page_num-1)*max_num_clips:page_num*max_num_clips
%                     fprintf(repmat('\b',1,nbytes))
%                     nbytes =  fprintf('\npage %d, reading clip %d', page_num, k);
%                     j=j+1;
%                     if k<=length(d)
%                         in_movie_filename=fullfile(outputdir, d(k).name);
%                     else
%                         in_movie_filename=[]; %not enough clips to fill array, should fill with grey panels
%                     end
%                     try
%                         v{j} = VideoReader(in_movie_filename);
%                     catch
%                         v{j}=[];
%                     end
%                 end
%                 maxnumframes=snumframes(1);
%                 maxnumframes=min(maxnumframes, maximum_frames_per_clip); %trim if requested
%                 fprintf('\nwriting ')
%                 nbytes = fprintf('\tframe 0 of %d', maxnumframes);
%                 for f=1:maxnumframes
%                     fprintf(repmat('\b',1,nbytes))
%                     nbytes = fprintf(' frame %d of %d', f, maxnumframes);
%                     for  ei=1:max_num_clips
%                         if isempty(v{ei})
%                             vidFrame=dummy;
%                             %there is no clip, this epoch doesn't exist
%                         else
%                             if hasFrame(v{ei})
%                                 vidFrame = readFrame(v{ei}) ;
%                             else
%                                 %vidFrame=dummy;
%                                 %we reached the end, so rewind and start over
%                                 v{ei}.CurrentTime=0;
%                                 vidFrame = readFrame(v{ei}) ;
%                             end
%                         end
%                         [h,w,c]=size(vidFrame);
%                         if  ei==1
%                             newFrame(1:h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==2
%                             newFrame(1:h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==3
%                             newFrame(1:h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==4
%                             newFrame(1:h, 3*w+1:4*w,:)=vidFrame;
% 
%                         elseif ei==5
%                             newFrame(h+1:2*h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==6
%                             newFrame(h+1:2*h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==7
%                             newFrame(h+1:2*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==8
%                             newFrame(h+1:2*h, 3*w+1:4*w,:)=vidFrame;
% 
%                         elseif ei==9
%                             newFrame(2*h+1:3*h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==10
%                             newFrame(2*h+1:3*h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==11
%                             newFrame(2*h+1:3*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==12
%                             newFrame(2*h+1:3*h, 3*w+1:4*w,:)=vidFrame;
% 
%                         elseif ei==13
%                             newFrame(3*h+1:4*h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==14
%                             newFrame(3*h+1:4*h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==15
%                             newFrame(3*h+1:4*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==16
%                             newFrame(3*h+1:4*h, 3*w+1:4*w,:)=vidFrame;
% 
%                         end
%                     end
%                     writeVideo(vout,newFrame)
%                 end
%                 close(vout)
%                 fprintf('\nwrote %s\n', vout.Filename)
%                 %ffmpeg convert from avi to mp4
% %                str=sprintf('[status]=system(''%s -hide_banner -loglevel warning -nostats -y -i %s -c:v libx264 -pix_fmt yuv420p %s'');', ffmpeg_path, vout.Filename, replace(vout.Filename, '.avi', '.mp4'));
%                 str=sprintf('[status]=system(''%s -hide_banner -loglevel warning -nostats -y -i %s -c:v libx264 -pix_fmt yuv420p -vf scale=1920:-1 -r 30 %s'');', ffmpeg_path, vout.Filename, replace(vout.Filename, '.avi', '.mp4'));
%                 eval(str) %fails silently if the ffmpeg system call doesn't work, you just won't see an mp4 output file
%                 if ~status fprintf('\nwrote %s', replace(vout.Filename, '.avi', '.mp4')); end
%                 if delete_avifiles delete(vout.Filename), end
%             end %if multiple pages
%         end %page loop
% 
% 
%     case '5x5'
%         max_num_clips=25;
%         for page_num=1:ceil(num_clips/max_num_clips) %multiple pages loop
%             if page_num==1 | multiple_pages %if multiple_pages=1 do all pages, otherwise only do page 1
%                 out_movie_fullfilename=fullfile(outputdir, sprintf('comp%s_%d', arraysize, page_num));
%                 vout = VideoWriter(out_movie_fullfilename);
%                 vout.FrameRate=desired_output_fps;
%                 open(vout);
%                 clear v
%                 j=0;
%                 nbytes =  fprintf('\npage %d, reading clip %d', page_num, 0);
%                 for k=1+(page_num-1)*max_num_clips:page_num*max_num_clips
%                     fprintf(repmat('\b',1,nbytes))
%                     nbytes =  fprintf('\npage %d, reading clip %d', page_num, k);
%                     j=j+1;
%                     if k<=length(d)
%                         in_movie_filename=fullfile(outputdir, d(k).name);
%                     else
%                         in_movie_filename=[]; %not enough clips to fill array, should fill with grey panels
%                     end
%                     try
%                         v{j} = VideoReader(in_movie_filename);
%                     catch
%                         v{j}=[];
%                     end
%                 end
%                 maxnumframes=snumframes(1);
%                 maxnumframes=min(maxnumframes, maximum_frames_per_clip); %trim if requested
%                 fprintf('\nwriting ')
%                 nbytes = fprintf('\tframe 0 of %d', maxnumframes);
%                 for f=1:maxnumframes
%                     fprintf(repmat('\b',1,nbytes))
%                     nbytes = fprintf(' frame %d of %d', f, maxnumframes);
%                     for  ei=1:max_num_clips
%                         if isempty(v{ei})
%                             vidFrame=dummy;
%                             %there is no clip, this epoch doesn't exist
%                         else
%                             if hasFrame(v{ei})
%                                 vidFrame = readFrame(v{ei}) ;
%                             else
%                                 %vidFrame=dummy;
%                                 %we reached the end, so rewind and start over
%                                 v{ei}.CurrentTime=0;
%                                 vidFrame = readFrame(v{ei}) ;
%                             end
%                         end
%                         [h,w,c]=size(vidFrame);
%                         if  ei==1
%                             newFrame(1:h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==2
%                             newFrame(1:h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==3
%                             newFrame(1:h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==4
%                             newFrame(1:h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==5
%                             newFrame(1:h, 4*w+1:5*w,:)=vidFrame;
% 
%                         elseif ei==6
%                             newFrame(h+1:2*h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==7
%                             newFrame(h+1:2*h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==8
%                             newFrame(h+1:2*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==9
%                             newFrame(h+1:2*h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==10
%                             newFrame(h+1:2*h, 4*w+1:5*w,:)=vidFrame;
% 
%                         elseif ei==11
%                             newFrame(2*h+1:3*h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==12
%                             newFrame(2*h+1:3*h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==13
%                             newFrame(2*h+1:3*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==14
%                             newFrame(2*h+1:3*h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==15
%                             newFrame(2*h+1:3*h, 4*w+1:5*w,:)=vidFrame;
% 
%                         elseif ei==16
%                             newFrame(3*h+1:4*h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==17
%                             newFrame(3*h+1:4*h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==18
%                             newFrame(3*h+1:4*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==19
%                             newFrame(3*h+1:4*h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==20
%                             newFrame(3*h+1:4*h, 4*w+1:5*w,:)=vidFrame;
% 
%                         elseif ei==21
%                             newFrame(4*h+1:5*h, 0*w+1:1*w,:)=vidFrame;
%                         elseif ei==22
%                             newFrame(4*h+1:5*h, 1*w+1:2*w,:)=vidFrame;
%                         elseif ei==23
%                             newFrame(4*h+1:5*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==24
%                             newFrame(4*h+1:5*h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==25
%                             newFrame(4*h+1:5*h, 4*w+1:5*w,:)=vidFrame;
%                         end
%                     end
%                     writeVideo(vout,newFrame)
%                 end
%                 close(vout)
%                 fprintf('\nwrote %s\n', vout.Filename)
%                 %ffmpeg convert from avi to mp4
%                 % str=sprintf('[status]=system(''%s -hide_banner -loglevel warning -stats -y -i %s -c:v libx264 -pix_fmt yuv420p %s'');', ffmpeg_path, vout.Filename, replace(vout.Filename, '.avi', '.mp4'));
%                 str=sprintf('[status]=system(''%s -hide_banner -loglevel warning -nostats -y -i %s -c:v libx264 -pix_fmt yuv420p %s'');', ffmpeg_path, vout.Filename, replace(vout.Filename, '.avi', '.mp4'));
%               % −y  automatically overwrite, -nostats suppress progress reporting
%                 eval(str) %fails silently if the ffmpeg system call doesn't work, you just won't see an mp4 output file
%                 if ~status fprintf('\nwrote %s', replace(vout.Filename, '.avi', '.mp4')); end
%                 if delete_avifiles delete(vout.Filename), end
%             end %if multiple pages
%         end %page loop
% 
%     case '6x6'
%         max_num_clips=36;
%         for page_num=1:ceil(num_clips/max_num_clips) %multiple pages loop
%             if page_num==1 | multiple_pages %if multiple_pages=1 do all pages, otherwise only do page 1
%                 out_movie_fullfilename=fullfile(outputdir, sprintf('comp%s_%d', arraysize, page_num));
%                 vout = VideoWriter(out_movie_fullfilename);
%                 vout.FrameRate=desired_output_fps;
%                 open(vout);
%                 clear v
%                 j=0;
%                 nbytes =  fprintf('\npage %d, reading clip %d', page_num, 0);
%                 for k=1+(page_num-1)*max_num_clips:page_num*max_num_clips
%                     fprintf(repmat('\b',1,nbytes))
%                     nbytes =  fprintf('\npage %d, reading clip %d', page_num, k);
%                     j=j+1;
%                     if k<=length(d)
%                         in_movie_filename=fullfile(outputdir, d(k).name);
%                     else
%                         in_movie_filename=[]; %not enough clips to fill array, should fill with grey panels
%                     end
%                     try
%                         v{j} = VideoReader(in_movie_filename);
%                     catch
%                         v{j}=[];
%                     end
%                 end
%                 maxnumframes=snumframes(1);
%                 maxnumframes=min(maxnumframes, maximum_frames_per_clip); %trim if requested
%                 fprintf('\nwriting ')
%                 nbytes = fprintf('\tframe 0 of %d', maxnumframes);
%                 for f=1:maxnumframes
%                     fprintf(repmat('\b',1,nbytes))
%                     nbytes = fprintf(' frame %d of %d', f, maxnumframes);
%                     for  ei=1:max_num_clips
%                         if isempty(v{ei})
%                             vidFrame=dummy;
%                             %there is no clip, this epoch doesn't exist
%                         else
%                             if hasFrame(v{ei})
%                                 vidFrame = readFrame(v{ei}) ;
%                             else
%                                 %vidFrame=dummy;
%                                 %we reached the end, so rewind and start over
%                                 v{ei}.CurrentTime=0;
%                                 vidFrame = readFrame(v{ei}) ;
%                             end
%                         end
%                         [h,w,c]=size(vidFrame);
%                         if  ei==1
%                             newFrame(1:h, 1:w,:)=vidFrame;
%                         elseif ei==2
%                             newFrame(1:h, w+1:2*w,:)=vidFrame;
%                         elseif ei==3
%                             newFrame(1:h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==4
%                             newFrame(1:h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==5
%                             newFrame(1:h, 4*w+1:5*w,:)=vidFrame;
%                         elseif ei==6
%                             newFrame(1:h, 5*w+1:6*w,:)=vidFrame;
% 
% 
%                         elseif ei==7
%                             newFrame(h+1:2*h, 1:w,:)=vidFrame;
%                         elseif ei==8
%                             newFrame(h+1:2*h, w+1:2*w,:)=vidFrame;
%                         elseif ei==9
%                             newFrame(h+1:2*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==10
%                             newFrame(h+1:2*h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==11
%                             newFrame(h+1:2*h, 4*w+1:5*w,:)=vidFrame;
%                         elseif ei==12
%                             newFrame(h+1:2*h, 5*w+1:6*w,:)=vidFrame;
% 
%                         elseif ei==13
%                             newFrame(2*h+1:3*h, 1:w,:)=vidFrame;
%                         elseif ei==14
%                             newFrame(2*h+1:3*h, w+1:2*w,:)=vidFrame;
%                         elseif ei==15
%                             newFrame(2*h+1:3*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==16
%                             newFrame(2*h+1:3*h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==17
%                             newFrame(2*h+1:3*h, 4*w+1:5*w,:)=vidFrame;
%                         elseif ei==18
%                             newFrame(2*h+1:3*h, 5*w+1:6*w,:)=vidFrame;
% 
%                         elseif ei==19
%                             newFrame(3*h+1:4*h, 1:w,:)=vidFrame;
%                         elseif ei==20
%                             newFrame(3*h+1:4*h, w+1:2*w,:)=vidFrame;
%                         elseif ei==21
%                             newFrame(3*h+1:4*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==22
%                             newFrame(3*h+1:4*h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==23
%                             newFrame(3*h+1:4*h, 4*w+1:5*w,:)=vidFrame;
%                         elseif ei==24
%                             newFrame(3*h+1:4*h, 5*w+1:6*w,:)=vidFrame;
% 
%                         elseif ei==25
%                             newFrame(4*h+1:5*h, 1:w,:)=vidFrame;
%                         elseif ei==26
%                             newFrame(4*h+1:5*h, w+1:2*w,:)=vidFrame;
%                         elseif ei==27
%                             newFrame(4*h+1:5*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==28
%                             newFrame(4*h+1:5*h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==29
%                             newFrame(4*h+1:5*h, 4*w+1:5*w,:)=vidFrame;
%                         elseif ei==30
%                             newFrame(4*h+1:5*h, 5*w+1:6*w,:)=vidFrame;
% 
%                         elseif ei==31
%                             newFrame(5*h+1:6*h, 1:w,:)=vidFrame;
%                         elseif ei==32
%                             newFrame(5*h+1:6*h, w+1:2*w,:)=vidFrame;
%                         elseif ei==33
%                             newFrame(5*h+1:6*h, 2*w+1:3*w,:)=vidFrame;
%                         elseif ei==34
%                             newFrame(5*h+1:6*h, 3*w+1:4*w,:)=vidFrame;
%                         elseif ei==35
%                             newFrame(5*h+1:6*h, 4*w+1:5*w,:)=vidFrame;
%                         elseif ei==36
%                             newFrame(5*h+1:6*h, 5*w+1:6*w,:)=vidFrame;
%                         end
%                     end
%                     writeVideo(vout,newFrame)
%                 end
%                 close(vout)
%                 fprintf('\nwrote %s\n', vout.Filename)
%                 %ffmpeg convert from avi to mp4
%                 str=sprintf('[status]=system(''%s -hide_banner -loglevel warning -stats -y -i %s -c:v libx264 -pix_fmt yuv420p %s'');', ffmpeg_path, vout.Filename, replace(vout.Filename, '.avi', '.mp4'));
%                 eval(str) %fails silently if the ffmpeg system call doesn't work, you just won't see an mp4 output file
%                 if ~status fprintf('\nwrote %s', replace(vout.Filename, '.avi', '.mp4')); end
%                 if delete_avifiles delete(vout.Filename), end
%             end %if multiple pages
%         end %page loop
% end
% 
% fprintf('\n')
% toc
% 
% 
% 
% 
% % resample to lower fps if desired
% %note that you can't trust the reported video object FrameRates, they might all be 30 fps
% if 0
%     orig_fps=vout.FrameRate;
%     fps=orig_fps/5; %downsampled fps
%     newmoviefilename= sprintf('%s-%dfps.%s',out_movie_fullfilename, fps, ext);
%     str=sprintf('!/usr/local/bin/ffmpeg  -i "%s.%s" -r %d "%s"', out_movie_fullfilename, ext, fps, newmoviefilename);
%     eval(str)
% end
% 
% % reduce resolution to 1920p (full HD)
% %   because sometimes the nxns are so big they won't play smoothly
% if 0
%     newmoviefilename= replace(out_movie_fullfilename, '.', '-1920.');
%     str=sprintf('!/usr/local/bin/ffmpeg  -i "%s" -vf scale=1920:-1 "%s"', out_movie_fullfilename, newmoviefilename);
%     eval(str)
% end
% 
% %reduce resolution to 1920p AND resample to 30 fps
% if 0
%     d=dir('comp*.mp4');
%     for i=1:length(d)
%         newmoviefilename= replace(d(i).name, '.', '-1920-30fps.');
%         str=sprintf('!/usr/local/bin/ffmpeg  -i "%s" -nostats -vf scale=1920:-1 -r 30 "%s"', d(i).name, newmoviefilename);
%         eval(str)
%     end
% end
% 
