% script to check if the directories in DirList have been processed yet

DirList=    'processedvids_ephys.txt';
dirlistpath=    '/Volumes/wehrrig4.uoregon.edu/lab/djmaus/Data/Molly/';

no_vid_count=0;


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
        fprintf('\n%d %s', i, datadir)
        % adjust filenames to work on a mac
        if ismac datadir=macifypath(datadir);end
        
        cd(datadir)
        d=dir('geometry-*.mat');
        if isempty (d)
            d2=dir('Behavior_mouse-*.mat');
            if length(d2)==0
                fprintf('\nno Behavior_mouse file in this directory')
                ProcessCams
            elseif length(d2)>1
                error('more than one behavior datafile');
            else
                fprintf('\n\t found file %s ', d2(1).name)
            end
            ConvertDLCtoGeometry(datadir)
            
        else
            fprintf('\n\t found file %s ', d(1).name)
        end
        d=dir('Assimilation.mat');
        if ~isempty (d)
            fprintf('\n\t found assimilation file %s ', d.name)
        else
            myWorkflow
        end
        
        
        d=dir('*labeled.mp4');
        if isempty (d)
            no_vid_count=no_vid_count+1;
            fprintf('\n\tno labeled video')
        else
            fprintf('\n\tfound labeled video %s',d(1).name);
        end
    end
end

fprintf('\n\n%d dirs with no labeled video', no_vid_count)


