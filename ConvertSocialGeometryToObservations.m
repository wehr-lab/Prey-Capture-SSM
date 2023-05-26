function ConvertSocialGeometryToObservations(DirList, dirlistpath, outputdir)
%usage: ConvertGeometryToObservations(DirList, outputdir)
% generate Observations data from DLC geometry, formatted for input to SSM
% redesigned Feb 2021 for the new camera data (replaces ConvertTracksToObservations)
% uses a DirList to load geometry outfiles from data directories
% concatenates some variables into a single matrix, and
% then saves as a mat file
% Expects a DirList created by DirListBuilder

X=[];
% groupdata=[];
if nargin==0,
    [DirList, dirlistpath] = uigetfile('*.txt', 'select DirList of data directories to scan');
    if isequal(DirList,0) || isequal(dirlistpath,0)
        fprintf('\ncancelled')
        return
    end
    outputdir=dirlistpath;
end
cd(dirlistpath)
fprintf('opening dirlist %s', DirList)
fid=fopen(DirList);
i=0;
while 1 %processes until end of file is reached, then breaks
    line=fgetl(fid);
    if  ~ischar(line), break, end %break at end of file
    while isempty(line)
        line=fgetl(fid);
    end
    if strcmp(line, 'datadir')
        datadir=fgetl(fid);
        i=i+1;
        
        datadirs{i}=datadir;
        fprintf('\n%s', datadir)
        % adjust filenames to work on a mac
        if ismac datadir=macifypath(datadir);end
        cd(datadir)
        d=dir('geometry-*.mat');
        if isempty (d) %set to 1 to force re-process geometry
            ConvertSocialDLCtoGeometry(datadir)
            d=dir('geometry-*.mat');
        end
        geo_file=d(1).name;
        geo=load(geo_file);
        groupdata(i)=geo;
        numframes=geo.numframes;
        %mouse speed
        if length(geo.speed1)<numframes
            tmp=zeros(numframes,1);
            tmp(1:length(geo.speed1))=geo.speed1;
            geo.speed1=tmp;
        elseif length(geo.speed1)>numframes
            geo.speed1=geo.speed1(1:numframes);
        end
          if length(geo.speed2)<numframes
            tmp=zeros(numframes,1);
            tmp(1:length(geo.speed2))=geo.speed2;
            geo.speed2=tmp;
        elseif length(geo.speed2)>numframes
            geo.speed2=geo.speed2(1:numframes);
        end
        startidx=size(X,1)+1;
        X(startidx:startidx-1+numframes, 1)= geo.speed1;
        X(startidx:startidx-1+numframes, 2)= geo.speed2;
        X(startidx:startidx-1+numframes, 3)= geo.range;
        X(startidx:startidx-1+numframes, 4)= geo.drange;
        X(startidx:startidx-1+numframes, 5)= (atanh(sind(geo.RelativeAzimuth1))).^(1/3); %Az is 0-180, same for left/right (9:00=3:00=90°)
        %cos is in [-1, 1], so atanh(cosd(az)) is a zero-mean gaussian, which is good for HMM fitting
        %but sin is [0, 1] because az is non-negative the way I computed it (see
        %ConvertSocialDLCtoGeometry), there is no distinction between left/right, only towards/away,
        %so atanh(sind(az)) is only the positive tail of the gaussian. To
        %gaussianize I take the cube root, i.e. the Wilson-Hilferty transformation
        %(https://www.rasch.org/rmt/rmt162g.htm) also (https://stats.stackexchange.com/questions/86135/is-it-possible-to-convert-a-rayleigh-distribution-into-a-gaussian-distribution)
        %which I confirmed gaussianizes very nicely
        X(startidx:startidx-1+numframes, 6)= atanh(cosd(geo.RelativeAzimuth1)); %Az is 0-180
        X(startidx:startidx-1+numframes, 7)= (atanh(sind(geo.RelativeAzimuth2))).^(1/3);
        X(startidx:startidx-1+numframes, 8)= atanh(cosd(geo.RelativeAzimuth2));
        X(startidx:startidx-1+numframes, 9)= geo.mouse1velocity0;
        X(startidx:startidx-1+numframes, 10)= geo.mouse1velocity90;
        X(startidx:startidx-1+numframes, 11)= geo.mouse2velocity0;
        X(startidx:startidx-1+numframes, 12)= geo.mouse2velocity90;
        X(startidx:startidx-1+numframes, 13)= geo.mouse1_thigmo;
        X(startidx:startidx-1+numframes, 14)= geo.mouse2_thigmo;
        localframenum(startidx:startidx-1+numframes)=1:numframes;
        for k=startidx:startidx-1+numframes %kind of clunky, is it worth it?
            datadirs_by_frame{k}=datadir;
        end

        tracks(startidx:startidx-1+numframes, 1)= geo.smbodyCOM1x;
        tracks(startidx:startidx-1+numframes, 2)= geo.smbodyCOM1y;
        tracks(startidx:startidx-1+numframes, 3)= geo.smbodyCOM2x;
        tracks(startidx:startidx-1+numframes, 4)= geo.smbodyCOM2y;
        tracks(startidx:startidx-1+numframes, 5)= geo.smheadbase1x;
        tracks(startidx:startidx-1+numframes, 6)= geo.smheadbase1y;
        tracks(startidx:startidx-1+numframes, 7)= geo.smheadbase2x;
        tracks(startidx:startidx-1+numframes, 8)= geo.smheadbase2y;
        tracks(startidx:startidx-1+numframes, 9)= geo.smnose1x;
        tracks(startidx:startidx-1+numframes, 10)= geo.smnose1y;
        tracks(startidx:startidx-1+numframes, 11)= geo.smnose2x;
        tracks(startidx:startidx-1+numframes, 12)= geo.smnose2y;

        
    end
end



X_description{1}='mouse1speed';
X_description{2}='mouse2speed';
X_description{3}='range';
X_description{4}='drange';
X_description{5}='sinRelativeAzimuth1';
X_description{6}='cosRelativeAzimuth1';
X_description{7}='sinRelativeAzimuth2';
X_description{8}='cosRelativeAzimuth2';
X_description{9}='mouse1velocity0';
X_description{10}='mouse1velocity90';
X_description{11}='mouse2velocity0';
X_description{12}='mouse2velocity90';
X_description{13}='mouse1_thigmo';
X_description{14}='mouse2_thigmo';

X=real(X);

        tracks_description{1}='smbodyCOM1x';
        tracks_description{2}='smbodyCOM1y';
        tracks_description{3}='smbodyCOM2x';
        tracks_description{4}='smbodyCOM2y';
        tracks_description{5}='smheadbase1x';
        tracks_description{6}='smheadbase1y';
        tracks_description{7}='smheadbase2x';
        tracks_description{8}='smheadbase2y';
        tracks_description{9}='smnose1x';
        tracks_description{10}='smnose1y';
        tracks_description{11}='smnose2x';
        tracks_description{12}='smnose2y';

%normalize by z-score
rawX=X;
mu = nanmean(X);
sigma = nanstd(X);
sigma0 = sigma;
sigma0(sigma0==0) = 1;
X = (X-mu) ./ sigma0;

if sum(isnan(X(:)))> 10%length(X)
    error('nans during zscore')
end



%try downsampling to about 30Hz
decimate_factor=round(geo.framerate/40);
for i=1:size(X, 2)
    decX(:,i)=decimate(X(:,i), decimate_factor);
end
undecX=X;
X=decX;
fprintf('\ndecimated observations by %dx', decimate_factor)

cd(outputdir)
run_on=sprintf('generated by %s on %s', mfilename, datestr(now));
generated_by=mfilename;
framerate=geo.framerate;
save training_data X rawX X_description run_on DirList datadirs ...
    groupdata outputdir localframenum datadirs_by_frame ...
    decX decimate_factor undecX framerate tracks tracks_description
fprintf('\nsaved observations to file training_data.mat in %s', outputdir)

