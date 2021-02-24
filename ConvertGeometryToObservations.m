function ConvertGeometryToObservations(DirList, dirlistpath, outputdir)
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
        if ismac
            datadir= strrep(datadir, '\', '/');
            datadir= strrep(datadir, 'D:', '/Volumes/wehrrig4.uoregon.edu');
        end
        cd(datadir)
        d=dir('geometry-*.mat');
        if isempty (d)
            ConvertDLCtoGeometry(datadir)
            d=dir('geometry-*.mat');
        end
        geo_file=d(1).name;
        geo=load(geo_file);
        groupdata(i)=geo;
        numframes=geo.numframes;
        startidx=size(X,1)+1;
        X(startidx:startidx-1+numframes, 1)= geo.speed;
        X(startidx:startidx-1+numframes, 2)= geo.cspeed;
        X(startidx:startidx-1+numframes, 3)= geo.range;
        X(startidx:startidx-1+numframes, 4)= geo.RelativeAzimuth;
        X(startidx:startidx-1+numframes, 5)= geo.mousevelocity0;
        X(startidx:startidx-1+numframes, 6)= geo.mousevelocity90;
        X(startidx:startidx-1+numframes, 7)= geo.cricketvelocity0;
        X(startidx:startidx-1+numframes, 8)= geo.cricketvelocity90;
        X(startidx:startidx-1+numframes, 9)= geo.drange;
        X(startidx:startidx-1+numframes, 10)= geo.dazimuth;
        X(startidx:startidx-1+numframes, 11)= geo.mouseacceleration;
        X(startidx:startidx-1+numframes, 12)= geo.cricketacceleration;
        X(startidx:startidx-1+numframes, 13)= geo.cricket_thigmo_distance;
        X(startidx:startidx-1+numframes, 14)= geo.mouse_thigmo_distance;
        localframenum(startidx:startidx-1+numframes)=geo.cricketdropframe+1:geo.cricketdropframe+numframes;
        for k=startidx:startidx-1+numframes %kind of clunky, is it worth it?
            datadirs_by_frame{k}=datadir;
        end
        
        %         X(startidx:startidx-1+length(groupdata(i).cricketspeed(region(1:end-1))), 2)= groupdata(i).cricketspeed(region(1:end-1));
        %         X(startidx:startidx-1+length(groupdata(i).range(region)), 3)= groupdata(i).range(region);
        %         X(startidx:startidx-1+length(groupdata(i).azimuth(region)), 4)= groupdata(i).azimuth(region);
        %         X(startidx:startidx-1+length(groupdata(i).mousevelocity0(region(1:end-1))), 5)= groupdata(i).mousevelocity0(region(1:end-1));
        %         X(startidx:startidx-1+length(groupdata(i).mousevelocity90(region(1:end-1))), 6)= groupdata(i).mousevelocity90(region(1:end-1));
        %         X(startidx:startidx-1+length(groupdata(i).cricketvelocity0(region(1:end-1))), 7)= groupdata(i).cricketvelocity0(region(1:end-1));
        %         X(startidx:startidx-1+length(groupdata(i).cricketvelocity90(region(1:end-1))), 8)= groupdata(i).cricketvelocity90(region(1:end-1));
        %         X(startidx:startidx-1+length(groupdata(i).drange(region(1:end-1))), 9)= groupdata(i).drange(region(1:end-1));
        %         X(startidx:startidx-1+length(groupdata(i).dazimuth(region(1:end-1))), 10)= groupdata(i).dazimuth(region(1:end-1));
        %         X(startidx:startidx-1+length(groupdata(i).mouseacceleration(region(1:end-2))), 11)= groupdata(i).mouseacceleration(region(1:end-2));
        %         X(startidx:startidx-1+length(groupdata(i).cricketacceleration(region(1:end-2))), 12)= groupdata(i).cricketacceleration(region(1:end-2));
        %         X(startidx:startidx-1+length(groupdata(i).cricket_thigmo_distance(region)), 13)= groupdata(i).cricket_thigmo_distance(region);
        %         X(startidx:startidx-1+length(groupdata(i).mouse_thigmo_distance(region)), 14)= groupdata(i).mouse_thigmo_distance(region);
        %         drug(startidx:startidx-1+length(groupdata(i).range(region)))=1;
    end
end



X_description{1}='mousespeed';
X_description{2}='cricketspeed';
X_description{3}='range';
X_description{4}='azimuth';
X_description{5}='mousevelocity0';
X_description{6}='mousevelocity90';
X_description{7}='cricketvelocity0';
X_description{8}='cricketvelocity90';
X_description{9}='drange/dt';
X_description{10}='dazimuth/dt';
X_description{11}='mouseacceleration';
X_description{12}='cricketacceleration';
X_description{13}='cricket_distance_from_wall';
X_description{14}='mouse_distance_from_wall';


X=real(X);

%normalize X
rawX=X; %non-normalized
for j=1: size(rawX, 2)
    X(:,j)=rawX(:,j)./max(abs(rawX(:,j))); %normalize
end

cd(outputdir)
run_on=sprintf('generated by %s on %s', mfilename, datestr(now));
generated_by=mfilename;
save training_data X rawX X_description run_on DirList datadirs groupdata outputdir localframenum datadirs_by_frame
fprintf('\nsaved observations to file training_data.mat in %s', outputdir)
