function ConvertSocialDLCtoGeometry(varargin)
% usage: ConvertSocialDLCtoGeometry([datapath], ['plot'])
%    datapath - folder with DLC tracks (defaults to current directory)
%     'plot' - if you want to display some plots (defaults to no plotting)
%
% moddified from ConvertDLCtoGeometry to analyze social behavior (2 mice)
% instead of prey cpature behavior.
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

if plotit
    %for long videos, plotting can be very slow. So we only plot a subset
    %of data. 12000 frames (60 seconds) takes about 3 minutes to plot.
    numframes2plot=12000;
    frames2plot=1:numframes2plot;
end

cd(datapath)

% fprintf('\nforce re-process Behavior_mouse with ProcessCams in ConvertDLCtoGeometry')
% ProcessCams

d=dir('Behavior_mouse-*.mat');
if length(d)==0
    warning('no Behavior_mouse file in this directory')
    fprintf('\nrunning ProcessCams')
    ProcessCamsSocial
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
% m1_nose
% m1_headbase
% m1_tailbase
% m1_Lear
% m1_Rear
% m1_spine1
% m1_spine2
% m2_nose
% m2_headbase
% m2_tailbase
% m2_Lear
% m2_Rear
% m2_spine1
% m2_spine2

if ~isfield(Sky.madlc, 'm1_headbase')
    %probably what has happened is that Sky was created by
    %ProcessCamsSocial before DLC was run, so madlc doesn't have the
    %keypoints we expect. Too hard to do a force reprocess here since we
    %need to add ephys folders etc
    warning('ConvertSocialDLCtoGeometry did not find expected keypoints in Sky.madlc. Maybe DLC was run after ProcessCamsSocial? Trying to re-run ProcessCamsSocial ...')
    ProcessCamsSocial
    load(behavior_datafile)
end


m1_headbase=Sky.madlc.m1_headbase;
m2_headbase=Sky.madlc.m2_headbase;
m1_nose=Sky.madlc.m1_nose;
m2_nose=Sky.madlc.m2_nose;
m1_tailbase=Sky.madlc.m1_tailbase;
m2_tailbase=Sky.madlc.m2_tailbase;

m1_Lear=Sky.madlc.m1_Lear;
m1_Rear=Sky.madlc.m1_Rear;

try
    framerate=Sky.vid.framerate;
catch %framerate was added to ProcessCams on Feb 12, 2021
    fprintf('\ngetting framerate from video...')
    v=VideoReader(Sky.vid.name);
    framerate=v.FrameRate;
    fprintf('\t%.2f', framerate)
end

if plotit
    t=1:length(m1_headbase);
    t=t/framerate; % t is in seconds
    
    figure
    plot(m1_headbase((frames2plot),1), m1_headbase((frames2plot),2), '.')
    hold on
    plot(m2_headbase((frames2plot),1), m2_headbase((frames2plot),2), '.')
    title('raw data')
    legend('mouse1 headbase', 'mouse2 headbase')
    set(gca, 'ydir', 'reverse')
    print -dpsc2 'geometry_plots.ps' -append
    
end

fprintf('\n%d total frames in video', length(m1_headbase))

headbase1x=m1_headbase(:,1);
headbase1y=m1_headbase(:,2);
headbase1prob=m1_headbase(:,3);
headbase2x=m2_headbase(:,1);
headbase2y=m2_headbase(:,2);
headbase2prob=m2_headbase(:,3);
nose1x=m1_nose(:,1);
nose1y=m1_nose(:,2);
nose1prob=m1_nose(:,3);
nose2x=m2_nose(:,1);
nose2y=m2_nose(:,2);
nose2prob=m2_nose(:,3);
m1_tailbasex=m1_tailbase(:,1);
m1_tailbasey=m1_tailbase(:,2);
m1_tailbaseprob=m1_tailbase(:,3);
m2_tailbasex=m2_tailbase(:,1);
m2_tailbasey=m2_tailbase(:,2);
m2_tailbaseprob=m2_tailbase(:,3);

m1_Rearx=m1_Rear(:,1);
m1_Reary=m1_Rear(:,2);
m1_Rearprob=m1_Rear(:,3);
m1_Learx=m1_Lear(:,1);
m1_Leary=m1_Lear(:,2);
m1_Learprob=m1_Lear(:,3);
%should add code to clean ear tracks

numframes=length(headbase1x);
fprintf('\n%d frames', numframes)

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

goodframes1=find(m1_tailbaseprob>=pthresh); %frames with prob above thresh
if goodframes1(1)~=1 goodframes1=[1; goodframes1];end
if goodframes1(end)~=numframes goodframes1=[goodframes1; numframes];end
[clean_m1_tailbasex, ty]=resample(m1_tailbasex(goodframes1), goodframes1, 1, 'pchip');
[clean_m1_tailbasey, ty]=resample(m1_tailbasey(goodframes1), goodframes1, 1, 'pchip');

goodframes2=find(m2_tailbaseprob>=pthresh); %frames with prob above thresh
if goodframes2(1)~=1 goodframes2=[1; goodframes2];end
if goodframes2(end)~=numframes goodframes2=[goodframes2; numframes];end
[clean_m2_tailbasex, ty]=resample(m2_tailbasex(goodframes2), goodframes2, 1, 'pchip');
[clean_m2_tailbasey, ty]=resample(m2_tailbasey(goodframes2), goodframes2, 1, 'pchip');

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

goodframes=find(m1_Rearprob>=pthresh); %frames with prob above thresh
if goodframes(1)~=1 goodframes=[1; goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes; numframes];end
[clean_m1_Rearx, ty]=resample(m1_Rearx(goodframes), goodframes, 1, 'pchip');
[clean_m1_Reary, ty]=resample(m1_Reary(goodframes), goodframes, 1, 'pchip');

goodframes=find(m1_Learprob>=pthresh); %frames with prob above thresh
if goodframes(1)~=1 goodframes=[1; goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes; numframes];end
[clean_m1_Learx, ty]=resample(m1_Learx(goodframes), goodframes, 1, 'pchip');
[clean_m1_Leary, ty]=resample(m1_Leary(goodframes), goodframes, 1, 'pchip');

%clean up any stray frames added by resampling
clean_m1_tailbasex= clean_m1_tailbasex(1:numframes);
clean_headbase1x=  clean_headbase1x(1:numframes);
clean_nose1x     = clean_nose1x(1:numframes);
clean_m1_tailbasey   =clean_m1_tailbasey(1:numframes);
clean_headbase1y  =clean_headbase1y(1:numframes);
clean_nose1y      =clean_nose1y(1:numframes);
clean_m2_tailbasex   =clean_m2_tailbasex(1:numframes);
clean_headbase2x  =clean_headbase2x(1:numframes);
clean_nose2x      =clean_nose2x(1:numframes);
clean_m2_tailbasey   =clean_m2_tailbasey(1:numframes);
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
    
    if exist('Circ1.mat')
        fprintf('\n found arena Circ1 file, double-check that the points are on the arena wall...\n')
        load Circ1
        arena_radius=Circ.radius;
        arena_center=Circ.center;
        cm_per_px=30/arena_radius;
        tt=0:pi/200:2*pi; %arbitrary length 401 points
        x_wall = arena_center(1) + arena_radius*cos(tt);
        y_wall = arena_center(2) + arena_radius*sin(tt);
    else
        wd=pwd;
        cd ..
        load arena_wall_ellipse.mat
        cd(wd)
        fprintf('\n found arena wall file, double-check that the points are on the arena wall...\n')
    end
    
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
plot(round(x_wall(1:round(.05*length(x_wall)):end)), round(y_wall(1:round(.05*length(x_wall)):end)) ,'co')
title('check if the points are on the arena wall')
drawnow
print -dpsc2 'geometry_plots.ps' -append


%compute rho = distance from arena center
% rho1 - use bodyCOM mouse 1
% rhon1, rhohb1 - same but for nose, headbase (just in case of glitches)
for f=1:length(clean_m1_tailbasex)
    rho1x=clean_m1_tailbasex(f)-arena_center(1);
    rho1y=clean_m1_tailbasey(f)-arena_center(2);
    rho1(f)=cm_per_px*sqrt(rho1x^2 + rho1y^2);
    
    rhon1x=clean_nose1x(f)-arena_center(1);
    rhon1y=clean_nose1y(f)-arena_center(2);
    rhon1(f)=cm_per_px*sqrt(rhon1x^2 + rhon1y^2);
    
    rhohb1x=clean_headbase1x(f)-arena_center(1);
    rhohb1y=clean_headbase1y(f)-arena_center(2);
    rhohb1(f)=cm_per_px*sqrt(rhohb1x^2 + rhohb1y^2);
    
    rho2x=clean_m2_tailbasex(f)-arena_center(1);
    rho2y=clean_m2_tailbasey(f)-arena_center(2);
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
    plot(1:numframes2plot, rho1(frames2plot), '-', rho1_errframes, rho1(rho1_errframes), 'ro')
    plot(1:numframes2plot, rhon1(frames2plot), '-', rhon1_errframes, rhon1(rhon1_errframes), 'go')
    plot(1:numframes2plot, rhohb1(frames2plot), '-', rhohb1_errframes, rhohb1(rhohb1_errframes), 'bo')
    plot(1:numframes2plot, rho2(frames2plot), '-', rho2_errframes, rho2(rho2_errframes), 'ro')
    plot(1:numframes2plot, rhon2(frames2plot), '-', rhon2_errframes, rhon2(rhon2_errframes), 'go')
    plot(1:numframes2plot, rhohb2(frames2plot), '-', rhohb2_errframes, rhohb2(rhohb2_errframes), 'bo')
    ylabel('rho')
    xlim([0 (numframes2plot)]) 
    print -dpsc2 'geometry_plots.ps' -append
    
    %same as above but in the arena
    figure;hold on
    plot(clean_m1_tailbasex(frames2plot), clean_m1_tailbasey(frames2plot), '-', clean_m1_tailbasex(rho1_errframes), clean_m1_tailbasey(rho1_errframes), 'ro')
    plot(clean_nose1x(frames2plot), clean_nose1y(frames2plot), '-', clean_nose1x(rhon1_errframes), clean_nose1y(rhon1_errframes), 'go')
    plot(clean_headbase1x(frames2plot), clean_headbase1y(frames2plot), '-', clean_headbase1x(rhohb1_errframes), clean_headbase1y(rhohb1_errframes), 'bo')
    plot(clean_m2_tailbasex(frames2plot), clean_m2_tailbasey(frames2plot), '-', clean_m2_tailbasex(rho2_errframes), clean_m2_tailbasey(rho2_errframes), 'ro')
    plot(clean_nose2x(frames2plot), clean_nose2y(frames2plot), '-', clean_nose2x(rhon2_errframes), clean_nose2y(rhon2_errframes), 'go')
    plot(clean_headbase2x(frames2plot), clean_headbase2y(frames2plot), '-', clean_headbase2x(rhohb2_errframes), clean_headbase2y(rhohb2_errframes), 'bo')
    print -dpsc2 'geometry_plots.ps' -append
end

%do another round of cleaning using the rho errorframes to resample
goodframes=setdiff(1:numframes, rho1_errframes);
if goodframes(1)~=1 goodframes=[1, goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes, numframes];end
[cleaner_m1_tailbasex, ty]=resample(clean_m1_tailbasex(goodframes), goodframes, 1, 'pchip');
[cleaner_m1_tailbasey, ty]=resample(clean_m1_tailbasey(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rhon1_errframes);
if goodframes(1)~=1 goodframes=[1, goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes(:); numframes];end %changed to ; 9-12-23
[cleaner_nose1x, ty]=resample(clean_nose1x(goodframes), goodframes, 1, 'pchip');
[cleaner_nose1y, ty]=resample(clean_nose1y(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rhohb1_errframes);
if goodframes(1)~=1 goodframes=[1, goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes(:); numframes];end %changed to ; 9-12-23
[cleaner_headbase1x, ty]=resample(clean_headbase1x(goodframes), goodframes, 1, 'pchip');
[cleaner_headbase1y, ty]=resample(clean_headbase1y(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rho2_errframes);
if goodframes(1)~=1 goodframes=[1; goodframes(:)];end %changed to ; 9-12-23
if goodframes(end)~=numframes goodframes=[goodframes(:); numframes];end
[cleaner_m2_tailbasex, ty]=resample(clean_m2_tailbasex(goodframes), goodframes, 1, 'pchip');
[cleaner_m2_tailbasey, ty]=resample(clean_m2_tailbasey(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rhon2_errframes);
if goodframes(1)~=1 goodframes=[1; goodframes(:)];end %changed to ; 9-12-23
if goodframes(end)~=numframes goodframes=[goodframes(:); numframes];end
[cleaner_nose2x, ty]=resample(clean_nose2x(goodframes), goodframes, 1, 'pchip');
[cleaner_nose2y, ty]=resample(clean_nose2y(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rhohb2_errframes);
if goodframes(1)~=1 goodframes=[1; goodframes(:)];end %changed to ; 9-12-23
if goodframes(end)~=numframes goodframes=[goodframes(:); numframes];end %changed to ; 9-12-23       size(goodframes(:)) = 367276    1
[cleaner_headbase2x, ty]=resample(clean_headbase2x(goodframes), goodframes, 1, 'pchip');
[cleaner_headbase2y, ty]=resample(clean_headbase2y(goodframes), goodframes, 1, 'pchip');

goodframes=setdiff(1:numframes, rho1_errframes);
if goodframes(1)~=1 goodframes=[1, goodframes];end
if goodframes(end)~=numframes goodframes=[goodframes, numframes];end
[cleaner_m1_Rearx, ty]=resample(clean_m1_Rearx(goodframes), goodframes, 1, 'pchip');
[cleaner_m1_Reary, ty]=resample(clean_m1_Reary(goodframes), goodframes, 1, 'pchip');
[cleaner_m1_Learx, ty]=resample(clean_m1_Learx(goodframes), goodframes, 1, 'pchip');
[cleaner_m1_Leary, ty]=resample(clean_m1_Leary(goodframes), goodframes, 1, 'pchip');


% recompute rho to see how well we cleaned it up
for f=1:numframes % for f=1:length(cleaner_m1_tailbasex)
    rho1x=cleaner_m1_tailbasex(f)-arena_center(1);
    rho1y=cleaner_m1_tailbasey(f)-arena_center(2);
    rho1(f)=cm_per_px*sqrt(rho1x^2 + rho1y^2);
    
    rho2x=cleaner_m2_tailbasex(f)-arena_center(1);
    rho2y=cleaner_m2_tailbasey(f)-arena_center(2);
    rho2(f)=cm_per_px*sqrt(rho2x^2 + rho2y^2);
end

if plotit
    figure; hold on
    plot(cleaner_m1_tailbasex(frames2plot), cleaner_m1_tailbasey(frames2plot), '-', cleaner_m1_tailbasex(rho1_errframes), cleaner_m1_tailbasey(rho1_errframes), 'ro')
    plot(cleaner_nose1x(frames2plot), cleaner_nose1y(frames2plot), '-', cleaner_nose1x(rhon1_errframes), cleaner_nose1y(rhon1_errframes), 'ro')
    plot(cleaner_headbase1x(frames2plot), cleaner_headbase1y(frames2plot), '-', cleaner_headbase1x(rhohb1_errframes), cleaner_headbase1y(rhohb1_errframes), 'ro')
    plot(cleaner_m2_tailbasex(frames2plot), cleaner_m2_tailbasey(frames2plot), '-', cleaner_m2_tailbasex(rho2_errframes), cleaner_m2_tailbasey(rho2_errframes), 'ro')
    plot(cleaner_nose2x(frames2plot), cleaner_nose2y(frames2plot), '-', cleaner_nose2x(rhon2_errframes), cleaner_nose2y(rhon2_errframes), 'ro')
    plot(cleaner_headbase2x(frames2plot), cleaner_headbase2y(frames2plot), '-', cleaner_headbase2x(rhohb2_errframes), cleaner_headbase2y(rhohb2_errframes), 'ro')
    title('after cleaning impossible frames outside the arena')
    print -dpsc2 'geometry_plots.ps' -append
    
    
    
    figure; hold on
    plot(rho1(frames2plot), '-')
    plot(rho2(frames2plot), '-')
    rho_errframes1=find(rho1>30); %find impossible frames outside the arena
    plot(rho_errframes1, rho1(rho_errframes1), 'ro')
    rho_errframes2=find(rho2>30); %find impossible frames outside the arena
    plot(rho_errframes2, rho2(rho_errframes2), 'go')
        xlim([0 (numframes2plot)]) 
    ylabel('rho after recompute')
    title('recomputed rho after cleaning frames outside the arena')
    print -dpsc2 'geometry_plots.ps' -append
end


mouse1_thigmo=30-rho1;
mouse2_thigmo=30-rho2;



%smooth
%note that smooth using rlowess option works incredibly well, but it is
%extremely slow (5 minutes per trace)
if (0)
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
    smm1_tailbasex=smooth(cleaner_m1_tailbasex, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smm1_tailbasey=smooth(cleaner_m1_tailbasey, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smm2_tailbasex=smooth(cleaner_m2_tailbasex, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    smm2_tailbasey=smooth(cleaner_m2_tailbasey, 'rlowess');
    i=i+1;
    fprintf(repmat('\b',1,nbytes));
    nbytes = fprintf('%d/12', i );
    
    fprintf('\ndone smoothing ')
    toc
else
    fprintf('\nskipping the smoothing step and filtering instead to save time')
    [b,a]=butter(3, .5);
    
    smm1_tailbasex=filtfilt(b,a, cleaner_m1_tailbasex);
    smheadbase1x=filtfilt(b,a,  cleaner_headbase1x);
    smnose1x     =filtfilt(b,a, cleaner_nose1x);
    smm1_tailbasey   =filtfilt(b,a,cleaner_m1_tailbasey);
    smheadbase1y  =filtfilt(b,a,cleaner_headbase1y);
    smnose1y      =filtfilt(b,a,cleaner_nose1y);
    smm2_tailbasex=filtfilt(b,a,cleaner_m2_tailbasex);
    smheadbase2x  =filtfilt(b,a,cleaner_headbase2x);
    smnose2x      =filtfilt(b,a,cleaner_nose2x);
    smm2_tailbasey   =filtfilt(b,a,cleaner_m2_tailbasey);
    smheadbase2y  =filtfilt(b,a,cleaner_headbase2y);
    smnose2y    =filtfilt(b,a,cleaner_nose2y);
    smm1_Rearx    =filtfilt(b,a,cleaner_m1_Rearx);
    smm1_Reary    =filtfilt(b,a,cleaner_m1_Reary);
    smm1_Learx    =filtfilt(b,a,cleaner_m1_Learx);
    smm1_Leary    =filtfilt(b,a,cleaner_m1_Leary);

end


%apparently one of the resampling operations above occasionally introduces a spurious
%extra frame
smm1_tailbasex=smm1_tailbasex(1:numframes);
smm1_tailbasey=smm1_tailbasey(1:numframes);
smm2_tailbasex=smm2_tailbasex(1:numframes);
smm2_tailbasey=smm2_tailbasey(1:numframes);
smnose1x=smnose1x(1:numframes);
smnose1y=smnose1y(1:numframes);
smnose2x=smnose2x(1:numframes);
smnose2y=smnose2y(1:numframes);

%compute abolute bearing as the angle perpendicular to the ears
bearing1=atan2d([smm1_Reary - smm1_Leary], [smm1_Rearx - smm1_Learx]);
m1_bearing=bearing1-90; %perpendicular to ears, in direction mouse is facing
m1_bearing(m1_bearing<-180)=m1_bearing(m1_bearing<-180)+360; %after rotating 90, we have to rewrap to return to the +-180 circle
%see doc atan2d for a diagram of the unit circle. 0° is to the right, 90° is up, 180
%and -180 meet at the left

if plotit
    % plot ear tracks
    frames2plot=1:1000;
    figure
    hold on
    plot(smm1_Rearx(frames2plot), smm1_Reary(frames2plot), 'r.')
    plot(smm1_Learx(frames2plot), smm1_Leary(frames2plot), 'g.')
    plot(smm1_tailbasex(frames2plot), smm1_tailbasey(frames2plot), 'c.')
    plot(smheadbase1x(frames2plot), smheadbase1y(frames2plot), 'k.')
    plot(Sky.madlc.m1_spine1(frames2plot, 1), Sky.madlc.m1_spine1(frames2plot, 2), 'y.')
    plot(Sky.madlc.m1_spine2(frames2plot, 1), Sky.madlc.m1_spine2(frames2plot, 2), 'r.')

    for i=frames2plot
        line([smm1_Learx(i) smm1_Rearx(i)], [smm1_Leary(i) smm1_Reary(i)])
    end
    title('smoothed ear tracks m1')

    figure
    hold on
    cmap=parula(length(frames2plot));
    for i=frames2plot
        L=line([0 (smm1_Rearx(i) - smm1_Learx(i))], [0 (smm1_Reary(i) - smm1_Leary(i))]);
        L.Color=cmap(i,:);
    end
    title('ear to ear')
    colorbar

    figure
    hold on
    cmap=parula(length(frames2plot));
    for i=frames2plot
        L=line([0 (smm1_Rearx(i) - smm1_Learx(i))], [0 (smm1_Reary(i) - smm1_Leary(i))]);
        L.Color=cmap(i,:);
    end
    title('ear to ear')
    colorbar

    figure
    % compute bearing multiple ways and compare
    d=median(sqrt((smm1_Rearx-smm1_Learx).^2 + (smm1_Reary-smm1_Leary).^2)); %dist betw ears, =hypotenuse
    bearing3 = asind((smm1_Reary - smm1_Leary)./d);
    bearing4 = acosd((smm1_Rearx - smm1_Learx)./d);
    plot( t, bearing, t, bearing1, t, bearing3, t, bearing4)
    legend('bearing (atan2d method)', 'ear line (atan2d method)', 'ear line asind method', 'ear line acosd method')
    xlim([0 frames2plot(end)])
    %note that the asind and acosd methods are not 4-quadrant methods, they
    %are only 180° methods, where sin equivocates top/bottom quadrants and
    %cos equivocates left/right quadrants. I also looked at atand, which is
    %also only half the circle, but it's super noisy because tan blows up
    %at +-90
    %after playing around with all of these methods, atand2d is super
    %robust and also correct
    
end




if plotit
    %check the results of cleaning and smoothing
    
    figure
    plot(smm1_tailbasex(frames2plot), smm1_tailbasey(frames2plot), '.')
    hold on
    plot(smm2_tailbasex(frames2plot), smm2_tailbasey(frames2plot), '.')
    title('smoothed data')
    legend('mouse1 COM', 'mouse2 COM')
    set(gca, 'ydir', 'reverse')
    print -dpsc2 'geometry_plots.ps' -append
    
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
    plot(t(frames2plot), smm1_tailbasex(frames2plot),'b',t(frames2plot), smm1_tailbasey(frames2plot), 'm', 'linewi', 2)
    title('mouse 1 smoothed bodyCOM ')
    subplot(212)
    plot(t(frames2plot), smm2_tailbasex(frames2plot),'b',t(frames2plot), smm2_tailbasey(frames2plot), 'm', 'linewi', 2)
    title('mouse 2 smoothed bodyCOM ')
    print -dpsc2 'geometry_plots.ps' -append
    
    figure
    subplot(211)
    plot(t(frames2plot), smheadbase1x(frames2plot),'b',t(frames2plot), smheadbase1y(frames2plot), 'm', 'linewi', 2)
    title('mouse 1 smoothed bodyCOM ')
    subplot(212)
    plot(t(frames2plot), smheadbase2x(frames2plot),'b',t(frames2plot), smheadbase2y(frames2plot), 'm', 'linewi', 2)
    title('mouse 2 smoothed bodyCOM ')
    print -dpsc2 'geometry_plots.ps' -append
    
    
    figure, hold on
    plot(t(frames2plot), headbase1x(frames2plot), t(frames2plot), headbase1y(frames2plot))
    plot(t(errframes1), headbase1x(errframes1), 'ro')
    plot(t(goodframes1), headbase1x(goodframes1), 'go')
    plot(t(frames2plot), headbase1prob(frames2plot)*100)
    plot(t(frames2plot), smheadbase1x(frames2plot),'b',...
        t(frames2plot), smheadbase1y(frames2plot), 'm', 'linewi', 2)
    legend('headbasex','headbasey', 'head errframes', 'head good frames',...
        'mouseprob', 'cleaned & smoothed head x', 'cleaned & smoothed head y')
    title('compare raw vs cleaned/smoothed data')
    xlim([0 t(numframes2plot)]) 
    print -dpsc2 'geometry_plots.ps' -append
    
    figure, hold on
    plot(t(frames2plot), headbase1prob(frames2plot)*100)
    plot(t(frames2plot), smheadbase1x(frames2plot),'b',...
        t(frames2plot), smheadbase1y(frames2plot), 'm', 'linewi', 2)
    legend( 'headbase1prob', 'cleaned & smoothed head x', 'cleaned & smoothed head y')
    print -dpsc2 'geometry_plots.ps' -append
    
    
    
    figure
    plot(headbase1x(frames2plot), headbase1y(frames2plot))
    hold on
    plot(smheadbase1x(frames2plot), smheadbase1y(frames2plot))
    plot(smheadbase2x(frames2plot), smheadbase2y(frames2plot))
    title('cleaned and smoothed data')
    legend('raw headbase', 'cleaned & smoothed headbase', 'cleaned & smoothed cricket')
    set(gca, 'ydir', 'reverse')
    print -dpsc2 'geometry_plots.ps' -append
    
    
    
    
    figure
    plot(t(frames2plot), smnose1x(frames2plot), t(frames2plot), smnose1y(frames2plot),t(frames2plot), smnose2x(frames2plot), t(frames2plot), smnose2y(frames2plot) )
    print -dpsc2 'geometry_plots.ps' -append
    
    figure
    hold on
    p1=plot(smheadbase1x(frames2plot), smheadbase1y(frames2plot), ...
        smm1_tailbasex(frames2plot), smm1_tailbasey(frames2plot), smnose1x(frames2plot), smnose1y(frames2plot));
    p2=plot(smheadbase2x(frames2plot), smheadbase2y(frames2plot), ...
        smm2_tailbasex(frames2plot), smm2_tailbasey(frames2plot), smnose2x(frames2plot), smnose2y(frames2plot));
    text(smheadbase1x(1), smheadbase1y(1), 'mouse1 start')
    text(smheadbase2x(1), smheadbase2y(1), 'mouse2 start')
    title('mouse positions, smoothed')
    set([p1 p2], 'linewi',2)
    set(gca, 'ydir', 'reverse')
    legend('headbase1', 'm1_tailbase', 'nose1', 'headbase2', 'm2_tailbase', 'nose2')
    print -dpsc2 'geometry_plots.ps' -append
    
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
a=sqrt((smm1_tailbasex-smnose1x).^2 + (smm1_tailbasey-smnose1y).^2);
b=sqrt((smm1_tailbasex-smnose2x).^2 + (smm1_tailbasey-smnose2y).^2);
c=sqrt((smnose1x-smnose2x).^2 + (smnose1y-smnose2y).^2);
RelativeAzimuth1=acosd((a.^2+b.^2-c.^2)./(2.*a.*b));

% now for the other mouse
a=sqrt((smm2_tailbasex-smnose2x).^2 + (smm2_tailbasey-smnose2y).^2);
b=sqrt((smm2_tailbasex-smnose1x).^2 + (smm2_tailbasey-smnose1y).^2);
c=sqrt((smnose2x-smnose1x).^2 + (smnose2y-smnose1y).^2);
RelativeAzimuth2=acosd((a.^2+b.^2-c.^2)./(2.*a.*b));




%an alternative is to use the ears, which should be orthogonal to mouse





if plotit
    
    figure
    hold on
    plot(RelativeAzimuth1(frames2plot))
    plot(RelativeAzimuth2(frames2plot))
    xlabel('frames')
    ylabel('azimuth in degrees')
    title(' azimuths')
    print -dpsc2 'geometry_plots.ps' -append
    
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
speed1=sqrt(diff(smm1_tailbasex).^2 + diff(smm1_tailbasey).^2);
speed2=sqrt(diff(smm2_tailbasex).^2 + diff(smm2_tailbasey).^2);
fprintf('\nsmoothing mouse speeds but not too slowly...')
tic
% smspeed1=smooth(speed1, 'rlowess'); %very very slow
smspeed1=smooth(speed1, 'lowess');
toc
smspeed2=smooth(speed2, 'lowess');
toc
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
    h=plot(smm1_tailbasex(1), smm1_tailbasey(1), 'bo', smnose1x(1), smnose1y(1), 'ko', ...
        smheadbase1x(1), smheadbase1y(1), 'ko',...
        smm2_tailbasex(1), smm2_tailbasey(1), 'ro', smnose2x(1), smnose2y(1), 'mo', ...
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
    for f=1:200 %length(smm1_tailbasex)
        waitbar(f/length(smm1_tailbasex), wb);
        set(h(1), 'xdata', smm1_tailbasex(f), 'ydata', smm1_tailbasey(f))
        set(h(2), 'xdata', smnose1x(f), 'ydata', smnose1y(f))
        set(h(3), 'xdata', smheadbase1x(f), 'ydata', smheadbase1y(f))
        set(h(4), 'xdata', smm2_tailbasex(f), 'ydata', smm2_tailbasey(f))
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
    tic
    
    figure
    hold on
    plot(t(frames2plot), speed1(frames2plot))
    plot(t(frames2plot), speed2(frames2plot))
    xlabel('time, s')
    ylabel('speed, px/frame')
    title('mouse speeds vs. time')
    print -dpsc2 'geometry_plots.ps' -append
    
    
    figure
    title('range, azimuth, and speed over time (mismatched units)')
    plot(t(frames2plot), 10*speed1(frames2plot), ...
        t(frames2plot), 10*speed2(frames2plot), ...
        t(frames2plot), range(frames2plot), t(frames2plot),...
        RelativeAzimuth1(frames2plot), t(frames2plot), RelativeAzimuth2(frames2plot)) %careful, these are in different units
    legend('mouse1 speed', 'mouse2 speed', 'range', 'azimuth1', 'azimuth2')
    xlabel('time, s')
    ylabel('speed, px/frame')
    grid on
    line(xlim, [0 0], 'color', 'k')
    th=title({datapath, 'range, azimuth, and speed over time (mismatched units'}, 'interpreter', 'none');
    set(th,'fontsize', 8)
    try
        print -dpsc2 'geometry_plots.ps' -append
    end
    
    figure
    plot(speed1(frames2plot), range(frames2plot), 'k')
    hold on
    
    
    cmap=colormap;
    for j=1:3; cmap2(:,j)=interp(cmap(:,j), ceil(numframes2plot/length(cmap)));end
    cmap2(find(cmap2>1))=1;
    for f=1:numframes2plot-1
        plot(speed1(f), range(1+f), '.', 'color', cmap2(f,:))
    end
    text(speed1(1), range(2), 'start')
    text(speed1(numframes2plot), range(numframes2plot), 'end')
    xlabel('mouse1 speed')
    ylabel('range')
    title('range vs. speed')
    print -dpsc2 'geometry_plots.ps' -append
    
    figure
    h=plot(range(frames2plot), RelativeAzimuth1(frames2plot));
    set(h, 'color', [.7 .7 .7]) %grey
    hold on
    cmap=colormap;
    for j=1:3; cmap2(:,j)=interp(cmap(:,j), ceil(numframes2plot/length(cmap)));end
    cmap2(find(cmap2>1))=1;
    for f=1:numframes2plot
        h=plot(range(f), RelativeAzimuth1(f), '.', 'color', cmap2(f,:));
        set(h, 'markersize', 20)
    end
    text(range(1), RelativeAzimuth1(2), 'start')
    text(range(numframes2plot), RelativeAzimuth1(numframes2plot), 'end')
    xl=xlim;yl=ylim;
    xlim([0 xl(2)]);
    xlabel('range, pixels')
    ylabel('mouse 1 azimuth, degrees')
    title('mouse1  azimuth vs. range')
    print -dpsc2 'geometry_plots.ps' -append
    fprintf('\ndone plotting,')
    toc
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
b=sqrt((smm1_tailbasex-smm2_tailbasex).^2 ...
    + (smm1_tailbasey-smm2_tailbasey).^2);
for f=1:length(smm1_tailbasex)-1
    c(f)=sqrt((smm1_tailbasex(f+1)-smm2_tailbasex(f)).^2 ...
        +(smm1_tailbasey(f+1)-smm2_tailbasey(f)).^2);
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
b=sqrt((smm2_tailbasex-smm1_tailbasex).^2 ...
    + (smm2_tailbasey-smm1_tailbasey).^2);
for f=1:length(smm2_tailbasex)-1
    c(f)=sqrt((smm2_tailbasex(f+1)-smm1_tailbasex(f)).^2 ...
        +(smm2_tailbasey(f+1)-smm2_tailbasex(f)).^2);
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
    'smnose1x', 'smnose1y', ...
    'smm1_tailbasex',  'smheadbase1x', ...
    'smm1_tailbasey',  'smheadbase1y', ...
    'smm2_tailbasex',  'smheadbase2x', 'smnose2x' , ...
    'smm2_tailbasey',  'smheadbase2y', 'smnose2y'   , ...
    'm1_Lear', 'm1_Learx', 'm1_Leary', 'm1_Rear', 'm1_Rearx', 'm1_Reary',  ...
    'm1_Learprob', 'm1_Rearprob', 'm1_bearing',    ...
    'framerate', 'numframes', ...
    'datapath', 'behavior_datafile', 'outfilename', ...
    'mouse1_thigmo', 'mouse2_thigmo', ...
    'rho1', 'rho2', ...
    'mouse1acceleration', 'mouse2acceleration', ...
    'drange', 'dazimuth1','dazimuth2', ...
    'mouse1velocity0',  'mouse1velocity90', ...
    'mouse2velocity0',  'mouse2velocity90', ...
    'cm_per_px', ...
    'generated_on', 'generated_by')
fprintf(' done\n')







