function ConvertSocialDLCtoGeometry(varargin)
% usage: ConvertSocialDLCtoGeometry([datapath], ['plot'])
%     datapath - folder with DLC tracks (defaults to current directory)
%     'plot' - if you want to display some plots (defaults to no plotting)
%
% moddified from ConvertDLCtoGeometry to analyze social behavior (2 mice)
% instead of prey cpature behavior.
%this function loads DLC (x,y,t) tracking data from an individual session, and computes
%geometric variables like speed, range, azimuth, and saves to local file.
%optionally displays some plots if you pass 'plot' as a second argument

%You could call this function from a batch processer using a dir list


plotit=1;
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
% nose1
% nose2
% baseOfHead1
% baseOfHead2
% bodyCOM1
% bodyCOM2



baseOfHead1=Sky.madlc.baseOfHead1;
baseOfHead2=Sky.madlc.baseOfHead2;
nose1=Sky.madlc.nose1;
nose2=Sky.madlc.nose2;
bodyCOM1=Sky.madlc.bodyCOM1;
bodyCOM2=Sky.madlc.bodyCOM2;



try
    framerate=Sky.vid.framerate;
catch %framerate was added to ProcessCams on Feb 12, 2021
    fprintf('\ngetting framerate from video...')
    v=VideoReader(Sky.vid.name);
    framerate=v.FrameRate;
    fprintf('\t%.2f', framerate)
end

if plotit
    t=1:length(baseOfHead1);
    t=t/framerate; % t is in seconds
    
    figure
    plot(baseOfHead1(:,1), baseOfHead1(:,2), '.')
    hold on
    plot(baseOfHead2(:,1), baseOfHead2(:,2), '.')
    title('raw data')
    legend('mouse1 headbase', 'mouse2 headbase')
    set(gca, 'ydir', 'reverse')
    
end

fprintf('\n%d total frames in video)', length(baseOfHead1))

headbase1x=baseOfHead1(:,1);
headbase1y=baseOfHead1(:,2);
headbase1prob=baseOfHead1(:,3);
headbase2x=baseOfHead2(:,1);
headbase2y=baseOfHead2(:,2);
headbase2prob=baseOfHead2(:,3);
nose1x=nose1(:,1);
nose1y=nose1(:,2);
nose1prob=nose1(:,3);
nose2x=nose2(:,1);
nose2y=nose2(:,2);
nose2prob=nose2(:,3);
bodyCOM1x=bodyCOM1(:,1);
bodyCOM1y=bodyCOM1(:,2);
bodyCOM1prob=bodyCOM1(:,3);
bodyCOM2x=bodyCOM2(:,1);
bodyCOM2y=bodyCOM2(:,2);
bodyCOM2prob=bodyCOM2(:,3);


numframes=length(headbase1x);
fprintf('\n%d frames )', numframes)

fprintf('\ncleaning  tracks using dlc probabilities...')
pthresh=.5;

% find glitches using probability values and clean using resample
errframes1=find(headbase1prob<pthresh); %find missing frames - not actually used
errframes2=find(headbase2prob<pthresh); %find missing frames

goodframes1=find(headbase1prob>=pthresh); %frames with prob above thresh
if goodframes1(1)~=1 goodframes1=[1; goodframes1];end
if goodframes1(end)~=numframes goodframes1=[goodframes1; numframes];end
[clean_headbase1x, ty]=resample(headbase1x(goodframes1), goodframes1, 1, 'pchip');
[clean_headbase1y, ty]=resample(headbase1y(goodframes1), goodframes1, 1, 'pchip');

goodframes2=find(headbase2prob>=pthresh); %frames with prob above thresh
if goodframes2(1)~=1 goodframes2=[1; goodframes2];end
if goodframes2(end)~=numframes goodframes2=[goodframes2; numframes];end
[clean_headbase2x, ty]=resample(headbase2x(goodframes2), goodframes2, 1, 'pchip');
[clean_headbase2y, ty]=resample(headbase2y(goodframes2), goodframes2, 1, 'pchip');

goodframes1=find(bodyCOM1prob>=pthresh); %frames with prob above thresh
if goodframes1(1)~=1 goodframes1=[1; goodframes1];end
if goodframes1(end)~=numframes goodframes1=[goodframes1; numframes];end
[clean_bodyCOM1x, ty]=resample(bodyCOM1x(goodframes1), goodframes1, 1, 'pchip');
[clean_bodyCOM1y, ty]=resample(bodyCOM1y(goodframes1), goodframes1, 1, 'pchip');

goodframes2=find(bodyCOM2prob>=pthresh); %frames with prob above thresh
if goodframes2(1)~=1 goodframes2=[1; goodframes2];end
if goodframes2(end)~=numframes goodframes2=[goodframes2; numframes];end
[clean_bodyCOM2x, ty]=resample(bodyCOM2x(goodframes2), goodframes2, 1, 'pchip');
[clean_bodyCOM2y, ty]=resample(bodyCOM2y(goodframes2), goodframes2, 1, 'pchip');

goodframes1=find(nose1prob>=pthresh); %frames with prob above thresh
if goodframes1(1)~=1 goodframes1=[1; goodframes1];end
if goodframes1(end)~=numframes goodframes1=[goodframes1; numframes];end
[clean_nose1x, ty]=resample(nose1x(goodframes1), goodframes1, 1, 'pchip');
[clean_nose1y, ty]=resample(nose1y(goodframes1), goodframes1, 1, 'pchip');

goodframes2=find(nose2prob>=pthresh); %frames with prob above thresh
if goodframes2(1)~=1 goodframes2=[1; goodframes2];end
if goodframes2(end)~=numframes goodframes2=[goodframes2; numframes];end
[clean_nose2x, ty]=resample(nose2x(goodframes2), goodframes2, 1, 'pchip');
[clean_nose2y, ty]=resample(nose2y(goodframes2), goodframes2, 1, 'pchip');

%clean up any stray frames added by resampling
clean_bodyCOM1x= clean_bodyCOM1x(1:numframes);
clean_headbase1x=  clean_headbase1x(1:numframes);
clean_nose1x     = clean_nose1x(1:numframes);
clean_bodyCOM1y   =clean_bodyCOM1y(1:numframes);
clean_headbase1y  =clean_headbase1y(1:numframes);
clean_nose1y      =clean_nose1y(1:numframes);
clean_bodyCOM2x   =clean_bodyCOM2x(1:numframes);
clean_headbase2x  =clean_headbase2x(1:numframes);
clean_nose2x      =clean_nose2x(1:numframes);
clean_bodyCOM2y   =clean_bodyCOM2y(1:numframes);
clean_headbase2y  =clean_headbase2y(1:numframes);
clean_nose2y    =clean_nose2y(1:numframes);
fprintf('\t done cleaning.\n')
%this makes  me realize that thigmo distance is a good error to check
%for. x and y could each get close to 0, but some violations are only
%obvious when you look at x and y together (and see if they are outside
%the arena)


% fit ellipse to arena to find distance-to-wall
d=dir('*_labeled.mp4');
movie_filename2=d(1).name;
v1 = VideoReader(movie_filename2);
oneframe = read(v1, 1) ;
%the circle is an ellipse since cameras are not square I guess

%try loading arena wall points from file
fprintf('\n checking for arena wall file...\n')
try
    figure
    imagesc(oneframe)
    shg
    hold on
    wd=pwd;
    cd ..
    load arena_wall_ellipse.mat
    cd(wd)
    fprintf('\n found arena wall file, double-check that the points are on the arena wall...\n')

catch
    fprintf('\ncould not found arena wall file, \nplease click 10 times all around the perimeter wall...')
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
    arena_center= [af(1), af(3)];
    plot(arena_center(1), arena_center(2) ,'ro')
    arena_radius=mean([af(2), af(4)]);
    line([arena_center(1) arena_center(1)+arena_radius], [arena_center(2) arena_center(2)])
    cm_per_px=30/arena_radius;
    
    cd ..
    save arena_wall_ellipse x_wall y_wall af arena_radius arena_center cm_per_px
    % next, for any x,y point, you can find the min distance to the perimeter set
end %
plot(round(x_wall(1:10:end)), round(y_wall(1:10:end)) ,'co')
title('check if the points are on the arena wall')
drawnow


%compute rho = distance from arena center
% rho1 - use bodyCOM mouse 1
% rhon1, rhohb1 - same but for nose, headbase (just in case of glitches)
for f=1:length(clean_bodyCOM1x)
    rho1x=clean_bodyCOM1x(f)-arena_center(1);
    rho1y=clean_bodyCOM1y(f)-arena_center(2);
    rho1(f)=cm_per_px*sqrt(rho1x^2 + rho1y^2);
    
    rhon1x=clean_nose1x(f)-arena_center(1);
    rhon1y=clean_nose1y(f)-arena_center(2);
    rhon1(f)=cm_per_px*sqrt(rhon1x^2 + rhon1y^2);
    
    rhohb1x=clean_headbase1x(f)-arena_center(1);
    rhohb1y=clean_headbase1y(f)-arena_center(2);
    rhohb1(f)=cm_per_px*sqrt(rhohb1x^2 + rhohb1y^2);
    
    rho2x=clean_bodyCOM2x(f)-arena_center(1);
    rho2y=clean_bodyCOM2y(f)-arena_center(2);
    rho2(f)=cm_per_px*sqrt(rho2x^2 + rho2y^2);
    
     rhon2x=clean_nose2x(f)-arena_center(1);
    rhon2y=clean_nose2y(f)-arena_center(2);
    rhon2(f)=cm_per_px*sqrt(rhon2x^2 + rhon2y^2);
    
    rhohb2x=clean_headbase2x(f)-arena_center(1);
    rhohb2y=clean_headbase2y(f)-arena_center(2);
    rhohb2(f)=cm_per_px*sqrt(rhohb2x^2 + rhohb2y^2);
  
end

rho1_errframes=find(rho1>30); %find impossible frames outside the arena
rhon1_errframes=find(rhon1>34); %find impossible frames outside the arena
rhohb1_errframes=find(rhohb1>34); %find impossible frames outside the arena
rho2_errframes=find(rho2>30); %find impossible frames outside the arena
rhon2_errframes=find(rhon2>34); %find impossible frames outside the arena
rhohb2_errframes=find(rhohb2>34); %find impossible frames outside the arena

% it seems like nose and headbase can be a little further than 30cm from the center and still look pretty valid

% plot distance from wall and look for violations as evidence of glitches
if plotit
    figure; hold on
    plot(1:numframes, rho1, '-', rho1_errframes, rho1(rho1_errframes), 'ro')
    plot(1:numframes, rhon1, '-', rhon1_errframes, rhon1(rhon1_errframes), 'go')
    plot(1:numframes, rhohb1, '-', rhohb1_errframes, rhohb1(rhohb1_errframes), 'bo')
    plot(1:numframes, rho2, '-', rho2_errframes, rho2(rho2_errframes), 'ro')
    plot(1:numframes, rhon2, '-', rhon2_errframes, rhon2(rhon2_errframes), 'go')
    plot(1:numframes, rhohb2, '-', rhohb2_errframes, rhohb2(rhohb2_errframes), 'bo')
    ylabel('rho')
    
    %same as above but in the arena
    figure;hold on
    plot(clean_bodyCOM1x, clean_bodyCOM1y, '-', clean_bodyCOM1x(rho1_errframes), clean_bodyCOM1y(rho1_errframes), 'ro')
    plot(clean_nose1x, clean_nose1y, '-', clean_nose1x(rhon1_errframes), clean_nose1y(rhon1_errframes), 'go')
    plot(clean_headbase1x, clean_headbase1y, '-', clean_headbase1x(rhohb1_errframes), clean_headbase1y(rhohb1_errframes), 'bo')
    plot(clean_bodyCOM2x, clean_bodyCOM2y, '-', clean_bodyCOM2x(rho2_errframes), clean_bodyCOM2y(rho2_errframes), 'ro')
    plot(clean_nose2x, clean_nose2y, '-', clean_nose2x(rhon2_errframes), clean_nose2y(rhon2_errframes), 'go')
    plot(clean_headbase2x, clean_headbase2y, '-', clean_headbase2x(rhohb2_errframes), clean_headbase2y(rhohb2_errframes), 'bo')
end

%do another round of cleaning using the rho errorframes to resample
goodframes=setdiff(1:numframes, rho1_errframes);
if goodframes(1)~=1 goodframes=[1; goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes; numframes];end
[cleaner_bodyCOM1x, ty]=resample(clean_bodyCOM1x(goodframes), goodframes, 1, 'pchip');
[cleaner_bodyCOM1y, ty]=resample(clean_bodyCOM1y(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rhon1_errframes);
if goodframes(1)~=1 goodframes=[1; goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes(:); numframes];end
[cleaner_nose1x, ty]=resample(clean_nose1x(goodframes), goodframes, 1, 'pchip');
[cleaner_nose1y, ty]=resample(clean_nose1y(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rhohb1_errframes);
if goodframes(1)~=1 goodframes=[1; goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes(:); numframes];end
[cleaner_headbase1x, ty]=resample(clean_headbase1x(goodframes), goodframes, 1, 'pchip');
[cleaner_headbase1y, ty]=resample(clean_headbase1y(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rho2_errframes);
if goodframes(1)~=1 goodframes=[1; goodframes(:)];end
if goodframes(end)~=numframes goodframes=[goodframes(:); numframes];end
[cleaner_bodyCOM2x, ty]=resample(clean_bodyCOM2x(goodframes), goodframes, 1, 'pchip');
[cleaner_bodyCOM2y, ty]=resample(clean_bodyCOM2y(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rhon2_errframes);
if goodframes(1)~=1 goodframes=[1; goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes(:); numframes];end
[cleaner_nose2x, ty]=resample(clean_nose2x(goodframes), goodframes, 1, 'pchip');
[cleaner_nose2y, ty]=resample(clean_nose2y(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rhohb2_errframes);
if goodframes(1)~=1 goodframes=[1; goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes(:); numframes];end
[cleaner_headbase2x, ty]=resample(clean_headbase2x(goodframes), goodframes, 1, 'pchip');
[cleaner_headbase2y, ty]=resample(clean_headbase2y(goodframes), goodframes, 1, 'pchip');

% recompute rho to see how well we cleaned it up
for f=1:length(cleaner_bodyCOM1x)
    rho1x=cleaner_bodyCOM1x(f)-arena_center(1);
    rho1y=cleaner_bodyCOM1y(f)-arena_center(2);
    rho1(f)=cm_per_px*sqrt(rho1x^2 + rho1y^2);
    
    rho2x=cleaner_bodyCOM2x(f)-arena_center(1);
    rho2y=cleaner_bodyCOM2y(f)-arena_center(2);
    rho2(f)=cm_per_px*sqrt(rho2x^2 + rho2y^2);
end

if plotit
    figure; hold on
    plot(cleaner_bodyCOM1x, cleaner_bodyCOM1y, '-', cleaner_bodyCOM1x(rho1_errframes), cleaner_bodyCOM1y(rho1_errframes), 'ro')
    plot(cleaner_nose1x, cleaner_nose1y, '-', cleaner_nose1x(rhon1_errframes), cleaner_nose1y(rhon1_errframes), 'ro')
    plot(cleaner_headbase1x, cleaner_headbase1y, '-', cleaner_headbase1x(rhohb1_errframes), cleaner_headbase1y(rhohb1_errframes), 'ro')
    plot(cleaner_bodyCOM2x, cleaner_bodyCOM2y, '-', cleaner_bodyCOM2x(rho2_errframes), cleaner_bodyCOM2y(rho2_errframes), 'ro')
    plot(cleaner_nose2x, cleaner_nose2y, '-', cleaner_nose2x(rhon2_errframes), cleaner_nose2y(rhon2_errframes), 'ro')
    plot(cleaner_headbase2x, cleaner_headbase2y, '-', cleaner_headbase2x(rhohb2_errframes), cleaner_headbase2y(rhohb2_errframes), 'ro')
    title('after cleaning impossible frames outside the arena')
    
    
    
    figure; hold on
    plot(rho1, '-')
    plot(rho2, '-')
    rho_errframes1=find(rho1>30); %find impossible frames outside the arena
    plot(rho_errframes1, rho1(rho_errframes1), 'ro')
    rho_errframes2=find(rho2>30); %find impossible frames outside the arena
    plot(rho_errframes2, rho2(rho_errframes2), 'go')
    ylabel('rho after recompute')
    title('recomputed rho after cleaning frames outside the arena')
end


mouse1_thigmo=30-rho1;
mouse2_thigmo=30-rho2;



%smooth
%note that smooth using rlowess option works incredibly well, but it is
%extremely slow (5 minutes per trace)
if (1)
    fprintf('\nsmoothing tracks the really slow way...')
    [b,a]=butter(3, .15);
    tic
    i=0;
    nbytes = fprintf('%d/12', i );
    
    smheadbase1x=smooth(cleaner_headbase1x, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smheadbase1y=smooth(cleaner_headbase1y, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smheadbase2x=smooth(cleaner_headbase2x, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smheadbase2y=smooth(cleaner_headbase2y, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smnose1x=smooth(cleaner_nose1x, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smnose1y=smooth(cleaner_nose1y, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smnose2x=smooth(cleaner_nose2x, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smnose2y=smooth(cleaner_nose2y, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smbodyCOM1x=smooth(cleaner_bodyCOM1x, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smbodyCOM1y=smooth(cleaner_bodyCOM1y, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smbodyCOM2x=smooth(cleaner_bodyCOM2x, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smbodyCOM2y=smooth(cleaner_bodyCOM2y, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    
    fprintf('\ndone smoothing ')
    toc
else
    fprintf('\nskipping the smoothing step and filtering instead to save time')
    [b,a]=butter(3, .5);
    
    smbodyCOM1x=filtfilt(b,a, cleaner_bodyCOM1x);
    smheadbase1x=filtfilt(b,a,  cleaner_headbase1x);
    smnose1x     =filtfilt(b,a, cleaner_nose1x);
    smbodyCOM1y   =filtfilt(b,a,cleaner_bodyCOM1y);
    smheadbase1y  =filtfilt(b,a,cleaner_headbase1y);
    smnose1y      =filtfilt(b,a,cleaner_nose1y);
    smbodyCOM2x=filtfilt(b,a,cleaner_bodyCOM2x);
    smheadbase2x  =filtfilt(b,a,cleaner_headbase2x);
    smnose2x      =filtfilt(b,a,cleaner_nose2x);
    smbodyCOM2y   =filtfilt(b,a,cleaner_bodyCOM2y);
    smheadbase2y  =filtfilt(b,a,cleaner_headbase2y);
    smnose2y    =filtfilt(b,a,cleaner_nose2y);
end




if plotit
    %check the results of cleaning and smoothing
    
    figure
    plot(smbodyCOM1x, smbodyCOM1y, '.')
    hold on
    plot(smbodyCOM2x, smbodyCOM2y, '.')
    title('smoothed data')
    legend('mouse1 COM', 'mouse2 COM')
    set(gca, 'ydir', 'reverse')
    
    %     figure, hold on
    %     t=1:length(cricketfrontx);
    %     plot(t, cricketfrontx, t, cricketfronty)
    %     plot(errframes, cricketfrontx(errframes), 'ro')
    %     plot(goodframes, cricketfrontx(goodframes), 'go')
    %     plot(t, cricketprob*100)
    %     plot(t, scricketx,t, scrickety, 'k', 'linewi', 2)
    %     legend('cricket', 'cricket errframes', 'cricket good frames',...
    %         'cricketprob', 'cleaned & smoothed cricket')
    
    
    figure
    subplot(211)
    plot(t, smbodyCOM1x,'b',t, smbodyCOM1y, 'm', 'linewi', 2)
    title('mouse 1 smoothed bodyCOM ')
    subplot(212)
    plot(t, smbodyCOM2x,'b',t, smbodyCOM2y, 'm', 'linewi', 2)
    title('mouse 2 smoothed bodyCOM ')
    
    figure
    subplot(211)
    plot(t, smheadbase1x,'b',t, smheadbase1y, 'm', 'linewi', 2)
    title('mouse 1 smoothed bodyCOM ')
    subplot(212)
    plot(t, smheadbase2x,'b',t, smheadbase2y, 'm', 'linewi', 2)
    title('mouse 2 smoothed bodyCOM ')
    
    
    figure, hold on
    plot(t, headbase1x, t, headbase1y)
    plot(t(errframes1), headbase1x(errframes1), 'ro')
    plot(t(goodframes1), headbase1x(goodframes1), 'go')
    plot(t, headbase1prob*100)
    plot(t, smheadbase1x,'b',t, smheadbase1y, 'm', 'linewi', 2)
    legend('headbasex','headbasey', 'head errframes', 'head good frames',...
        'mouseprob', 'cleaned & smoothed head x', 'cleaned & smoothed head y')
    title('compare raw vs cleaned/smoothed data')
    
    figure, hold on
    plot(t, headbase1prob*100)
    plot(t, smheadbase1x,'b',t, smheadbase1y, 'm', 'linewi', 2)
    legend( 'headbase1prob', 'cleaned & smoothed head x', 'cleaned & smoothed head y')
    
    
    
    figure
    plot(headbase1x, headbase1y)
    hold on
    plot(smheadbase1x, smheadbase1y)
    plot(smheadbase2x, smheadbase2y)
    title('cleaned and smoothed data')
    legend('raw headbase', 'cleaned & smoothed headbase', 'cleaned & smoothed cricket')
    set(gca, 'ydir', 'reverse')
    
    
    
    
    figure
    plot(t, smnose1x, t, smnose1y,t, smnose2x, t, smnose2y )
    
    figure
    hold on
    p1=plot(smheadbase1x, smheadbase1y, smbodyCOM1x, smbodyCOM1y, smnose1x, smnose1y);
    p2=plot(smheadbase2x, smheadbase2y, smbodyCOM2x, smbodyCOM2y, smnose2x, smnose2y);
    text(smheadbase1x(1), smheadbase1y(1), 'mouse1 start')
    text(smheadbase2x(1), smheadbase2y(1), 'mouse2 start')
    title('mouse positions, smoothed')
    set([p1 p2], 'linewi',2)
    set(gca, 'ydir', 'reverse')
    legend('headbase1', 'bodyCOM1', 'nose1', 'headbase2', 'bodyCOM2', 'nose2')
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
% note that azimuth defined in this way ranges 0-180 (no negative values), and is the same for
% left vs right. In other words, target at either 3 o'clock or 9 o'clock is 90° 
%
%in earlier version the nose was unreliably tracked, we switched to tailbase-headbase
%I'll try nose first here
a=sqrt((smbodyCOM1x-smnose1x).^2 + (smbodyCOM1y-smnose1y).^2);
b=sqrt((smbodyCOM1x-smnose2x).^2 + (smbodyCOM1y-smnose2y).^2);
c=sqrt((smnose1x-smnose2x).^2 + (smnose1y-smnose2y).^2);
RelativeAzimuth1=acosd((a.^2+b.^2-c.^2)./(2.*a.*b));

% now for the other mouse
a=sqrt((smbodyCOM2x-smnose2x).^2 + (smbodyCOM2y-smnose2y).^2);
b=sqrt((smbodyCOM2x-smnose1x).^2 + (smbodyCOM2y-smnose1y).^2);
c=sqrt((smnose2x-smnose1x).^2 + (smnose2y-smnose1y).^2);
RelativeAzimuth2=acosd((a.^2+b.^2-c.^2)./(2.*a.*b));




%an alternative is to use the ears, which should be orthogonal to mouse
%bearing

if plotit
    
    figure
    hold on
    plot(RelativeAzimuth1)
    plot(RelativeAzimuth2)
    xlabel('frames')
    ylabel('azimuth in degrees')
    title(' azimuths')
    % cd(analysis_plots_dir)
    % if exist('analysis_plots.ps')==2
    %     print -dpsc2 'analysis_plots.ps' -append -bestfit
    % else
    %     print -dpsc2 'analysis_plots.ps' -bestfit
    % end
    % line(xlim, [0 0], 'linestyle', '--')
end


%range (distance to target)
deltax=smnose2x-smnose1x;
deltay=smnose2y-smnose1y;
range=sqrt(deltax.^2 + deltay.^2);

%mouse speeds
speed1=sqrt(diff(smbodyCOM1x).^2 + diff(smbodyCOM1y).^2);
speed2=sqrt(diff(smbodyCOM2x).^2 + diff(smbodyCOM2y).^2);
fprintf('\nsmoothing mouse speeds very slowly...')
smspeed1=smooth(speed1, 'rlowess');
smspeed2=smooth(speed2, 'rlowess');
smspeed1=[smspeed1(1); smspeed1]; %pad with duped first point so vectors are same length after diff
smspeed2=[smspeed2(1); smspeed2]; %pad with duped first point so vectors are same length after diff
speed1=smspeed1;
speed2=smspeed2;
fprintf(' done\n')

%animate the mouse and cricket, along with angles, write to video
if 0
    [p, f, e]=fileparts(datapath);
    
    vidfname=sprintf('%s.avi', f);
    v=VideoWriter(vidfname);
    open(v);
    figure
       subplot(311)
    h=plot(smbodyCOM1x(1), smbodyCOM1y(1), 'bo', smnose1x(1), smnose1y(1), 'ko', ...
        smheadbase1x(1), smheadbase1y(1), 'ko',...
    smbodyCOM2x(1), smbodyCOM2y(1), 'ro', smnose2x(1), smnose2y(1), 'mo', ...
            smheadbase2x(1), smheadbase2y(1), 'mo');
    legend('mouse1 COM', 'mouse1 nose','mouse1 head', 'mouse2 COM', 'mouse2 nose', 'mouse2 head', 'Location', 'EastOutside')
    subplot(312)
    hold on
    h2=plot(1,range(1), 'k.', 1, mouse1_thigmo(1),'b.',1, mouse2_thigmo(1), 'r.');
    xlim([0 numframes])
    subplot(313)
hold on
h3=plot(1, RelativeAzimuth1(1), 'b.', 1, RelativeAzimuth2(1), 'r.');
        xlim([0 numframes])

    wb=waitbar(0, 'building animation');
    for f=1:200 %length(smbodyCOM1x)
        waitbar(f/length(smbodyCOM1x), wb);
        set(h(1), 'xdata', smbodyCOM1x(f), 'ydata', smbodyCOM1y(f))
        set(h(2), 'xdata', smnose1x(f), 'ydata', smnose1y(f))
        set(h(3), 'xdata', smheadbase1x(f), 'ydata', smheadbase1y(f))
        set(h(4), 'xdata', smbodyCOM2x(f), 'ydata', smbodyCOM2y(f))
        set(h(5), 'xdata', smnose2x(f), 'ydata', smnose2y(f))
        set(h(6), 'xdata', smheadbase2x(f), 'ydata', smheadbase2y(f))
        
        subplot(312)
 plot(f,range(f), 'k.', f, mouse1_thigmo(f),'b.', f, mouse2_thigmo(f), 'r.');
%         hnew2=plot(f,range(f), 'ko', f, mouse1_thigmo(f),'bo', f, mouse2_thigmo(f), 'ro');
%         set(h2, 'visible', 'off');
%         h2=hnew2;
%         
        subplot(313)
        plot(f, RelativeAzimuth1(f), 'b.', f, RelativeAzimuth2(f), 'r.');
      
        
        drawnow
        frame = getframe(gcf);
        writeVideo(v,frame);
    end
    close(v)
    close(wb)
end


if plotit
    fprintf('\nplotting...')
    figure
    hold on
    plot(t, speed1)
    plot(t, speed2)
    xlabel('time, s')
    ylabel('speed, px/frame')
    title('mouse speeds vs. time')
    
    
    figure
    title('range, azimuth, and speed over time (mismatched units')
    plot(t, 10*speed1, t, 10*speed2, t, range, t, RelativeAzimuth1, t, RelativeAzimuth2) %careful, these are in different units
    legend('mouse1 speed', 'mouse2 speed', 'range', 'azimuth1', 'azimuth2')
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
    plot(speed1, range, 'k')
    hold on
    
    
    cmap=colormap;
    for j=1:3; cmap2(:,j)=interp(cmap(:,j), ceil(numframes/64));end
    cmap2(find(cmap2>1))=1;
    for f=1:numframes-1
        plot(speed1(f), range(1+f), '.', 'color', cmap2(f,:))
    end
    text(speed1(1), range(2), 'start')
    text(speed1(end), range(end), 'end')
    xlabel('mouse1 speed')
    ylabel('range')
    title('range vs. speed')
    % print -dpsc2 'analysis_plots.ps' -append
    
    figure
    h=plot(range, RelativeAzimuth1);
    set(h, 'color', [.7 .7 .7]) %grey
    hold on
    cmap=colormap;
    for j=1:3; cmap2(:,j)=interp(cmap(:,j), ceil(numframes/64));end
    cmap2(find(cmap2>1))=1;
    for f=1:numframes
        h=plot(range(f), RelativeAzimuth1(f), '.', 'color', cmap2(f,:));
        set(h, 'markersize', 20)
    end
    text(range(1), RelativeAzimuth1(2), 'start')
    text(range(end), RelativeAzimuth1(end), 'end')
    xl=xlim;yl=ylim;
    xlim([0 xl(2)]);
    xlabel('range, pixels')
    ylabel('mouse 1 azimuth, degrees')
    title('mouse1  azimuth vs. range')
    % print -dpsc2 'analysis_plots.ps' -append
end





%add derivatives (acceleration etc)
mouse1acceleration=diff(speed1);
mouse2acceleration=diff(speed2);
drange=diff(range);
dazimuth1=diff(RelativeAzimuth1);
dazimuth2=diff(RelativeAzimuth2);
%pad so everything remains the same length
mouse1acceleration=[mouse1acceleration;mouse1acceleration(end)];
mouse2acceleration=[mouse2acceleration;mouse2acceleration(end)];
drange=[drange;drange(end)];
dazimuth1=[dazimuth1;dazimuth1(end)];
dazimuth2=[dazimuth2;dazimuth2(end)];

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
a=speed1;
b=sqrt((smbodyCOM1x-smbodyCOM2x).^2 ...
    + (smbodyCOM1y-smbodyCOM2y).^2);
for f=1:length(smbodyCOM1x)-1
    c(f)=sqrt((smbodyCOM1x(f+1)-smbodyCOM2x(f)).^2 ...
        +(smbodyCOM1y(f+1)-smbodyCOM2y(f)).^2);
end
a=a(:);
b=b(1:length(a));
c=[c(:); c(end)]; %pad to match length of a & b

theta=acosd((a.^2+b.^2-c.^2)./(2.*a.*b));
v0=a.*cosd(theta);
v90=a.*sind(theta);
mouse1velocity0=v0;
mouse1velocity90=v90;

%repeat for mouse 2
clear a b c theta
a=speed2;
b=sqrt((smbodyCOM2x-smbodyCOM1x).^2 ...
    + (smbodyCOM2y-smbodyCOM1y).^2);
for f=1:length(smbodyCOM2x)-1
    c(f)=sqrt((smbodyCOM2x(f+1)-smbodyCOM1x(f)).^2 ...
        +(smbodyCOM2y(f+1)-smbodyCOM2x(f)).^2);
end
a=a(:);
b=b(1:length(a));
c=[c(:); c(end)]; %pad to match length of a & b

theta=acosd((a.^2+b.^2-c.^2)./(2.*a.*b));
v0=a.*cosd(theta);
v90=a.*sind(theta);
mouse2velocity0=v0;
mouse2velocity90=v90;



    
%save results to local out file
fprintf('\nsaving to file %s...', outfilename)

generated_on=datestr(now);
generated_by=mfilename;

save(outfilename, 'speed1', 'speed2', 'range',...
    'RelativeAzimuth1','RelativeAzimuth2', ...
    'smnose1x', 'smnose1y',  ...
    'smbodyCOM1x',   'smheadbase1x', ...
    'smbodyCOM1y',   'smheadbase1y', ...
    'smbodyCOM2x',   'smheadbase2x',  'smnose2x'  ,  ...
    'smbodyCOM2y',   'smheadbase2y',  'smnose2y'    ,  ...
    'framerate', 'numframes', ...
    'datapath', 'behavior_datafile', 'outfilename', ...
    'mouse1_thigmo', 'mouse2_thigmo', ...
    'rho1', 'rho2', ...
    'mouse1acceleration', 'mouse2acceleration', ...
    'drange', 'dazimuth1','dazimuth2', ...
    'mouse1velocity0',    'mouse1velocity90', ...
    'mouse2velocity0',    'mouse2velocity90', ...
    'generated_on', 'generated_by')
fprintf('  done\n')







