function tile_video_clips
%load video clips and tile them into composite video

% not all epochs have the same duration (obviously), so you can either loop
% the shorter ones or grey them out when they're done

%use this to process a previous run
state_epoch_clips_dir='state_epoch_clips-22-Jul-2020';
%use this for a new run (i.e. default to "today" directory):
%state_epoch_clips_dir=sprintf('state_epoch_clips-%s',datestr(today));

rootdir='/Users/mikewehr/Documents/Analysis/PreyCapture data';
%rootdir='\\Users\\Kat\\Resilio Sync\\Prey Capture\\matlab code July 2020\\'

cd( rootdir)
cd(state_epoch_clips_dir)

n=0;

arraysize='3x3';
%could be '3x3', '4x4', '5x5', '6x6'
fprintf('\ntiling clips in a %s array', arraysize);

% scan directory for clips to get number of states and epochs
%the ssm_state_epoch_clips were generated by cluster-state-clips.m
fprintf('\nscanning clips to get number of states and epochs...')
%note that k's can be skipped, perhaps because of no p>.8 occupancy? So
%just stopping when you can't find the next one will halt there
d=dir('ssm_state_epoch_clip-*.mp4');
for i=1:length(d)
    str=split(d(i).name, '-');
    allks(i)=str2num(str{2});
end
num_states=max(allks);
fprintf('\n%d states', num_states)

for k=1:num_states
    e=1;
    movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_epoch_clip-%d-%d.mp4', k, e));
    while exist(movie_filename, 'file')==2
        e=e+1;
        movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_epoch_clip-%d-%d.mp4', k, e));
    end
    numepochs(k)=e-1;
end

tic
% Scan video clips to get number of frames in each clip, and store them in
% NumFrames(k,e)
fprintf('\ngetting numFrames...')
try
    cd(rootdir)
    cd(state_epoch_clips_dir)
    load NumFrames
catch
    for k=1:num_states
        fprintf(' %d', k)
        for e=1:numepochs(k)
            movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_epoch_clip-%d-%d.mp4', k, e));
            vobj=VideoReader(movie_filename);
            NumFrames(k,e)=vobj.NumFrames;
            %note that mmfileinfo takes almost exactly as long
        end
    end
    cd(rootdir)
    cd(state_epoch_clips_dir)
    save NumFrames NumFrames
end
fprintf('\ndone\n')
toc


%make a grey dummy frame of the right size
movie_filename=fullfile(rootdir, state_epoch_clips_dir, 'ssm_state_epoch_clip-1-1.mp4');
vobj=VideoReader(movie_filename);
dummy= read(vobj, 1);
dummy=uint8(128*ones(size(dummy)));

%sort NumFrames from longest to shortest clip
for k=1:num_states
    [snumframes, snumframesi]=sort(NumFrames(k,:), 'descend');
    sNumFrames(k,:)=snumframes;
    sNumFramesi(k,:)=snumframesi;
end

% Main working loop.
% For each state k, we tile the epochs into a ssm_state_vid-comp-k
% This could be either 3x3, 4x4, etc
tic
fprintf('\nTiling video clips...')
switch arraysize
    case '3x3'
        max_num_epochs=9;
        for k=[1:num_states]
            out_movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_vid-comp-%d', k));
            vout = VideoWriter(out_movie_filename, 'MPEG-4');
            open(vout);
            for ei=1:max_num_epochs
                e=sNumFramesi(k,ei);
                in_movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_epoch_clip-%d-%d.mp4', k, e));
                try
                    v{ei} = VideoReader(in_movie_filename);
                catch
                    v{ei}=[];
                end
            end
            fprintf('\nk %d:', k)
            fprintf(' %d', sNumFrames(k,1:10))
            maxnumframes=sNumFrames(k,1);
            nbytes = fprintf('\tframe 0 of %d', maxnumframes);
            for f=1:maxnumframes
                fprintf(repmat('\b',1,nbytes))
                nbytes = fprintf('\tframe %d of %d', f, maxnumframes);
                for  ei=1:max_num_epochs
                    e=sNumFramesi(k,ei);
                    if isempty(v{ei})
                        vidFrame=dummy;
                        %there is no clip, this epoch doesn't exist
                    else
                        if hasFrame(v{ei})
                            vidFrame = readFrame(v{ei}) ;
                        else
                            %vidFrame=dummy;
                            vidFrame = read(v{ei},1) ;
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
                    %imshow(newFrame);shg
                end
                writeVideo(vout,newFrame)
            end
            close(vout)
        end
        
    case '4x4'
        max_num_epochs=16;
        for k=[1:num_states]
            out_movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_vid-comp-%d', k));
            vout = VideoWriter(out_movie_filename, 'MPEG-4');
            open(vout);
            for ei=1:max_num_epochs
                e=sNumFramesi(k,ei);
                in_movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_epoch_clip-%d-%d.mp4', k, e));
                try
                    v{ei} = VideoReader(in_movie_filename);
                catch
                    v{ei}=[];
                end
            end
            fprintf('\nk %d:', k)
            fprintf(' %d', sNumFrames(k,1:10))
            maxnumframes=sNumFrames(k,1);
            nbytes = fprintf('\tframe 0 of %d', maxnumframes);
            for f=1:maxnumframes
                fprintf(repmat('\b',1,nbytes))
                nbytes = fprintf('\tframe %d of %d', f, maxnumframes);
                for  ei=1:max_num_epochs
                    e=sNumFramesi(k,ei);
                    if isempty(v{ei})
                        vidFrame=dummy;
                        %there is no clip, this epoch doesn't exist
                    else
                        if hasFrame(v{ei})
                            vidFrame = readFrame(v{ei}) ;
                        else
                            %vidFrame=dummy;
                            vidFrame = read(v{ei},1) ;
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
                    %imshow(newFrame);shg
                end
                writeVideo(vout,newFrame)
            end
            close(vout)
        end
    case '5x5'
        max_num_epochs=25;
        for k=[1:num_states]
            out_movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_vid-comp-%d', k));
            vout = VideoWriter(out_movie_filename, 'MPEG-4');
            open(vout);
            for ei=1:max_num_epochs
                e=sNumFramesi(k,ei);
                in_movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_epoch_clip-%d-%d.mp4', k, e));
                try
                    v{ei} = VideoReader(in_movie_filename);
                catch
                    v{ei}=[];
                end
            end
            fprintf('\nk %d:', k)
            fprintf(' %d', sNumFrames(k,1:10))
            maxnumframes=sNumFrames(k,1);
            nbytes = fprintf('\tframe 0 of %d', maxnumframes);
            for f=1:maxnumframes
                fprintf(repmat('\b',1,nbytes))
                nbytes = fprintf('\tframe %d of %d', f, maxnumframes);
                for  ei=1:max_num_epochs
                    e=sNumFramesi(k,ei);
                    if isempty(v{ei})
                        vidFrame=dummy;
                        %there is no clip, this epoch doesn't exist
                    else
                        if hasFrame(v{ei})
                            vidFrame = readFrame(v{ei}) ;
                        else
                            %vidFrame=dummy;
                            vidFrame = read(v{ei},1) ;
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
                    %imshow(newFrame);shg
                end
                writeVideo(vout,newFrame)
            end
            close(vout)
        end
    case '6x6'
        max_num_epochs=36;
        for k=[1:num_states]
            out_movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_vid-comp-%d', k));
            vout = VideoWriter(out_movie_filename, 'MPEG-4');
            open(vout);
            for ei=1:max_num_epochs
                e=sNumFramesi(k,ei);
                in_movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('ssm_state_epoch_clip-%d-%d.mp4', k, e));
                try
                    v{ei} = VideoReader(in_movie_filename);
                catch
                    v{ei}=[];
                end
            end
            fprintf('\nk %d:', k)
            fprintf(' %d', sNumFrames(k,1:10))
            maxnumframes=sNumFrames(k,1);
            nbytes = fprintf('\tframe 0 of %d', maxnumframes);
            for f=1:maxnumframes
                fprintf(repmat('\b',1,nbytes))
                nbytes = fprintf('\tframe %d of %d', f, maxnumframes);
                for  ei=1:max_num_epochs
                    e=sNumFramesi(k,ei);
                    if isempty(v{ei})
                        vidFrame=dummy;
                        %there is no clip, this epoch doesn't exist
                    else
                        if hasFrame(v{ei})
                            vidFrame = readFrame(v{ei}) ;
                        else
                            %vidFrame=dummy;
                            vidFrame = read(v{ei},1) ;
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
                    %imshow(newFrame);shg
                end
                writeVideo(vout,newFrame)
            end
            close(vout)
        end
end
fprintf('\n')
toc

% now create a monolithic composite of all states in sequence
tic
fprintf('\ngenerating monolithic composite...')
out_movie_filename_mono=fullfile(rootdir, state_epoch_clips_dir, sprintf('all_states_comp%s', arraysize));
vout = VideoWriter(out_movie_filename_mono, 'MPEG-4');
open(vout);
for k=[1:num_states]
    in_movie_filename=fullfile(rootdir, state_epoch_clips_dir, sprintf('/ssm_state_vid-comp-%d.mp4', k));
    vin = VideoReader(in_movie_filename);
    fprintf('\nk %d:', k)
    nbytes=fprintf(' %d/10', 0);
    for i=1:10
        fprintf(repmat('\b',1,nbytes))
        nbytes=fprintf(' %d/10', i);
        vin.CurrentTime=0;
        for f=1:vin.NumFrames
            vidFrame = readFrame(vin) ;
            str=sprintf('loop %d',i);
            vidFrame = insertText(vidFrame,[20,125],str,...
                'FontSize',48,'Font', 'Arial', 'BoxColor', 'g',  ...
                'BoxOpacity',0.0,'TextColor','red');
            vidFrame=imresize(vidFrame, .25);
            writeVideo(vout,vidFrame)
        end
    end
end
close(vout)
toc
beep