% label trial videos with hmm states, and other info

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
cd('/Users/mikewehr/Documents/Analysis/PreyCapture data')
% cd('/Users/mikewehr/Resilio Sync/Prey Capture/')
% state_epoch_clips_dir='state_epoch_clips-13-Aug-2020';
state_epoch_clips_dir=sprintf('state_epoch_clips-%s',datestr(today));

cd(state_epoch_clips_dir)
load pruned_tpm


% %   here, you need to look at the tpm and assign clusters, as follows
 figure
tree=linkage(tpm, 'average');
colorthresh=.9*max(tree(:,3)); %threshold for color-coding the clusters
[H,T,outperm] = dendrogram(tree,0,'Orientation','left','ColorThreshold',colorthresh);
imagesc(tpm(outperm,outperm))
colormap(hot)
axis square
set(gca, 'xtick', 1:length(T), 'ytick', 1:length(T), 'xticklabel', outperm, 'yticklabel', outperm)
title('symbolic tpm all data, clustered')
fprintf('\n clustered sequence:\n')
fprintf('%d ',outperm) %echo the clustered sequence
fprintf('\n')


switch state_epoch_clips_dir
    case  '7-13-2020' %legacy
        %         C1=[20  32  10   1  37   3   6  34  16  24  25   8  28];
        %         C2=[2  14   4];
        %         C2a=[7  22  12  36  11  17  31  30  39  35];
        %         C3=[15  19  33  18  21];
        %         C4=[5   9  13  26  23  38];
        %         C5=[29  27];
    case 'state_epoch_clips-22-Jul-2020'
        C1=[ 1  14 2  15  27 8  21  30 9  11  19 16 32];
        C2=[ 3 5  12  13 7  28 6  26  35  25  10  33  23  29  18  34 ];
        C3=[ 4  17  20  24  31  36 ];
        C4=[22];
        C5=[];
    case 'state_epoch_clips-13-Aug-2020'
       
        
        C1=[7 20 14 38 30 19 34 3];
        C2=[ 6 12 16 22 32];
        C3=[5 18 26 35 37 9 13 15 17];
        C4=[29 23 33 ];
        C5=[2 4 21 24 8 25 27 1 10 36 31 ];
        C6=[11 39 28  ];
        
        
        
    otherwise
        C1=[];
        C2=[ ];
        C3=[];
        C4=[];
        C5=[ ];
        C6=[ ];
        error('maybe you need to look at the tpm and assign clusters')
end

        x1=1; x2=length(C1); 
        L(1)=line([x1 x1], [x1 x2])
        L(2)=line([x2 x2], [x1 x2])
        L(3)=line([x1 x2], [x1 x1])
        L(4)=line([x1 x2], [x2 x2])
        set(L,'LineWidth',2)
         x1=x2+1; x2=x1+length(C2)-1; 
        L(1)=line([x1 x1], [x1 x2])
        L(2)=line([x2 x2], [x1 x2])
        L(3)=line([x1 x2], [x1 x1])
        L(4)=line([x1 x2], [x2 x2])
        set(L,'LineWidth',2)
            x1=x2+1; x2=x1+length(C3)-1; 
        L(1)=line([x1 x1], [x1 x2])
        L(2)=line([x2 x2], [x1 x2])
        L(3)=line([x1 x2], [x1 x1])
        L(4)=line([x1 x2], [x2 x2])
        set(L,'LineWidth',2)
            x1=x2+1; x2=x1+length(C4)-1; 
        L(1)=line([x1 x1], [x1 x2])
        L(2)=line([x2 x2], [x1 x2])
        L(3)=line([x1 x2], [x1 x1])
        L(4)=line([x1 x2], [x2 x2])
        set(L,'LineWidth',2)
            x1=x2+1; x2=x1+length(C5)-1; 
        L(1)=line([x1 x1], [x1 x2])
        L(2)=line([x2 x2], [x1 x2])
        L(3)=line([x1 x2], [x1 x1])
        L(4)=line([x1 x2], [x2 x2])
        set(L,'LineWidth',2)
            x1=x2+1; x2=x1+length(C6)-1; 
        L(1)=line([x1 x1], [x1 x2])
        L(2)=line([x2 x2], [x1 x2])
        L(3)=line([x1 x2], [x1 x1])
        L(4)=line([x1 x2], [x2 x2])
        set(L,'LineWidth',2)
        print -dpdf TPM_clusters.pdf
        
% vidoutnamestr='labelled_trials';
%out_movie_filename=sprintf('/Users/mikewehr/Documents/Analysis/PreyCapture data/%s', vidoutnamestr);
out_movie_filename='labelled_trials';
vout = VideoWriter(out_movie_filename, 'MPEG-4');
open(vout)
cumframeidx=0;


files=lidocaine_new_preycapturefilelist;
for i=1:length(Groupdata);
    start_frame=Groupdata(i).start_frame;
    stop_frame=Groupdata(i).stop_frame;
    firstcontact_frame=Groupdata(i).firstcontact_frame;
    %numframes= firstcontact_frame; %Groupdata(i).numframes;
    drug=Groupdata(i).drug;
    
    if isfield(Groupdata(i), 'movie_location')
        movie_location=Groupdata(i).movie_location;
    else
        %     find the corresponding movie location from filelist
        movie_location='';
        for j=1:length(files)
            if files(j).start_frame==start_frame & ...
                    files(j).firstcontact_frame==firstcontact_frame & ...
                    files(j).drug==drug
                movie_location=files(j).datapath;
                fprintf('j=%d %d %d %s', j, start_frame, stop_frame, movie_location)
            end
        end
    end
    
    if isempty(movie_location)
        error('could not identify movie location')
    end
    
    new_movie_location=strrep(movie_location,...
        'D:\lab\Data\Injections_mice\', '/Users/mikewehr/Documents/Analysis/PreyCapture data/');
    
    new_movie_location=strrep(new_movie_location, '\', '/');
    cd(new_movie_location)
    d=dir('*_labeled.mp4');
    movie_filename=d.name;
    fprintf('\nmovie %d/%d ', i,length(Groupdata))
    v = VideoReader(movie_filename);
    oneframe = read(v, 1) ;
    grey=mean(oneframe(:));
     numframes=stop_frame-start_frame;
   % numframes=firstcontact_frame-start_frame; %mw 7.21.2020
%numframes= firstcontact_frame;
    
    %add some labels
    x1=10; y1=10;
    x2=250; y2=10;
    nbytes = fprintf('\tframe 0 of %d', numframes);
    for f=1:numframes
        fprintf(repmat('\b',1,nbytes))
        nbytes = fprintf('\tframe %d of %d', f, numframes);
        
        cumframeidx=cumframeidx+1;
        vidFrame = read(v, start_frame+f-1) ;
        
 



        
        %get state label for this frame
        if any(Z(cumframeidx)==C1)
            framestatename='C1';
            boxcolor='magenta';
        elseif any(Z(cumframeidx)==C2)
            framestatename='C2';
            boxcolor='blue';
    
        elseif any(Z(cumframeidx)==C3)
            framestatename='C3';
            boxcolor='green';
        elseif any(Z(cumframeidx)==C4)
            framestatename='C4';
            boxcolor='cyan';
        elseif any(Z(cumframeidx)==C5)
            framestatename='C5';
            boxcolor='yellow'; 
        elseif any(Z(cumframeidx)==C6)
            framestatename='C6';
            boxcolor='red';
        else
            framestatename='';
            boxcolor='black';
            %usually a state that has been pruned
        end
        
        % add state label
        
        str=sprintf('%d\n%s', Z(cumframeidx),framestatename);
        vidFrame = insertText(vidFrame,[x1,y1],str,...
            'FontSize',60,'Font', 'Arial', 'BoxColor', boxcolor,  ...
            'BoxOpacity',0.4,'TextColor','white');
        %         str=sprintf('%s', framestatename);
        %         vidFrame = insertText(vidFrame,[x1,y1+60],str,...
        %             'FontSize',60,'Font', 'Arial', 'BoxColor', boxcolor,  ...
        %             'BoxOpacity',0.4,'TextColor','white');
        
        %add frame counter & drug
        %the counters are: trialnum localframenum/numframes
        %cumframenum/totalframes
        vidFrame = insertText(vidFrame,[10,900],...
            sprintf('trial%d %d/%d %d/%d',i, f,numframes, cumframeidx, length(Z)),...
            'FontSize',48,'Font', 'Arial', 'BoxColor', 'g',  ...
            'BoxOpacity',0,'TextColor','white');
        vidFrame = insertText(vidFrame,[10,950],drug, ...
            'FontSize',48,'Font', 'Arial', 'BoxColor', 'g',  ...
            'BoxOpacity',0,'TextColor','white');
        vidFrame = insertText(vidFrame,[10,1025],...
            sprintf('%s',movie_filename),...
            'FontSize',36,'Font', 'Arial', 'BoxColor', 'g',  ...
            'BoxOpacity',0,'TextColor','white');
        
        writeVideo(vout,vidFrame)
        
        
    end
    
    
end

close(vout)
cd    '/Users/mikewehr/Documents/Analysis/PreyCapture data'
beep