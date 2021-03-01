function PlotStatePSTH(outputdir)
%Usage: PlotStatePSTH(outputdir)
%
% align spiking data to state and epoch boundaries
% uses pruned_tpm.mat generated by PruneTPM

%hmm this should be for a cell, or repeated for simultaneously recorded
%cells. But the hmm is run on an entire dirlist, which has many independent recordings
% I guess we could start with one cell and then repeat for the whole dirlist
% maybe we should save the state-epoch boundaries in the datadir?

cd (outputdir)
load('pruned_tpm.mat')
load('training_data.mat')


cumstartframe=1;
for i=1:length(datadirs);
    numframes=groupdata(i).numframes;
    cumstartframes(i)=cumstartframe;
    cumstopframes(i)=cumstartframe+numframes-1;
    cumstartframe=cumstartframe+numframes;
end

for i=1:length(datadirs);
    % localframenum comes from ConvertGeometryToObservations and
    % already accounts for trimming from cricket drop frame to catch
    % frame
    
    cricketdropframe=groupdata(i).cricketdropframe;
    catchframe=groupdata(i).catchframe;
    %the geometry variables run from cricketdropframe to catchframe
    
    %plot some geometry for this recording
    t=1:length(groupdata(i).range);
    t=t/groupdata(i).framerate;
    figure
    hold on
    range=groupdata(i).range;
    nrange=range/max(abs(range));
    speed=groupdata(i).speed;
    nspeed=speed/max(abs(speed));
    RelativeAzimuth=groupdata(i).RelativeAzimuth;
    nRelativeAzimuth=RelativeAzimuth/max(abs(RelativeAzimuth));
    mouse_thigmo_distance=groupdata(i).mouse_thigmo_distance;
    nmouse_thigmo_distance=mouse_thigmo_distance/max(abs(mouse_thigmo_distance));
    plot(t, nrange)
    plot(t, nspeed)
    plot(t, nRelativeAzimuth)
    plot(t, nmouse_thigmo_distance)
    numframes=length(t);
    localZ=Z(cumstartframes(i):cumstopframes(i));
    plot( t, 1+.25*localZ/num_states)
    legend('range', 'speed', 'azimuth', 'thigmo', 'Z')
    
    %get spiketimes and alignment
    datadir=datadirs{i};
    if ismac datadir=macifypath(datadir);end
    cd(datadir)
    [vids,units,chans] = AssimilateSignals(cricketdropframe, catchframe);
    
    %plot rasters
    numunits=length(units);
    cmap=jet(numunits);
    offset=0;
    for u=1:numunits
        offset=offset+1;
        start=units(1).start;
        stop=units(1).stop;
        spiketimes=units(u).spiketimes;
        spiketimes=spiketimes-start; %align to cricketdrop
        plot(spiketimes, zeros(size(spiketimes))+offset, '.', 'markersize', 20, 'color', cmap(u,:))
    end
    
    %plot states/epochs
    figure('pos', [430   923   560   420])
    hold on
    colors=jet(pruned_num_states);
    ylim=[0 1];
    yl=ylim;
    for k=1:pruned_num_states
        %find epoch starts within this trial
        epoch_start_idx=find(pruned_epochs(k).starts>cumstartframes(i) & ...
            pruned_epochs(k).starts<cumstopframes(i));
        epoch_starts=pruned_epochs(k).starts(epoch_start_idx);
        %find epoch stops within this trial
        epoch_stop_idx=find(pruned_epochs(k).stops>cumstartframes(i) & ...
            pruned_epochs(k).stops<cumstopframes(i));
        epoch_stops=pruned_epochs(k).stops(epoch_stop_idx);
        
        
        for e=1:length(epoch_starts)
            c=colors(k,:);
            Xidx=[epoch_starts(e), epoch_starts(e), epoch_stops(e), epoch_stops(e)];
            Xidx=Xidx-cumstartframes(i); % convert to local frames
            X=t(Xidx); %convert to local time in seconds (to match spiketimes)
            Y=[0 numunits numunits 0];
            jb=fill(X, Y, c, 'facealpha', .1, 'edgecolor', 'none');
            % jbfill(x,0*x+yl(1),0*x+yl(2),c,c,1,.1);
        end
        %plot rasters
        cmap=jet(numunits);
        offset=0;
        for u=1:numunits
            offset=offset+1;
            start=units(1).start;
            stop=units(1).stop;
            spiketimes=units(u).spiketimes;
            spiketimes=spiketimes-start; %align to cricketdrop
            plot(spiketimes, zeros(size(spiketimes))+offset, '.', 'markersize', 20, 'color', cmap(u,:))
        end
    end
    
    
    
%     keyboard
    
    
    
end


















