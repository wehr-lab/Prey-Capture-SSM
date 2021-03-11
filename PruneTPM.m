 function PruneTPM(datadir)
% loads ssm output generated by ssm_preycap_posterior.py
% prunes low-occupancy states and short epochs
% computes symbolic TPM
% saves results in pruned_tpm.mat

% parameters we may tweak are here
state_duration_cutoff=100; %in frames, 100 worked well for 30 Hz framerate (also depends on total frames)
epoch_duration_cutoff=10;

%load the output of the python ssm code 
cd(datadir)
load ssm_posterior_probs.mat
load training_data
num_states=double(num_states);

K=size(post_probs_undec, 2);
for k=1:K
    pp=post_probs_undec(:,k)';
    xs=find(pp>.8);
    dxs=diff(xs);
    stopsi=find(dxs>1);
    stops=xs([stopsi end]);
    startsi=[1 stopsi+1];
    starts=xs(startsi);
    %     starts=starts(1:end-1);
    num_epochs(k)=length(starts);
    epochs(k).starts=starts; %start frame of each epoch
    epochs(k).stops=stops;
    epochs(k).num_epochs=length(starts);
    epochs(k).numframes= 1+stops-starts; %number of frames in each epoch
    epochs(k).total_numframes=sum(epochs(k).numframes); %total frames across all epochs of this state
end

%prune away states with very low total occupancy
excluded_states=[];
% state_duration_cutoff=100; %moved to parameter section at top
fprintf('\nexcluding states of less than %d frames', state_duration_cutoff)
for k=1:num_states
    
    %these lines inspect the occupancy
    %fprintf('\nstate %d, %d epochs, %d total frames', k, num_epochs(k), epochs(k).total_numframes)
    %MM(k,:)=[k, num_epochs(k), epochs(k).total_numframes];
    %sortrows(MM, 3);
    %based on inpection,
    %I'm arbitrarily choosing 100 frames as the cutoff
    
    if epochs(k).total_numframes<state_duration_cutoff
        excluded_states=[excluded_states k];
    end
end
pruned_num_states=num_states-length(excluded_states);
fprintf('\nexcluding %d of %d states, %d remaining states',...
    length(excluded_states), num_states, pruned_num_states);

% prune away epochs of very short duration
durs=[];
for k=1:num_states
    nf=epochs(k).numframes;
    durs=[durs nf];
end
figure
hist(durs, 100)
xlabel('epoch duration');ylabel('count')
%based on inpection,
%I'm arbitrarily choosing 2 frames as the cutoff
% epoch_duration_cutoff=10; %moved to parameter section at top
fprintf('\nexcluding epochs of less than %d frames', epoch_duration_cutoff)
fprintf('\nexcluding %d of %d epochs (%d %%)',length(find(durs<=epoch_duration_cutoff)), length(durs), round(100*length(find(durs<=epoch_duration_cutoff))/length(durs)))

kk=0;
Z2k=nan(num_states, 1);
for k=1:num_states
    if ~ismember(k, excluded_states)
        starts=epochs(k).starts;
        stops=epochs(k).stops;
        numframes=epochs(k).numframes;
        surviving_epochs=find(numframes>epoch_duration_cutoff);
        if length(surviving_epochs)>0
            kk=kk+1;
            pruned_num_epochs(kk)=length(surviving_epochs);
            pruned_epochs(kk).starts=starts(surviving_epochs);
            pruned_epochs(kk).stops=stops(surviving_epochs);
            pruned_epochs(kk).num_epochs=length(surviving_epochs);
            pruned_epochs(kk).numframes=numframes(surviving_epochs);
            pruned_epochs(kk).total_numframes=sum(numframes(surviving_epochs));
            pruned_epochs(kk).Z=k; %map from pruned_epochs k (dim=pruned_num_epochs)to Z (dim=num_states)  
            Z2k(k)=kk; %map from Z to pruned_epochs k
        end
    end
end
pruned_num_states=kk;
fprintf('\nafter epoch duration pruning %d states remain', pruned_num_states)


% post-pruning inspection
durs=[];
for k=1:pruned_num_states
    nf=pruned_epochs(k).numframes;
    durs=[durs nf];
end
figure
hist(durs, 100)
xlabel('post-pruning epoch duration');ylabel('count')


%this just lists the surviving frames for easy look-up
%although I don't think I actually use it
surviving_frames=[]; %list of surviving frames, in state order not frame order
surviving_state_list=[]; %corresponding list of states
survival_mask=zeros(size(Z)); %for every frame in entire dataset, 0 if pruned, 1 if survived pruning
for k=1:pruned_num_states
    starts=pruned_epochs(k).starts;
    stops=pruned_epochs(k).stops;
    for ne=1:pruned_epochs(k).num_epochs
        frames=starts(ne):stops(ne);
        survival_mask(frames)=1;
        surviving_frames=[surviving_frames frames];
        surviving_state_list=[surviving_state_list k*ones(size(frames))];
    end
end
fprintf('\n%d surviving frames (out of %d total)', ...
    length(surviving_frames), length(X))

% this is just a list of start frames with state,
%this turns out to be a better way to generate the symbolic sequence after
%pruning
e=0;
for k=1:pruned_num_states
    starts=pruned_epochs(k).starts;
    for ne=1:length(starts)
        e=e+1;
        raw_Zsym(e,1)=starts(ne);
        raw_Zsym(e,2)=k;
    end
end
sorted_Zsym=sortrows(raw_Zsym, 1);
Zsym=sorted_Zsym(:,2);

%prune spurious symbolic state repeats that may arise when 
% too-short or uncertain (p<.8) states are pruned away
Zbak=Zsym; %just for debugging
cont=1;
while cont
        cont=0;
    for i=1:length(Zsym)-1
        if Zsym(i)==Zsym(i+1)
            temp=Zsym(i+1:end);
            Zsym(i:end)=nan;
            Zsym(i:end-1)=temp;
            cont=1;
        end
    end
end
fprintf('\npruned %d spurious symbolic state repeats (out of %d total)', ...
    length(find(isnan(Zsym))), length(Zsym));
Zsym=Zsym(~isnan(Zsym));


%compute a symbolic TPM, where the transition probabilities are between
%discreet state epochs rather than sample transitions which are dependent on duration
%first, compute a vector of state epochs

% Zsym will be the symbolic state sequence
% clear K Zsym Zsym_startframe
% % Zsym_startframe was just used in debugging
% for f=1:length(X)
%     pp=post_probs(f,:);
%     k=find(pp==max(pp));
%     K(f)=k;
%     if pp(K(f))<.8 K(f)=nan; end
%     if ismember(k, excluded_states) K(f)=nan; end
%     if ~ismember(f, surviving_frames) K(f)=nan; end
% end
%
%
% f1=1;
% while isnan(K(f1))
%     f1=f1+1;
% end
% Zsym(1)=K(f1);
%
% n=1;
% for f=f1+1:length(X)
%     if isnan (K(f))
%         %skip this frame (no pp>.8)
%     elseif K(f)==K(f-1)
%         %skip this frame (same epoch, state didn't change)
%     else
%         n=n+1;
%         Zsym(n)=K(f);
%
%     end
% end

fprintf('\nsanity check:')
fprintf('\nnumber of epochs from num_epochs %d', sum(pruned_num_epochs))
fprintf('\nnumber of epochs from Zsym %d', length(Zsym))
fprintf('\na difference of %d', ...
    length(Zsym)-sum(pruned_num_epochs))
% more sanity check
% for m=1:num_states
%    fprintf('\n%d %d %d',m, num_epochs(m), length( find (Zsym==m)))
% end
%
% a=Zsym_startframe(find (Zsym==10));
% b=epochs(10).starts;
% for i=1:length(a)
%     fprintf('\n%d %d', a(i), b(i))
% end



seq=Zsym;
clear t
t=sparse(seq(1:end-1), seq(2:end), 1);
t=full(t);
[M,N]=size(t);
tpm=zeros(pruned_num_states);
tpm(1:M,1:N)=t./ repmat(sum(t, 2), 1, N);
tpm(isnan(tpm))=0;

figure
imagesc(tpm)
% caxis([0 .2])
axis square
colorbar
colormap hot;shg
title('symbolic transition probability matrix')


readme={
    'num_states: number of states in the hmm model'
    'post_probs: matrix returned by hmm, frames x numstates'
    'TM: transition prob matrix returned by hmm'
    'hmm_lls: hmm convergence goodness of fit'
    'X: input data to hmm (observations), normalized'
    'rawX: non-normalized X'
    'X_description: description of variables in X'
    'X_sourcefile: filename of groupdata'
    'Groupdata: raw data from which X was generated'
    'Z: viterbi state sequence from ssm'
    'localframenum: frame num within each trial'
    'note that X is trimmed from start_frame:firstcontact_frame'
    '                                   '
    'epochs: structure array of epoch details for each state (before pruning)'
    'num_epochs: number of epochs in each state, before pruning (same as pruned_epochs.num_epochs)'
    '                                   '
    'epoch_duration_cutoff: exclude (prune) epochs shorter than this, e.g. 2 frames'
    'state_duration_cutoff: pruning cutoff for total occupancy (e.g. <100 frames)'
    'excluded_states: states pruned for low total occupancy (e.g. <100 frames)'
    'surviving_frames: list of frames after pruning (in state order)'
    'surviving_state_list: list of states after pruning (in state order, corresponds to surviving_frames)'
    'survival_mask: for every frame in entire dataset, 0 if pruned, 1 if survived pruning'
    'pruned_epochs: structure array of epoch details for each state (after pruning)'
    'pruned_num_epochs: number of epochs in each state, after pruning (same as pruned_epochs.num_epochs)'
    'pruned_num_states: number of hmm states after pruning'
    'Zsym: symbolic state-epoch sequence, after pruning. One number for each epoch.'
    'tpm: symbolic transition probability matrix after pruning'
    ' '
    'run_on: time, date, and function that generated this file'
    };

save pruned_tpm num_states epoch_duration_cutoff post_probs ...
    Ps epochs surviving_frames surviving_state_list survival_mask readme ...
    TM excluded_states pruned_epochs surviving_state_list ...
    X pruned_num_epochs X_description pruned_num_states ...
    Zundec post_probs post_probs_undec ...
    tpm DirList hmm_lls Z Zsym ...
    num_epochs state_duration_cutoff ...
    run_on localframenum


fprintf('\nsaved results in pruned_tpm.mat')
%note that all data saved in training_data are also copied into pruned_tpm
