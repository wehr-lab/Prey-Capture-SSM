function LabelMovieStates(outputdir)

%Usage: LabelMovieStates(datadir)
% label trial videos with hmm states, and other info

if nargin==0 outputdir=pwd;end
cd(outputdir)
if ~exist('./pruned_tpm.mat')
    error('no smm group data in this directory')
end
load pruned_tpm
load training_data


out_movie_filename='labelled_trials';
vout = VideoWriter(out_movie_filename, 'MPEG-4');
vout.FrameRate=groupdata(1).framerate;
open(vout)
cumframeidx=0;
cmap=jet(num_states);
cmap=round(255*cmap);



for i=1:length(datadirs);
    % localframenum comes from ConvertGeometryToObservations and
    % already accounts for trimming from cricket drop frame to catch
    % frame
    
    start_frame=groupdata(i).cricketdropframe;
    stop_frame=groupdata(i).catchframe;
    
  
    datadir=datadirs{i};
    if ismac datadir=macifypath(datadir);end
    
    cd(datadir)
    d=dir('*_labeled.mp4');
    movie_filename=d.name;
    fprintf('\nmovie %d/%d ', i,length(datadirs))
    v = VideoReader(movie_filename);
    oneframe = read(v, 1) ;
    grey=mean(oneframe(:));
    numframes=stop_frame-start_frame;
    
    %add some labels
    x1=10; y1=10;
    x2=250; y2=10;
    nbytes = fprintf('\tframe 0 of %d', numframes);
    for f=1:numframes
        fprintf(repmat('\b',1,nbytes))
        nbytes = fprintf('\tframe %d of %d', f, numframes);
        
        cumframeidx=cumframeidx+1;
        vidFrame = read(v, start_frame+f-1) ;
        

       
        
        % add state label
        if survival_mask(cumframeidx) %surviving epoch
            boxcolor=cmap(1+Z(cumframeidx),:);
            textcolor='white';
        else %this epoch was pruned away
            boxcolor='black';
            textcolor=[50 50 50];
        end
        
        str=sprintf('%d', Z(cumframeidx));
        vidFrame = insertText(vidFrame,[x1,y1],str,...
            'FontSize',60,'Font', 'Arial', 'BoxColor', boxcolor,  ...
            'BoxOpacity',0.4,'TextColor',textcolor);
        
        %add frame counter
        %the counters are: trialnum localframenum/numframes
        %cumframenum/totalframes
        vidFrame = insertText(vidFrame,[10,900],...
            sprintf('trial%d %d/%d %d/%d',i, f,numframes, cumframeidx, length(Z)),...
            'FontSize',48,'Font', 'Arial', 'BoxColor', 'g',  ...
            'BoxOpacity',0,'TextColor','white');
        vidFrame = insertText(vidFrame,[10,1025],...
            sprintf('%s',movie_filename),...
            'FontSize',24,'Font', 'Arial', 'BoxColor', 'g',  ...
            'BoxOpacity',0,'TextColor','white');
        
        writeVideo(vout,vidFrame)
        
        
    end
    
    
end

cd(outputdir)
close(vout)
beep