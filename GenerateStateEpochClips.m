function GenerateStateEpochClips(outputdir1, localmovieroot)
% slice source videos into video clips for each state and epoch (up to some
% max num epochs)
%
% looks in the original data dirs (from pruned_tpm/datadirs) for the source videos
% then slices them into states and epochs based on
% pruned_tpm.mat generated by PruneTPM



cd (outputdir1)
load('pruned_tpm.mat')
load('training_data.mat')
outputdir=outputdir1;  %overwrite whatever's in pruned_tpm, in case we manually changed the name
%of the output directory (as sometimes happens when you run more than one
%per day)



cd (outputdir)
datadirs_by_frame=datadirs_by_frame;
pruned_num_states=pruned_num_states;
pruned_epochs=pruned_epochs;
localframenum=localframenum;

for k=1:pruned_num_states
    fprintf('\nstate %d/%d ', k, pruned_num_states );
    nbytes = fprintf(' epoch 0/%d', pruned_epochs(k).num_epochs );
    for e=1:min(25, pruned_epochs(k).num_epochs)
        fprintf(repmat('\b',1,nbytes));
        nbytes = fprintf(' epoch %d/%d', e,pruned_epochs(k).num_epochs );
        
        absstartframe=pruned_epochs(k).starts(e); %these are relative to X
        absstopframe=pruned_epochs(k).stops(e);
        moviedir=datadirs_by_frame{absstartframe};
        try
            landframe=Land(absstartframe); %Land frame of the movie where the data actually starts
        catch
            landframe=1; %e.g. Land doesn't even exist for social videos
        end
        % localframenum comes from ConvertGeometryToObservations and
        % already accounts for trimming from cricket drop frame to catch
        % frame
        %actually with kip/nick dataFrame format we still need to correct for
        %land frame
        %localstartframe, localstopframe are relative to Land frame, which is stored in indices{trialnum}(1)
        localstartframe=localframenum(absstartframe)+landframe;
        localstopframe=localframenum(absstopframe)+landframe;
        skipepoch=0;
        if localstopframe<localstartframe
            %rare situation where epoch spans a movie boundary
            %localframenum(absframes)
            absframes=absstartframe:absstopframe;
            %             movieboundary=find(localframenum(absframes)==1); %this won't
            %             work now since localframenum starts at cricketdropframe, not at 1
            movieboundary=find(diff(localframenum(absframes))<1, 1);
            if movieboundary>round(length(absframes)/2)
                %keep the part of epoch that's in the first movie
                L=localframenum(absframes);
                localstopframe=L(movieboundary)+landframe;
            elseif movieboundary<=round(length(absframes)/2)
                %keep the part of epoch that's in the second movie
                L=localframenum(absframes);
                localstartframe=L(movieboundary+1)+landframe;
                moviedir=datadirs_by_frame{absstopframe};
            else %not sure what's wrong with this movie boundary so let's just bail on this epoch
                warning(sprintf('not sure what''s wrong with this movie boundary, bailing on this epoch (state %d epoch %d)', k, e))
                skipepoch=1;
            end
        end
        if ~skipepoch
            cd(localmovieroot)
            cd(moviedir)
            d=dir('*labeled.mp4');
            movie_filename=d(1).name;
            v = VideoReader(fullfile(moviedir, movie_filename));
            if localstopframe>v.NumFrames
                warning(sprintf('localstopframe is off from v.NumFrames by %d frames', localstopframe-v.NumFrames))
                localstopframe=v.NumFrames; %
            end
            %         trim really long epochs to some max length e.g. 10 s
            if localstopframe-localstartframe > 10*v.FrameRate
                localstopframe=round(localstartframe + 10*v.FrameRate);
            end
            vidFrames = read(v, [localstartframe, localstopframe]) ;
            vidFrames=imresize(vidFrames, .5);
            str=sprintf('s%d e%d', k,e);
            for f=1:size(vidFrames, 4)
                vidFrames(:,:,:,f) = insertText(vidFrames(:,:,:,f),[5,5],str,...
                    'FontSize',60,'Font', 'Arial', 'BoxColor', 'g',  ...
                    'BoxOpacity',0.4,'TextColor','white');
            end
            out_movie_filename=sprintf('ssm_state_epoch_clip-%d-%d', k, e);
            out_movie_fullfilename=fullfile(outputdir, out_movie_filename);
            vout = VideoWriter(out_movie_fullfilename, 'MPEG-4');
            open(vout)
            writeVideo(vout,vidFrames)
            close(vout)
        end
    end
end


beep







