function ConvertHHMMdatasetToObservations(datafilename, outputdir)
%usage: ConvertHHMMdatasetToObservations(datafilename, outputdir)
%
% load data generated by /Users/wehr/Documents/Analysis/myHHMM/read_kip_data.m

load(datafilename) %assume full path


%sessionbyframe=M(:,1);

% X_description generated in read_kip_data.m

%manually selecting certain dB and laser from kip's data

% %for 0-80dB, laser ON-OFF data set
% dBtoinclude=80;
% lasertoinclude='ON';
% sessions2include=[];
% for j=1:length(dB)
%     thislaser=laser{j};
%     thisdB=dB{j};
%     if thisdB==dBtoinclude & contains(thislaser,lasertoinclude)
%         sessions2include=[sessions2include j];
%     end
% end
% fprintf('\nincluding %d dB and laser %s ', dBtoinclude, lasertoinclude)
% condition.sessions2include=sessions2include;
% condition.note=sprintf('including %d dB and laser %s ', dBtoinclude, lasertoinclude)
% condition.dB=dBtoinclude;
% condition.lasertoinclude=lasertoinclude;

%for deaf mouse 1211 data set
dBtoinclude=0;
lasertoinclude='OFF';
sessions2include=[];
for j=1:length(dB)
    thislaser=laser{j};
    thisdB=dB{j};
    if thisdB==dBtoinclude & contains(thislaser,lasertoinclude)
        sessions2include=[sessions2include j];
    end
end
fprintf('\nincluding %d dB and laser %s ', dBtoinclude, lasertoinclude)
condition.sessions2include=sessions2include;
condition.note=sprintf('deaf mouse 1211, %d dB, laser %s ', dBtoinclude, lasertoinclude)
condition.dB=dBtoinclude;
condition.lasertoinclude=lasertoinclude;


X=[];
datadirs_by_frame={};
localframenum=[];
for i=sessions2include
    startidx=size(X,1)+1;
    X=[X; data{i}'];
    nframes=length(data{i});
    datadirs_by_frame(startidx:startidx-1+nframes)=repmat(moviedirs(i), 1, nframes);
    localframenum(startidx:startidx-1+nframes)=1:nframes;
    Land(startidx:startidx-1+nframes)=repmat(indices{i}(1), 1, nframes);
end
fprintf('\nusing %d sessions ', length(sessions2include))
fprintf('%d ', sessions2include)
fprintf('\n')
fprintf('\ndata is %d frames by %d observations', size(X, 1), size(X, 2))

% ssm wants it frames x obs, whereas hhmm wants in obs x frames

%data is already normalized in read_kip_data
%I should z-score it instead!

% %normalize X
% rawX=X; %non-normalized
% for j=1: size(rawX, 2)
%     X(:,j)=rawX(:,j)./max(abs(rawX(:,j))); %normalize
% end
% 
% framerate=200; %hard coded, where is framerate stored so we can read it instead?

%try downsampling to about 30Hz
decimate_factor=round(framerate/40);
fprintf('\nthere are %d nans in this dataset', length(find(isnan(X))))
for i=1:size(X, 2)
    %     if there are nans on the first or last frame, try this
    %     replace nans on last frame of diffed variables with frame n-1
    try
        X(find(isnan(X(:,i))), i)=X(find(isnan(X(:,i)))-1, i);
    catch %if there's nans on the first frame we do this instead
        X(find(isnan(X(:,i))), i)=X(find(isnan(X(:,i)))+1, i);
    end
    %are there still nans?
    if any(isnan(X(:,i)))
        fprintf('\nremoving nans by interpolation')
        %if there are segments of missing data, we have to interpolate
        t=1:length(X(:,i));
        mask =  ~isnan(X(:,i));
        nseq=X(:,i);
        nseq(~mask) = interp1(t(mask), X(mask,i), t(~mask));
        X(:,i)=nseq;
    end

    decX(:,i)=decimate(X(:,i), decimate_factor);
end
undecX=X;
X=decX;
fprintf('\ndecimated observations by %dx', decimate_factor)

cd(outputdir)
run_on=sprintf('generated by %s on %s', mfilename, datestr(now));
generated_by=mfilename;
save training_data X  X_description run_on framerate  ...
    outputdir  condition  datadirs_by_frame localframenum ...
    decX decimate_factor undecX framerate datafilename Land
fprintf('\nsaved observations to file training_data.mat in %s\n', outputdir)

