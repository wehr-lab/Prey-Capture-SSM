function ConvertDLCtoGeometry(varargin)
% usage: ConvertDLCtoGeometry([datapath], ['plot'])
%     datapath - folder with DLC tracks (defaults to current directory)
%     'plot' - if you want to display some plots (defaults to no plotting)
%
%this function loads DLC (x,y,t) tracking data from an individual session, and computes
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

cd(datapath)

% fprintf('\nforce re-process Behavior_mouse with ProcessCams in ConvertDLCtoGeometry')
% ProcessCams

d=dir('Behavior_mouse-*.mat');
if length(d)==0
    warning('no Behavior_mouse file in this directory')
    fprintf('\nrunning ProcessCams')
    ProcessCams
    d=dir('Behavior_mouse-*.mat');
    warning('no Behavior_mouse file in this directory')
elseif length(d)>1
    error('more than one behavior datafile');
end
behavior_datafile=d(1).name;
load(behavior_datafile)
fprintf('\nloaded %s', behavior_datafile)
outfilename=strrep(behavior_datafile, 'Behavior_mouse', 'geometry');
% names of DLC points
% cricketback
% cricketfront
% headbase
% leftear
% nose
% rightear
% tailbase
% tailtip

try
    headbase=Sky.dlc.headbase;
    nose=Sky.dlc.nose;
    rightear=Sky.dlc.rightear;
    leftear=Sky.dlc.leftear;
    tailbase=Sky.dlc.tailbase;
    cricketback=Sky.dlc.cricketback;
    cricketfront=Sky.dlc.cricketfront;
catch 
    headbase=Sky.dlc.topOfHead;
    nose=Sky.dlc.nose;
    rightear=Sky.dlc.rightEar;
    leftear=Sky.dlc.leftEar;
    tailbase=Sky.dlc.baseOfTail;
    cricketback=Sky.dlc.cricketTail;
    cricketfront=Sky.dlc.cricketHead;
end

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
% drop is where probability crosses .5 and stays up for >.5s
%(arbitrary operational definition)
pthresh=.5; % probability threshold
durthresh=100; %cricketprob needs to stay high for this many frames to count as a drop
cricketprob=mean([cricketfront(:,3), cricketback(:,3)], 2);
goodframes=find(cricketprob>=pthresh); %frames with prob above thresh
dfgoodframes=diff(goodframes);
thresh=20; %ignore probability flickers shorter than this
i=1;
%check how long the cricket was in view, error out (for now) if too short to study
if length(find(cricketprob>pthresh))<durthresh
    fprintf('\n\nproblem with %s\n', datapath)
    error(sprintf('cricket only in view for %.0f ms, exclude this session', 1000*length(find(cricketprob>pthresh))/framerate))
end

while any(dfgoodframes(i:i+durthresh)>=thresh) %scan until we don't see diff jumps
    i=i+1;
    
    if (i+durthresh)>length(dfgoodframes)
        fprintf('\n\nproblem with %s\n', datapath)
        error('no sustained view of cricket, exclude this session')
    end
end
fprintf('\n%d total frames in video)', length(cricketprob))
cricketdropframe=goodframes(i);
catchframe=goodframes(end); %last known sighting of cricket = catch frame
fprintf('\ncricket drop frame %d (%.1fs)', cricketdropframe, cricketdropframe/framerate)
fprintf('\ncricket catch frame %d (%.1fs)', catchframe, catchframe/framerate)

% trim to t>cricketdropframe t<catchframe and split into x and y
% headbaset=headbase(cricketdropframe:catchframe,:);
headbasex=headbase(cricketdropframe:catchframe,1);
headbasey=headbase(cricketdropframe:catchframe,2);
headbaseprob=headbase(cricketdropframe:catchframe,3);
nosex=nose(cricketdropframe:catchframe,1);
nosey=nose(cricketdropframe:catchframe,2);
rightearx=rightear(cricketdropframe:catchframe,1);
righteary=rightear(cricketdropframe:catchframe,2);
leftearx=leftear(cricketdropframe:catchframe,1);
lefteary=leftear(cricketdropframe:catchframe,2);
tailbasex=tailbase(cricketdropframe:catchframe,1);
tailbasey=tailbase(cricketdropframe:catchframe,2);
tailbaseprob=tailbase(cricketdropframe:catchframe,3);
cricketfrontprob=cricketfront(cricketdropframe:catchframe,3);
cricketfrontx=cricketfront(cricketdropframe:catchframe,1);
cricketfronty=cricketfront(cricketdropframe:catchframe,2);
cricketbackprob=cricketback(cricketdropframe:catchframe,3);
cricketbackx=cricketback(cricketdropframe:catchframe,1);
cricketbacky=cricketback(cricketdropframe:catchframe,2);
numframes=length(nosex);
fprintf('\n%d frames (cricket drop to catch))', numframes)

fprintf('\ncleaning cricket tracks...')
% try using resample approach for cleaning
cricketprob=mean([cricketfrontprob, cricketbackprob], 2); %redo since we trimmed
goodframes=find(cricketprob>=pthresh); %frames with prob above thresh
errframes=find(cricketprob<pthresh); %find missing frames
[clean_cricketfrontx, ty]=resample(cricketfrontx(goodframes), goodframes, 1, 'pchip');
[clean_cricketfronty, ty]=resample(cricketfronty(goodframes), goodframes, 1, 'pchip');
clean_cricketfrontx=clean_cricketfrontx(1:length(nosex)); %trim to same length (might be off by 1)
clean_cricketfronty=clean_cricketfronty(1:length(nosex)); %trim to same length (might be off by 1)

fprintf('\ncleaning mouse tracks...')
goodframes=find(headbaseprob>=pthresh); %frames with prob above thresh
errframes=find(headbaseprob<pthresh); %find missing frames
[clean_headbasex, ty]=resample(headbasex(goodframes), goodframes, 1, 'pchip');
[clean_headbasey, ty]=resample(headbasey(goodframes), goodframes, 1, 'pchip');
if length(nosex)>length(clean_headbasex)
    tmpx=clean_headbasex;
    tmpy=clean_headbasey;
    clean_headbasex=zeros(size(nosex));
    clean_headbasey=zeros(size(nosex));
    clean_headbasex(1:length(tmpx))=tmpx; %trim to same length (might be off by 1)
    clean_headbasey(1:length(tmpx))=tmpy; %trim to same length (might be off by 1)
else
    clean_headbasex=clean_headbasex(1:length(nosex)); %trim to same length (might be off by 1)
    clean_headbasey=clean_headbasey(1:length(nosex)); %trim to same length (might be off by 1)
end

goodframes=find(tailbaseprob>=pthresh); %frames with prob above thresh
errframes=find(tailbaseprob<pthresh); %find missing frames
[clean_tailbasex, ty]=resample(tailbasex(goodframes), goodframes, 1, 'pchip');
[clean_tailbasey, ty]=resample(tailbasey(goodframes), goodframes, 1, 'pchip');
if length(nosex)>length(clean_tailbasex)
    tmpx=clean_tailbasex;
    tmpy=clean_tailbasey;
    clean_tailbasex=zeros(size(nosex));
    clean_tailbasey=zeros(size(nosex));
    clean_tailbasex(1:length(tmpx))=tmpx; %trim to same length (might be off by 1)
    clean_tailbasey(1:length(tmpx))=tmpy; %trim to same length (might be off by 1)
else
    clean_tailbasex=clean_tailbasex(1:length(nosex)); %trim to same length (might be off by 1)
    clean_tailbasey=clean_tailbasey(1:length(nosex)); %trim to same length (might be off by 1)
end

%smooth
fprintf('\nfiltering...')
[b,a]=butter(3, .25);
snosex=filtfilt(b,a,nosex);
snosey=filtfilt(b,a,nosey);
sheadbasex=filtfilt(b,a,clean_headbasex);
sheadbasey=filtfilt(b,a,clean_headbasey);
stailbasex=filtfilt(b,a,clean_tailbasex);
stailbasey=filtfilt(b,a,clean_tailbasey);
scricketx=filtfilt(b,a,clean_cricketfrontx);
scrickety=filtfilt(b,a,clean_cricketfronty);

if plotit
    %check the results of cleaning and smoothing
    
    figure, hold on
    t=1:length(cricketfrontx);
    plot(t, cricketfrontx, t, cricketfronty)
    plot(errframes, cricketfrontx(errframes), 'ro')
    plot(goodframes, cricketfrontx(goodframes), 'go')
    plot(t, cricketprob*100)
    plot(t, scricketx,t, scrickety, 'k', 'linewi', 2)
    legend('cricket', 'cricket errframes', 'cricket good frames',...
        'cricketprob', 'cleaned & smoothed cricket')

    figure, hold on
    plot(t, headbasex, t, headbasey)
    plot(errframes, headbasex(errframes), 'ro')
    plot(goodframes, headbasex(goodframes), 'go')
    plot(t, headbaseprob*100)
    plot(t, sheadbasex,t, sheadbasey, 'k', 'linewi', 2)
        legend('headbase', 'head errframes', 'head good frames',...
        'mouseprob', 'cleaned & smoothed head')

    figure
    plot(headbasex, headbasey)
    hold on
    plot(sheadbasex, sheadbasey)
    plot(scricketx, scrickety)
    title('cleaned and smoothed data')
    legend('raw headbase', 'cleaned & smoothed headbase', 'cleaned & smoothed cricket')
    set(gca, 'ydir', 'reverse')

    figure
    hold on
    plot(sheadbasex, sheadbasey, stailbasex, stailbasey, scricketx, scrickety)
    text(sheadbasex(1), sheadbasey(1), 'start')
    text(scricketx(1), scrickety(1), 'start')
    title('mouse & cricket positions, smoothed')
    set(gca, 'ydir', 'reverse')
    legend('headbase', 'tailbase', 'cricket')
end



%atan2d does the full circle (-180 to 180)
%atand does the half circle (-90 to 90)




fprintf('\ncomputing geometry...')
%calculating Relative Azimuth instead of using absolute angles
% %solve the triangle using the cosine rule
% a=COM-to-nose distance
% b=COM-to-cricket
% c=nose-to-cricket
% then azimuth=arccos((a2 + b2 - c2)/(2ab))
%
%nose is unreliably tracked, so switching to tailbase-headbase
a=sqrt((stailbasex-sheadbasex).^2 + (stailbasey-sheadbasey).^2);
b=sqrt((stailbasex-scricketx).^2 + (stailbasey-scrickety).^2);
c=sqrt((sheadbasex-scricketx).^2 + (sheadbasey-scrickety).^2);
RelativeAzimuth=acosd((a.^2+b.^2-c.^2)./(2.*a.*b));

%an alternative is to use the ears, which should be orthogonal to mouse
%bearing

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
deltax=scricketx-sheadbasex;
deltay=scrickety-sheadbasey;

range=sqrt(deltax.^2 + deltay.^2);

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
    th=title(datapath, 'interpreter', 'none');
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

% fit ellipse to arena to find distance-to-wall
d=dir('*_labeled.mp4');
movie_filename2=d(1).name;
v1 = VideoReader(movie_filename2);
oneframe = read(v1, 1) ;
%the circle is an ellipse since cameras are not square I guess

%try loading arena wall points from file
try
    figure
    imagesc(oneframe)
    hold on
    wd=pwd;
    cd ..
    load arena_wall_ellipse.mat
    cd(wd)
catch
    cd(wd)
    %ask user to click points to locate arena wall
    title('click 10 times all around the perimeter wall')
    [xin,yin]=ginput(10);
    plot(xin, yin, '*')
    
    %fit an ellipse to those points
    %from https://www.mathworks.com/matlabcentral/answers/98522-how-do-i-fit-an-ellipse-to-my-data-in-matlab
    a0 = [1000 500 500 500];
    f = @(a) ((xin-a(1)).^2)/a(2).^2 + ((yin-a(3)).^2)/a(4).^2 -1;
    options = optimset('Display','iter');
    af = lsqnonlin(f, a0, [], [], options);
    t=0:pi/200:2*pi; %arbitrary length 401 points
    x_wall = af(1) + af(2)*cos(t);
    y_wall = af(3) + af(4)*sin(t);
    plot(x_wall, y_wall)
    plot(round(x_wall), round(y_wall) ,'co')
    %[xnew, ynew] is a collection of points along the perimeter wall
    
    cd ..
    save arena_wall_ellipse x_wall y_wall
    % next, for any x,y point, you can find the min distance to the perimeter set
end %
plot(round(x_wall(1:10:end)), round(y_wall(1:10:end)) ,'co')
title('check if the points are on the arena wall') 

clear mouse_thigmo_distance dx dy rm
for f=1:length(sheadbasex)
    for t=1:length(x_wall)
        dx=sheadbasex(f)-x_wall(t);
        dy=sheadbasey(f)-y_wall(t);
        rm(t)=sqrt(dx^2 + dy^2);
    end
    mouse_thigmo_distance(f)=min(rm);
end

for f=1:length(scricketx)
    for t=1:length(x_wall)
        dx=scricketx(f)-x_wall(t);
        dy=scrickety(f)-y_wall(t);
        rc(t)=sqrt(dx^2 + dy^2);
    end
    cricket_thigmo_distance(f)=min(rc);
end

%add derivatives (acceleration etc)
mouseacceleration=diff(speed);
cricketacceleration=diff(cspeed);
drange=diff(range);
dazimuth=diff(RelativeAzimuth);
%pad so everything remains the same length
mouseacceleration=[mouseacceleration;mouseacceleration(end)];
cricketacceleration=[cricketacceleration;cricketacceleration(end)];
drange=[drange;drange(end)];
dazimuth=[dazimuth;dazimuth(end)];

%compute decomposed velocities 
    %compute theta, the angle between mouse velocity and cricket location
    % %solve the triangle using the cosine rule
    % a=COM(t) to COM(t+1) distance
    % b=COM(t) to cricket(t) distance
    % c=COM(t+1) to cricket(t) distance
    % then theta=arccos((a2 + b2 - c2)/(2ab))
    %and we decompose speed into v0, towards cricket, and v90, orthogonal to
    %cricket (speed is given by a)
    %v0=a.*cosd(theta)
    %v90=a.*sind(theta)
    %first, for mouse speed
    clear a b c theta
    a=speed;
    b=sqrt((sheadbasex-scricketx).^2 ...
        + (sheadbasey-scrickety).^2);
    for f=1:length(sheadbasex)-1
        c(f)=sqrt((sheadbasex(f+1)-scricketx(f)).^2 ...
            +(sheadbasey(f+1)-scrickety(f)).^2);
    end
    a=a(:);
    b=b(1:length(a));
    c=[c(:); c(end)]; %pad to match length of a & b
    
    theta=acosd((a.^2+b.^2-c.^2)./(2.*a.*b));
    v0=a.*cosd(theta);
    v90=a.*sind(theta);
    mousevelocity0=v0;
    mousevelocity90=v90;
    
    %second, for cricket speed
    % a=cricketxy(t) to cricketxy(t+1) distance = cricket speed
    % b=cricketxy(t) to mouseCOM(t) distance
    % c=cricketxy(t+1) to mouseCOM(t) distance
    clear a b c theta
    a=cspeed;
    b=sqrt((sheadbasex-scricketx).^2 ...
        + (sheadbasey-scrickety).^2);
    for f=1:length(sheadbasex)-1
        c(f)=sqrt((sheadbasex(f)-scricketx(f+1)).^2 ...
            +(sheadbasey(f)-scrickety(f+1)).^2);
    end
    a=a(:);
    b=b(1:length(a));
    c=[c(:); c(end)];

    
    theta=acosd((a.^2+b.^2-c.^2)./(2.*a.*b));
    cv0=a.*cosd(theta);
    cv90=a.*sind(theta);
    cricketvelocity0=cv0;
    cricketvelocity90=cv90;
    
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
    'mouse_thigmo_distance', 'cricket_thigmo_distance', ...
    'mouseacceleration', 'cricketacceleration', ...
    'drange', 'dazimuth', ...
    'mousevelocity0',    'mousevelocity90', ...
    'cricketvelocity0',    'cricketvelocity90', ...
    'generated_on', 'generated_by')
fprintf('  done\n')





