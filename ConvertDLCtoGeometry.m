function ConvertDLCtoGeometry(varargin)
% usage: ConvertDLCtoGeometry([datapath], ['plot'])
%     datapath - folder with DLC tracks (defaults to current directory)
%     'plot' - if you want to display some plots (defaults to no plotting)
%
%this function loads DLC (x,y,t) tracking data from an indivual session, and computes
%geometric variables like speed, range, azimuth, and saves to local file.
%optionally displays some plots if you pass 'plot' as a second argument

%You could call this function from a batch processer using a dir list


plotit=0;
datapath=pwd;
if nargin==1
    datapath=varargin{1};
elseif nargin==2
    if strcmp(varargin{2}, 'plot')
        plotit=1;
        close all
    end
end



%adjust filenames to work on a mac
% if ismac
%     datapath= strrep(datapath, '\', '/');
%     datapath= strrep(datapath, 'C:', '/Volumes/C');
%     datapath= strrep(datapath, 'D:', '/Volumes/D');
% end

cd(datapath)
d=dir('Behavior_mouse-*.mat');
if length(d)>1 error('more than one behavior datafile'); end
behavior_datafile=d(1).name;
load(behavior_datafile)
fprintf('\nloaded %s', behavior_datafile)
outfilename=strrep(behavior_datafile, 'Behavior_mouse', 'geometry');
% cricketback
% cricketfront
% headbase
% leftear
% nose
% rightear
% tailbase
% tailtip

headbase=Sky.dlc.headbase;
nose=Sky.dlc.nose;
rightear=Sky.dlc.rightear;
leftear=Sky.dlc.leftear;
tailbase=Sky.dlc.tailbase;
cricketback=Sky.dlc.cricketback;
cricketfront=Sky.dlc.cricketfront;

try
    framerate=Sky.vid.framerate;
catch %framerate was added to ProcessCams on Feb 12, 2021
    fprintf('\ngetting framerate from video...')
    v=VideoReader(Sky.vid.name);
    framerate=v.FrameRate;
    fprintf('\t%.2f', framerate)
end

if plotit
    t=1:length(headbase);
    t=t/framerate; % t is in seconds
    
    figure
    plot(headbase(:,1), headbase(:,2))
    hold on
    plot(nose(:,1), nose(:,2))
    plot(cricketfront(:,1), cricketfront(:,2))
    title('raw data')
    legend('mouse headbase', 'mouse nose', 'cricket front')
    set(gca, 'ydir', 'reverse')
    
end

% find cricket drop and clean up tracks using probability
% drop is where probability crosses .5 and stays up for >1s
%(arbitrary first guess)
pthresh=.5; % probability threshold
cricketprob=mean([cricketfront(:,3), cricketback(:,3)], 2);
goodframes=find(cricketprob>=pthresh); %frames with prob above thresh
dfgoodframes=diff(goodframes);
thresh=3; %ignore probability flickers shorter than this
i=1;
while any(dfgoodframes(i:i+round(1*framerate))>=thresh)
    i=i+1;
end
cricketdropframe=goodframes(i);
catchframe=goodframes(end); %last known sighting of cricket = catch frame
fprintf('\ncricket drop frame %d (%.1fs)', cricketdropframe, cricketdropframe/framerate)
fprintf('\ncricket catch frame %d (%.1fs)', catchframe, catchframe/framerate)

% trim to t>cricketdropframe t<catchframe and split into x and y
% headbaset=headbase(cricketdropframe:catchframe,:);
headbasex=headbase(cricketdropframe:catchframe,1);
headbasey=headbase(cricketdropframe:catchframe,2);
% noset=nose(cricketdropframe:catchframe,:);
nosex=nose(cricketdropframe:catchframe,1);
nosey=nose(cricketdropframe:catchframe,2);
% righteart=rightear(cricketdropframe:catchframe,:);
rightearx=rightear(cricketdropframe:catchframe,1);
righteary=rightear(cricketdropframe:catchframe,2);
% lefteart=leftear(cricketdropframe:catchframe,:);
leftearx=leftear(cricketdropframe:catchframe,1);
lefteary=leftear(cricketdropframe:catchframe,2);
% tailbaset=tailbase(cricketdropframe:catchframe,:);
tailbasex=tailbase(cricketdropframe:catchframe,1);
tailbasey=tailbase(cricketdropframe:catchframe,2);
cricketfrontprob=cricketfront(cricketdropframe:catchframe,3);
cricketfrontx=cricketfront(cricketdropframe:catchframe,1);
cricketfronty=cricketfront(cricketdropframe:catchframe,2);
cricketbackprob=cricketback(cricketdropframe:catchframe,3);
cricketbackx=cricketback(cricketdropframe:catchframe,1);
cricketbacky=cricketback(cricketdropframe:catchframe,2);
numframes=length(nosex);

fprintf('\ncleaning cricket tracks...')
% try using resample approach for cleaning
cricketprob=mean([cricketfrontprob, cricketbackprob], 2); %redo since we trimmed
goodframes=find(cricketprob>=pthresh); %frames with prob above thresh
errframes=find(cricketprob<pthresh); %find missing frames
[clean_cricketfrontx, ty]=resample(cricketfrontx(goodframes), goodframes, 1, 'pchip');
[clean_cricketfronty, ty]=resample(cricketfronty(goodframes), goodframes, 1, 'pchip');
clean_cricketfrontx=clean_cricketfrontx(1:length(nosex)); %trim to same length (might be off by 1)
clean_cricketfronty=clean_cricketfronty(1:length(nosex)); %trim to same length (might be off by 1)

if plotit
    %check the results of cleaning
    
    figure, hold on
    t=1:length(cricketfrontx);
    plot(t, cricketfrontx, t, cricketfronty)
    plot(errframes, cricketfrontx(errframes), 'ro')
    plot(goodframes, cricketfrontx(goodframes), 'go')
    plot(t, cricketprob*100)
    plot(t, clean_cricketfrontx,t, clean_cricketfronty, 'k', 'linewi', 2)
    
    figure
    plot(headbasex, headbasey)
    hold on
    plot(nosex, nosey)
    plot(clean_cricketfrontx, clean_cricketfronty)
    title('cleaned data')
    legend('mouse headbase', 'mouse nose', 'cricket front')
    set(gca, 'ydir', 'reverse')
end

%need to clean mouse tracks using same method



% %clean tracks using mean of nearest pre/post good frames- this is really slow and needs to be vectorized for speed
% fprintf('\ncleaning cricket tracks...')
% errframes=find(cricketprob<.5); %find missing frames
% wb=waitbar(0);
% for i=errframes'
%     waitbar(i/length(errframes),wb)
%     if i> cricketdropframe
%         %find nearest previous good frame
%         j=i;
%         while ~ismember(j, goodframes)
%             j=j-1;
%             %             if j<cricketdropframe
%             %                 %this should never happen
%             %                 j=i
%             %                 break
%             %             end
%         end
%         pre_goodframe=j;
%         %find nearest next good frame
%         j=i;
%         while ~ismember(j, goodframes)
%             j=j+1;
%             if j>numframes
%                 j=pre_goodframe;
%                 break
%             end
%         end
%         post_goodframe=j;
%         clean_cricketfront(i,1:2)=mean([clean_cricketfront(pre_goodframe,1:2); clean_cricketfront(post_goodframe,1:2)],1 );
%         clean_cricketback(i,1:2)=mean([clean_cricketback(pre_goodframe,1:2); clean_cricketback(post_goodframe,1:2)], 1);
%
%     end
% end
% close(wb)

% % clean up cricket tracks, by median filtering
% dfc1=diff(clean_cricketfront);
% thresh=10; %plausible cricket jump threshold, pixels
% errframes1=find(abs(dfc1)>thresh);
% for ef=errframes1'
%     if ef>3 & ef<length(clean_cricketfront)-3
%         clean_cricketfront(ef,:)=median(clean_cricketfront(ef-3:ef+3,:));
%         clean_cricketback(ef,:)=median(clean_cricketback(ef-3:ef+3,:));
%     end
%  end
%
% if plotit
%     %check the results of cleaning
%     figure, hold on
%     plot(t, cricketfront(:,1))
%     plot(t, cricketfront(:,2))
%     plot(t, clean_cricketfront(:,1), 'linewidth', 2)
%     plot(t, clean_cricketfront(:,2), 'linewidth', 2)
%     plot(t, cricketback(:,1))
%     plot(t, cricketback(:,2))
%     plot(t, clean_cricketback(:,1), 'linewidth', 2)
%     plot(t, clean_cricketback(:,2), 'linewidth', 2)
%     plot(t, cricketprob*100)
%     plot(t(cricketdropframe), 1300, 'v')
%     legend('original front x','original front y', ...
%         'cleaned front x',  'cleaned front y', ...
%         'original back x','original back y', ...
%         'cleaned back x',  'cleaned back y', 'cricket prob')
%
%     figure
%     hold on
%     roi=1:numframes;
%     %roi=1.4e4:1.5e4;
%     plot(headbase(roi,1), headbase(roi,2))
%     plot(nose(roi,1), nose(roi,2))
%     plot(clean_cricketfront(roi,1), clean_cricketfront(roi,2))
%     title('cleaned data')
%     legend('mouse headbase', 'mouse nose', 'cricket front')
%     set(gca, 'ydir', 'reverse')
% end


%smooth
fprintf('\nfiltering...')
[b,a]=butter(3, .25);
snosex=filtfilt(b,a,nosex);
snosey=filtfilt(b,a,nosey);
sheadbasex=filtfilt(b,a,headbasex);
sheadbasey=filtfilt(b,a,headbasey);
scricketx=filtfilt(b,a,clean_cricketfrontx);
scrickety=filtfilt(b,a,clean_cricketfronty);

if plotit
    figure
    hold on
    plot(sheadbasex, sheadbasey, snosex, snosey, scricketx, scrickety)
    text(sheadbasex(1), sheadbasey(1), 'start')
    text(scricketx(1), scrickety(1), 'start')
    title('mouse & cricket positions, smoothed')
    set(gca, 'ydir', 'reverse')
end



% animate the mouse and cricket
% if(1)
%     h=plot(smouseCOMx(1), smouseCOMy(1), 'bo', smouseNosex(1), smouseNosey(1), 'ro');
%     for f=1:length(smouseCOMx)
%         hnew=plot(smouseCOMx(f), smouseCOMy(f), 'bo', ...
%             smouseNosex(f), smouseNosey(f), 'ro', ...
%             scricketx(f), scrickety(f), 'ko');
%         set(h, 'visible', 'off');
%         h=hnew;
%         pause(.01)
%     end
% end

%atan2d does the full circle (-180 to 180)
%atand does the half circle (-90 to 90)



% %mouse bearing: mouse body-to-nose angle, in absolute coordinates
% deltax=smouseNosex-smouseCOMx;
% deltay=smouseNosey-smouseCOMy;
% mouse_bearing=atan2d(deltay, deltax);
%
% %mouseCOM-to-cricket angle, in absolute coordinates
% deltax_ccom=scricketx-smouseCOMx;
% deltay_ccom=scrickety-smouseCOMy;
% cricket_angle_com=atan2d(deltay_ccom, deltax_ccom);
%
% %mouseNose-to-cricket angle, in absolute coordinates
% %(should be nearly identical to mouseCOM-to-cricket angle)
% deltax_cnose=scricketx-smouseNosex;
% deltay_cnose=scrickety-smouseNosey;
% cricket_angle_nose=atan2d(deltay_cnose, deltax_cnose);
%
% %azimuth: relative angle between mouse bearing and mouseCOM-to-cricket angle
% azimuth2=mouse_bearing-cricket_angle_com;
% azimuth1=mouse_bearing-cricket_angle_nose;
%
% figure
% hold on
% plot(cricket_angle_com)
% plot(cricket_angle_nose)
% plot(mouse_bearing)
% title('absolute angles')
% legend('mouse COM to cricket', 'mouse nose to cricket', 'mouse bearing')
%
% mouse_bearing_unwrapped = 180/pi * unwrap(mouse_bearing * pi/180);
% cricket_angle_com_unwrapped = 180/pi * unwrap(cricket_angle_com * pi/180);
% cricket_angle_nose_unwrapped = 180/pi * unwrap(cricket_angle_nose * pi/180);
%
% azimuth4=mouse_bearing_unwrapped-cricket_angle_com_unwrapped;
% azimuth3=mouse_bearing_unwrapped-cricket_angle_nose_unwrapped;
%
% figure(ftracks)
% subplot(312)
% hold on
% plot(cricket_angle_com_unwrapped)
% plot(cricket_angle_nose_unwrapped)
% plot(mouse_bearing_unwrapped, 'k')
% title('unwrapped absolute angles')
% legend('mouse COM to cricket', 'mouse nose to cricket', 'mouse bearing')

% animate the mouse and cricket
% if(1)
%     h=plot(smouseCOMx(1), smouseCOMy(1), 'bo', smouseNosex(1), smouseNosey(1), 'ro');
%     for f=1:length(smouseCOMx)
%         hnew=plot(smouseCOMx(f), smouseCOMy(f), 'bo', ...
%             smouseNosex(f), smouseNosey(f), 'ro', ...
%             scricketx(f), scrickety(f), 'ko');
%         set(h, 'visible', 'off');
%         h=hnew;
%         pause(.01)
%     end
% end

fprintf('\ncomputing geometry...')
%calculating Relative Azimuth instead of using absolute angles
% %solve the triangle using the cosine rule
% a=COM-to-nose distance
% b=COM-to-cricket
% c=nose-to-cricket
% then azimuth=arccos((a2 + b2 - c2)/(2ab))
a=sqrt((sheadbasex-snosex).^2 + (sheadbasey-snosey).^2);
b=sqrt((sheadbasex-scricketx).^2 + (sheadbasey-scrickety).^2);
c=sqrt((snosex-scricketx).^2 + (snosey-scrickety).^2);
RelativeAzimuth=acosd((a.^2+b.^2-c.^2)./(2.*a.*b));


if plotit
    
    figure
    hold on
    plot(RelativeAzimuth)
    xlabel('frames')
    ylabel('azimuth in degrees')
    title(' azimuth')
    % cd(analysis_plots_dir)
    % if exist('analysis_plots.ps')==2
    %     print -dpsc2 'analysis_plots.ps' -append -bestfit
    % else
    %     print -dpsc2 'analysis_plots.ps' -bestfit
    % end
    % line(xlim, [0 0], 'linestyle', '--')
end

%animate the mouse and cricket, along with angles, write to video
if 0
    [p, f, e]=fileparts(datapath);
    
    vidfname=sprintf('%s.avi', f);
    v=VideoWriter(vidfname);
    open(v);
    figure(ftracks)
    axes(ax) %     subplot(311)
    h=plot(smouseCOMx(1), smouseCOMy(1), 'bo', smouseNosex(1), smouseNosey(1), 'ro',scricketx(1), scrickety(1), 'ko');
    legend('mouse COM', 'mouse nose', 'cricket','mouse COM', 'mouse nose', 'cricket', 'Location', 'EastOutside')
    subplot(312)
    h2=plot(1,cricket_angle_nose_unwrapped(1), 'ko', 1, mouse_bearing_unwrapped(1), 'ro');
    subplot(313)
    h3=plot(azimuth(1), 'bo');
    
    wb=waitbar(0, 'building animation');
    for f=1:length(smouseCOMx)
        waitbar(f/length(smouseCOMx), wb);
        axes(ax)
        set(h(1), 'xdata', smouseCOMx(f), 'ydata', smouseCOMy(f))
        set(h(2), 'xdata', smouseNosex(f), 'ydata', smouseNosey(f))
        set(h(3), 'xdata', scricketx(f), 'ydata', scrickety(f))
        
        subplot(312)
        hnew2=plot(f, cricket_angle_nose_unwrapped(f), 'ko', f, mouse_bearing_unwrapped(f), 'ro');
        set(h2, 'visible', 'off');
        h2=hnew2;
        
        subplot(313)
        hnew3=plot(f, azimuth(f), 'bo');
        set(h3, 'visible', 'off');
        h3=hnew3;
        
        drawnow
        frame = getframe(gcf);
        writeVideo(v,frame);
    end
    close(v)
    close(wb)
end

%range (distance to target)
deltax_cnose=scricketx-snosex;
deltay_cnose=scrickety-snosey;

range=sqrt(deltax_cnose.^2 + deltay_cnose.^2);

%mouse speed
speed=sqrt(diff(sheadbasex).^2 + diff(sheadbasex).^2);
[b,a]=butter(3, .5);
speed=filtfilt(b,a,speed);
speed=[speed(1); speed]; %pad with duped first point so vectors are same length after diff

%cricket speed
cspeed=sqrt(diff(scricketx).^2 + diff(scrickety).^2);
[b,a]=butter(3, .5);
cspeed=filtfilt(b,a,cspeed);
cspeed=[cspeed(1); cspeed]; %pad with duped first point so vectors are same length after diff

if plotit
    fprintf('\nplotting...')
    figure
    plot(t, speed)
    xlabel('time, s')
    ylabel('speed, px/frame')
    title('mouse speed vs. time')
    
    figure
    plot(t, cspeed)
    xlabel('time, s')
    ylabel('speed, px/frame')
    title('cricket speed vs. time')
    
    figure
    title('range, azimuth, and speed over time (mismatched units')
    plot(t, 10*speed, t, 10*cspeed, t, range, t, RelativeAzimuth) %careful, these are in different units
    legend('mouse speed', 'cricket speed', 'range', 'azimuth')
    xlabel('time, s')
    ylabel('speed, px/frame')
    grid on
    line(xlim, [0 0], 'color', 'k')
    th=title(datapath);
    set(th,'fontsize', 8)
    try
        %     print -dpsc2 'analysis_plots.ps' -append
    end
    
    figure
    plot(speed, range, 'k')
    hold on
    
    
    cmap=colormap;
    for j=1:3; cmap2(:,j)=interp(cmap(:,j), ceil(numframes/64));end
    cmap2(find(cmap2>1))=1;
    for f=1:numframes-1
        plot(speed(f), range(1+f), '.', 'color', cmap2(f,:))
    end
    text(speed(1), range(2), 'start')
    text(speed(end), range(end), 'end')
    xlabel('speed')
    ylabel('range')
    title('range vs. speed')
    % print -dpsc2 'analysis_plots.ps' -append
    
    figure
    h=plot(range, RelativeAzimuth);
    set(h, 'color', [.7 .7 .7]) %grey
    hold on
    cmap=colormap;
    for j=1:3; cmap2(:,j)=interp(cmap(:,j), ceil(numframes/64));end
    cmap2(find(cmap2>1))=1;
    for f=1:numframes
        h=plot(range(f), RelativeAzimuth(f), '.', 'color', cmap2(f,:));
        set(h, 'markersize', 20)
    end
    text(range(1), RelativeAzimuth(2), 'start')
    text(range(end), RelativeAzimuth(end), 'end')
    xl=xlim;yl=ylim;
    xlim([0 xl(2)]);
    xlabel('range, pixels')
    ylabel('azimuth, degrees')
    title('azimuth vs. range')
    % print -dpsc2 'analysis_plots.ps' -append
end


%save results to local out file
fprintf('\nsaving to file %s...', outfilename)

generated_on=datestr(now);
generated_by=mfilename;

save(outfilename, 'speed', 'cspeed', 'range', 'RelativeAzimuth', ...
    'snosex', 'snosey', 'clean_cricketfrontx',  'clean_cricketfronty', ...
    'cricketdropframe', 'catchframe', 'framerate', 'numframes', ...
    'datapath', 'behavior_datafile', 'outfilename', ...
    'sheadbasex', 'sheadbasey', ...
    'leftearx', 'lefteary', ...
    'rightearx', 'righteary', ...
    'tailbasex', 'tailbasey', ...
    'generated_on', 'generated_by')
fprintf('  done\n')





