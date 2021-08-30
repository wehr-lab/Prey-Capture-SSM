function PlotGeoPSTH(outputdir)
%Usage: PlotGeoPSTH(outputdir)
%
% align spiking data to geometry  variables
% uses pruned_tpm.mat generated by PruneTPM


%if nargin==0 fprintf('no input\nUsage: PlotStatePSTH(outputdir)\n');return;end

if nargin==0
    close all
    outputdir=pwd;
end

fprintf('%s', outputdir)
cd (outputdir)
outpsfilename='geo-psths.ps';
delete(outpsfilename)
load('pruned_tpm.mat')
td=load('training_data.mat');


cumstartframe=1;
for i=1:length(td.datadirs);
    numframes=td.groupdata(i).numframes;
    cumstartframes(i)=cumstartframe;
    cumstopframes(i)=cumstartframe+numframes-1;
    cumstartframe=cumstartframe+numframes;
end


for i=1:length(td.datadirs);
    if ismember(i, [61 62 63 64 65 66  ]) %messed up data
        %keyboard
    else
        
        % localframenum comes from ConvertGeometryToObservations and
        % already accounts for trimming from cricket drop frame to catch
        % frame
        
        if get(gcf, 'Number')>20 keyboard;end
        
        cricketdropframe=td.groupdata(i).cricketdropframe;
        catchframe=td.groupdata(i).catchframe;
        if catchframe>td.groupdata(i).numframes
            %rare case where catch=last frame and there's an off-by-one error
            catchframe=td.groupdata(i).numframes;
        end
        %the geometry variables run from cricketdropframe to catchframe
        
        %plot some geometry for this recording
        t=1:length(td.groupdata(i).range);
        t=t/td.groupdata(i).framerate;
        
        fig1=figure;
        [~,dirname]=fileparts(td.datadirs{i});
        title(dirname);
        hold on
        range=td.groupdata(i).range;
        nrange=range/max(abs(range));
        speed=td.groupdata(i).speed;
        nspeed=speed/max(abs(speed));
        cspeed=td.groupdata(i).cspeed;
        ncspeed=cspeed/max(abs(cspeed));
        RelativeAzimuth=td.groupdata(i).RelativeAzimuth;
        nRelativeAzimuth=RelativeAzimuth/max(abs(RelativeAzimuth));
        mouse_thigmo_distance=td.groupdata(i).mouse_thigmo_distance;
        nmouse_thigmo_distance=mouse_thigmo_distance/max(abs(mouse_thigmo_distance));
        plot(t, nrange, 'linew', 2)
        plot(t, nspeed, 'linew', 2)
        plot(t, ncspeed, 'linew', 2)
        plot(t, nRelativeAzimuth, 'linew', 2)
        plot(t, nmouse_thigmo_distance, 'linew', 2)
        numframes=length(t);
        localZ=Zundec(cumstartframes(i):cumstopframes(i));
        plot( t, 1+.25*double(localZ)/num_states)
        legend('range', 'mouse speed', 'cricket speed', 'azimuth', 'thigmo', 'Z',...
            'AutoUpdate','off', 'location',  'eastoutside')
        xlabel('time, s')
        
        %get spiketimes and alignment
        datadir=td.datadirs{i};
        if ismac datadir=macifypath(datadir);end
        cd(datadir)
        [vids,units,chans] = AssimilateSignals(cricketdropframe, catchframe);
        
        %plot rasters aligned to the geometry variables
        numunits=length(units);
        cmap=jet(numunits);
        offset=1.25;
        for u=1:numunits
            offset=offset+.05;
            start=units(1).start;
            stop=units(1).stop;
            spiketimes=units(u).spiketimes;
            spiketimes=spiketimes-start; %align to cricketdrop
            plot(spiketimes, zeros(size(spiketimes))+offset, '.', 'markersize', 20, 'color', cmap(u,:))
        end
        xlim([0 t(catchframe)])
        yl=ylim;
        yl(2)=yl(2)+.05;
        ylim(yl);
        
        clear fr nfr
        for u=1:numunits
            start=units(1).start;
            stop=units(1).stop;
            spiketimes=units(u).spiketimes;
            spiketimes=spiketimes-start; %align to cricketdrop
            
            %this puts the psth samplerate at framerate
            binwidth= 1/td.groupdata(1).framerate; %s
            %psth=conv(allst, gaussian(100, .25));
            [n,x]=hist(spiketimes, [0:binwidth:t(end)]);
            fr(u,:)=smooth(n);
        end
        nfr=fr./max(fr(:)); %normalize
        
        offset=1.25;
        for u=1:numunits
            offset=offset+.05;
            plot(x, nfr(u,:)+offset, 'color', cmap(u,:), 'linewidth', 2)
            
        end
        line([0 0], ylim)
        xlabel('time, s')
        
        fig2=figure;
        subplot(511)
        hold on
        for u=1:numunits
            [xc, lag]=xcorr(nfr(u,:),  cspeed,  50);
            lags=1000*lag/td.groupdata(1).framerate; %ms
            offset=offset+10;
            plot(lags, xc+offset, 'color', cmap(u,:), 'linewidth', 2)
            xlabel('time  lag, ms')
            ylabel('cricket speed')
        end
        subplot(512)
        hold on
        for u=1:numunits
            [xc, lag]=xcorr(nfr(u,:),  speed,  50);
            lags=1000*lag/td.groupdata(1).framerate; %ms
            offset=offset+10;
            plot(lags, xc+offset, 'color', cmap(u,:), 'linewidth', 2)
            xlabel('time  lag, ms')
            ylabel('mouse speed')
        end
        subplot(513)
        hold on
        for u=1:numunits
            [xc, lag]=xcorr(nfr(u,:),  RelativeAzimuth,  50);
            lags=1000*lag/td.groupdata(1).framerate; %ms
            offset=offset+10;
            plot(lags, xc+offset, 'color', cmap(u,:), 'linewidth', 2)
            xlabel('time  lag, ms')
            ylabel('azimuth')
        end
             subplot(514)
        hold on
        for u=1:numunits
            [xc, lag]=xcorr(nfr(u,:),  range,  50);
            lags=1000*lag/td.groupdata(1).framerate; %ms
            offset=offset+10;
            plot(lags, xc+offset, 'color', cmap(u,:), 'linewidth', 2)
            xlabel('time  lag, ms')
            ylabel('range')
        end
        
        subplot(511)
        title({'xcorr of FR with geometry', dirname});
        
        subplot(515);
        %shuffle corrector
        hold on
        shufspeed=cspeed(randperm(length(cspeed)));
        for u=1:numunits
            [xc, lag]=xcorr(nfr(u,:), shufspeed,  50);
            lags=1000*lag/td.groupdata(1).framerate; %ms
            offset=offset+10;
            plot(lags, xc+offset, 'color', cmap(u,:), 'linewidth', 2)
            xlabel('time  lag, ms')
            ylabel('shuffled cricket')
        end
    end
    
    
    
    
    
    fprintf('\ndir %d/%d', i, length(td.datadirs))
    fprintf('\n_____________________________________________________\n')
    
    
    cd(outputdir)
    try
        figure(fig1);
        pause(.01)
        print(outpsfilename, '-dpsc2', '-append', '-bestfit')
        close
        pause(.01)
        figure(fig2);
        orient tall
        print(outpsfilename, '-dpsc2', '-append', '-bestfit')
        close
    end
    
    
end

















