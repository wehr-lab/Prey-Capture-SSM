function PlotStatePSTH(outputdir)
%Usage: PlotStatePSTH(outputdir)
%
% align spiking data to state and epoch boundaries
% uses pruned_tpm.mat generated by PruneTPM

%hmm this should be for a cell, or repeated for simultaneously recorded
%cells. But the hmm is run on an entire dirlist, which has many independent recordings
% I guess we could start with one cell and then repeat for the whole dirlist
% maybe we should save the state-epoch boundaries in the datadir?

%if nargin==0 fprintf('no input\nUsage: PlotStatePSTH(outputdir)\n');return;end

if nargin==0
    close all
    outputdir='/Volumes/Lennon/Documents/Analysis/PreyCapture data/state_epoch_clips-02-Mar-2021'
end

cd (outputdir)
outpsfilename='state-psths.ps';
delete(outpsfilename)
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
    fprintf('\ndir %d/%d', i, length(datadirs))
    if ismember(i, [61 62 63 64 65 66  ]) %messed up data
        %keyboard
    else
        
        % localframenum comes from ConvertGeometryToObservations and
        % already accounts for trimming from cricket drop frame to catch
        % frame
        
        if get(gcf, 'Number')>20 keyboard;end
        
        cricketdropframe=groupdata(i).cricketdropframe;
        catchframe=groupdata(i).catchframe;
        if catchframe>groupdata(i).numframes
            %rare case where catch=last frame and there's an off-by-one error
            catchframe=groupdata(i).numframes;
        end
        %the geometry variables run from cricketdropframe to catchframe
        
        %plot some geometry for this recording
        t=1:length(groupdata(i).range);
        t=t/groupdata(i).framerate;
        fig1=figure;
        [~,dirname]=fileparts(datadirs{i});
        title(dirname);
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
        legend('range', 'speed', 'azimuth', 'thigmo', 'Z','AutoUpdate','off')
        
        %get spiketimes and alignment
        datadir=datadirs{i};
        if ismac datadir=macifypath(datadir);end
        cd(datadir)
        [vids,units,chans] = AssimilateSignals(cricketdropframe, catchframe);
        
        %plot rasters aligned to the geometry variables
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
        xlim([0 t(catchframe)])
        
        %plot states/epochs as shaded boxes
       % figure('pos', [430   923   560   420])
       % hold on
        kcolors=jet(pruned_num_states);
        yl=[0 1];
        for k=1:pruned_num_states
            %find epoch starts within this trial
            epoch_start_idx=find(pruned_epochs(k).starts>cumstartframes(i) & ...
                pruned_epochs(k).starts<cumstopframes(i));
            epoch_starts=pruned_epochs(k).starts(epoch_start_idx);
            %find epoch stops within this trial
            epoch_stop_idx=find(pruned_epochs(k).stops>cumstartframes(i) & ...
                pruned_epochs(k).stops<=cumstopframes(i));
            epoch_stops=pruned_epochs(k).stops(epoch_stop_idx);
            
            for e=1:length(epoch_starts)
                c=kcolors(k,:);
                Xidx=[epoch_starts(e), epoch_starts(e), epoch_stops(e), epoch_stops(e)];
                Xidx=Xidx-cumstartframes(i); % convert to local frames
                X=t(Xidx); %convert to local time in seconds (to match spiketimes)
                Y=[0 numunits numunits 0];
                jb=fill(X, Y, c, 'facealpha', .5, 'edgecolor', 'none');
            end
%             %plot rasters aligned to the shaded state epochs
%             cmap=jet(numunits);
%             offset=0;
%             for u=1:numunits
%                 offset=offset+1;
%                 start=units(1).start;
%                 stop=units(1).stop;
%                 spiketimes=units(u).spiketimes;
%                 spiketimes=spiketimes-start; %align to cricketdrop
%                 plot(spiketimes, zeros(size(spiketimes))+offset, '.', 'markersize', 20, 'color', cmap(u,:))
%             end
        end
        
        %plot epoch-aligned rasters and firing rates
        cmap=jet(numunits);
        fig2=figure('pos', [1570 144  924  1201]);
        title(dirname);
        
        subplot1(pruned_num_states, 1)
        for k=1:pruned_num_states
            subplot1(k)
            hold on
                    offset=0;
            %find epoch starts within this trial
            epoch_start_idx=find(pruned_epochs(k).starts>cumstartframes(i) & ...
                pruned_epochs(k).starts<cumstopframes(i));
            epoch_starts=pruned_epochs(k).starts(epoch_start_idx);
            if length(epoch_starts)>0
                ylabel(sprintf('state %d\n%d epochs', k,length(epoch_starts) ))
                
                    
                    for u=1:numunits
                        start=units(1).start;
                        stop=units(1).stop;
                        spiketimes=units(u).spiketimes;
                        spiketimes=spiketimes-start; %align to cricketdrop
                        allst=[];
                        for e=1:length(epoch_starts)
                            offset=offset+1;
                            Xidx=epoch_starts(e);
                            Xidx=Xidx-cumstartframes(i); % convert to local frames
                            X=t(Xidx); %convert to local time in seconds (to match spiketimes)
                            st=spiketimes(find(spiketimes>X-.100 & spiketimes<X+.500)); %extract spikes in a window around epoch start
                            st=st-X; %align to epoch start time
                            plot(st, zeros(size(st))+offset, '.', 'markersize', 20, 'color', cmap(u,:))
                            allst=[allst st];
                        end
                        if ~isempty(allst)
                            
                            %psth=conv(allst, gaussian(100, .25));
                            [n,x]=hist(allst, [-.5:.01:.5]);
                            plot(x, smooth(n)+offset-e, 'color', cmap(u,:))
                            
                        end
                        line([0 0], ylim)
                        if length(epoch_starts)>5
                            %  keyboard
                        end
                    end
                    
            end
            xlim([-.1 .5])
            
        end
        
    end
    
    cd(outputdir)
    try
        figure(fig1);
        print(outpsfilename, '-dpsc2', '-append', '-bestfit')
        close
        figure(fig2);
        orient tall
        print(outpsfilename, '-dpsc2', '-append', '-bestfit')
        close
    end
end

















