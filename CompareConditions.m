function CompareConditions(DirList, dirlistpath, outputdir)
%usage: CompareConditions(DirList, dirlistpath, outputdir)
% compares HMM output across different conditions as specified in the
% dirlist to specify conditions, edit the DirList (created by
% DirListBuilder) to include a line with the keyword "condition" following
% the dir line, and then a line with the condition following that. If you
% have multiple conditions (e.g. noise level and laser), just concatenate
% them (see example below). Use a blank line in between data directories.
% 
%
% example:
%
% datadir
% D:\lab\djmaus\Data\Kip\2021-05-12_9-44-23_mouse-0058
% condition
% 20 dB laser on
%
% datadir
% D:\lab\djmaus\Data\Kip\2021-05-12_9-54-32_mouse-0058
% condition
% 60 dB laser off

if nargin==0,
    outputdir=pwd;
    [DirList, dirlistpath] = uigetfile('*.txt', 'select DirList of data directories to scan');
    if isequal(DirList,0) || isequal(dirlistpath,0)
        fprintf('\ncancelled')
        return
    end
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
        if isempty(datadir) error('unexpected format of datadirs or conditions in dirlist'); end
        i=i+1;
        datadirs{i}=datadir;
        
        %check for any included conditions
        line=fgetl(fid);
        if strcmp(line, 'condition')
            %read conditions until you get a blank line
            cond=fgetl(fid);
            conds{i}=cond;
            if strcmp(line, 'datadir') ...
                    strcmp(cond, 'datadir') | strcmp(cond, 'condition')
                help(mfilename)
                error('unexpected format of datadirs or conditions in dirlist')
                %there's some minimal checking here for malformed entries, but
                %it's not exhaustive... pretty much assuming the entries
                %are
            elseif strcmp(line, 'datadir')
                error('unexpected format of datadirs or conditions in dirlist')
            elseif isempty(line)
                conds{i}='';
            end
            fprintf('\n%d %s, %s',i, datadirs{i}, conds{i})
            
        end
    end
end
numtrials=i;

% sanity checking
if length(datadirs) ~= length(conds)
    error ('length(datadirs) ~= length(conditions)')
end

conditions=unique(conds);
numconditions = length(conditions);
fprintf('\n\n%d trials', numtrials)
fprintf('\n%d conditions: ', numconditions)
fprintf('%s, ', conditions{:})
fprintf('\b\b\n')

cd(outputdir)
load pruned_tpm
load training_data.mat

%let's start simple: just count number of epochs for each state, in the
%different conditions
nepochs=zeros(numconditions, pruned_num_states); %preallocate
numframes_by_condition=zeros(numconditions, 1);
numtrials_by_condition=zeros(numconditions, 1);

for cindex=1:numconditions
    for trial=1:numtrials
        if strcmp(conds(trial), conditions{cindex})
            %this is a trial with the condition of interest
            numframes_by_condition(cindex)=numframes_by_condition(cindex)+groupdata(trial).numframes;
            numtrials_by_condition(cindex)=numtrials_by_condition(cindex)+1;
            for k=1:pruned_num_states
                for e=1:pruned_epochs(k).num_epochs
                    %is e in this trial?
                    start=pruned_epochs(k).starts(e);
                    if strcmp(datadirs_by_frame{start}, macifypath(datadirs{trial}))
                        nepochs(cindex, k)=nepochs(cindex, k)+1;
                    end
                end
            end
        end
    end
end
% sanity check
if    sum(nepochs(:)) ~= sum(pruned_num_epochs)
    error('sanity check failure on num epochs')
end

figure
plot(nepochs')
xlabel('state')
ylabel('num epochs')
legend(conditions)

figure
plot((nepochs./numframes_by_condition)')
xlabel('state')
ylabel('normed num epochs')
title('normalized by framecount')
legend(conditions)



for cindex=1:numconditions
    fprintf('\n%s: %d total epochs, %d frames, %d trials', conditions{cindex}, sum(nepochs(cindex,:)), numframes_by_condition(cindex), numtrials_by_condition(cindex))
end

%keyboard









