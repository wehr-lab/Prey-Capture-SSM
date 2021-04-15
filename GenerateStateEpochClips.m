function GenerateStateEpochClips(outputdir)
% slice source videos into video clips for each state and epoch (up to some
% max num epochs)
%
% looks in the original data dirs (from pruned_tpm/datadirs) for the source videos
% then slices them into states and epochs based on
% pruned_tpm.mat generated by PruneTPM



cd (outputdir)
load('pruned_tpm.mat')
load('training_data.mat')

% this is now in datadirs_by_frame
% first store source movie paths and filenames
% % cumframeidx=0;
% % fprintf('\norganizing filenames...')
% % for i= 1:length(Groupdata);
% %     start_frame=Groupdata(i).start_frame;
% %     stop_frame=Groupdata(i).stop_frame;
% %     firstcontact_frame=Groupdata(i).firstcontact_frame;
% %     drug=Groupdata(i).drug;
% %      numframes1=Groupdata(i).numframes; %mw 07.21.2020
% % %    numframes1=Groupdata(i).firstcontact_frame;
% %
% %     if isfield(Groupdata(i), 'movie_location')
% %         movie_location=Groupdata(i).movie_location;
% %     else
% %         %     find the corresponding movie location from filelist
% %         movie_location='';
% %         for j=1:length(files)
% %             if files(j).start_frame==start_frame & ...
% %                    ...% files(j).stop_frame==stop_frame & ...
% %                     files(j).firstcontact_frame==firstcontact_frame & ...
% %                     files(j).drug==drug
% %                 movie_location=files(j).datapath;
% %                 fprintf('j=%d %d %d %s', j, start_frame, stop_frame, movie_location)
% %             end
% %         end
% %     end
% %     if isempty(movie_location)
% %         error('could not identify movie location')
% %     end
% %     new_movie_location=strrep(movie_location,...
% %         'D:\lab\Data\Injections_mice\', local_movie_root);
% %     new_movie_location=strrep(new_movie_location, '\', '/');
% %     cd(new_movie_location)
% %     d=dir('*_labeled.mp4');
% %     movie_filename=d.name;
% %     fprintf('\nmovie %d/%d ', i,length(Groupdata))
% %     for f=1:numframes1
% %         cumframeidx=cumframeidx+1;
% %         sourcemoviefilename{cumframeidx}=movie_filename;
% %         sourcemoviefilepath{cumframeidx}=new_movie_location;
% %         localframenum2(cumframeidx)=f;
% %     end
% % end
%I checked and localframenum==localframenum2 everywhere
%so that's solid

%look for epochs that span movie boundaries, which is causing an error
%reading the movies to get the epoch clip.
%The code block below identifies where this happens and
%plots it for inspection. My conclusion is that it can happen, it's not
%really an error. The HMM could classify a stretch of video as an epoch of
%a state even if the video contains a jump cut between movies. It happens
%rarely, like once per thousand epochs, so it seems reasonable to just
%discard such clips or truncate them to one of the straddled videos.
%
% for k=1:pruned_num_states
%     fprintf('\nstate %d/%d ', k, pruned_num_states );
%     nbytes = fprintf(' epoch 0/%d', pruned_epochs(k).num_epochs );
%     for e=1:min(36, pruned_epochs(k).num_epochs)
%         %         fprintf(repmat('\b',1,nbytes));
%         %         nbytes = fprintf(' epoch %d/%d', e,pruned_epochs(k).num_epochs );
%
%         absstartframe=pruned_epochs(k).starts(e); %these are relative to X
%         absstopframe=pruned_epochs(k).stops(e);
%         localstartframe=localframenum2(absstartframe);
%         localstopframe=localframenum2(absstopframe);
%         %         fprintf('\n%d %d, %d %d', absstartframe,absstopframe, localstartframe, localstopframe)
%         if localstopframe<localstartframe
%             fprintf('\nk%d-e%d %d %d, %d %d',k,e, absstartframe,absstopframe, localstartframe, localstopframe)
%             %this only makes sense for the figure from plot_posterior_probs
%             subplot(211); xlim([absstartframe-10 absstopframe+10 ]);
%             subplot(212); xlim([absstartframe-10 absstopframe+10 ]);
%             x=absstartframe-10:absstopframe+10;
%             movieboundary=find(localframenum(x)==1)
%
%             subplot(211);hold on;
%             plot(x(movieboundary), 0, '+', absstartframe, 0, '*', absstopframe, 0, '*');
%             subplot(212); hold on;
%             plot(x(movieboundary), 0.5, '+', absstartframe, 0.5, '*', absstopframe, 0.5, '*');
%             keyboard
%         end
%     end
% end

cd (outputdir)
datadirs_by_frame=datadirs_by_frame;
pruned_num_states=pruned_num_states;
pruned_epochs=pruned_epochs;
localframenum=localframenum;

for k=8:pruned_num_states
    fprintf('\nstate %d/%d ', k, pruned_num_states );
    nbytes = fprintf(' epoch 0/%d', pruned_epochs(k).num_epochs );
    for e=1:min(25, pruned_epochs(k).num_epochs)
        fprintf(repmat('\b',1,nbytes));
        nbytes = fprintf(' epoch %d/%d', e,pruned_epochs(k).num_epochs );
        
        absstartframe=pruned_epochs(k).starts(e); %these are relative to X
        absstopframe=pruned_epochs(k).stops(e);
        moviedir=datadirs_by_frame{absstartframe};
        
        % localframenum comes from ConvertGeometryToObservations and
        % already accounts for trimming from cricket drop frame to catch
        % frame
        localstartframe=localframenum(absstartframe);
        localstopframe=localframenum(absstopframe);
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
                localstopframe=L(movieboundary);
            elseif movieboundary<=round(length(absframes)/2)
                %keep the part of epoch that's in the second movie
                L=localframenum(absframes);
                localstartframe=L(movieboundary+1);
                moviedir=datadirs_by_frame{absstopframe};
            else %not sure what's wrong with this movie boundary so let's just bail on this epoch
                warning(sprintf('not sure what''s wrong with this movie boundary, bailing on this epoch (state %d epoch %d)', k, e))
                skipepoch=1;
            end
        end
        if ~skipepoch
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
            str=sprintf('k%d e%d', k,e);
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







