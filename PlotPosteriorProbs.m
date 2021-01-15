function PlotPosteriorProbs(datadir)
% loads ssm output generated by ssm_preycap_posterior.py
% and plots a few things
%
% Note that now this file only plots stuff, it's not part of the data
% processing pipeline

%load the output of the python code and plot stuff
%note that the python code uses savemat to save several types of output
load ./ssm_posterior_probs.mat
load ./training_data
num_states=double(num_states);
fprintf('\n%d states', num_states)
%this plots goodness of fit across iterations
figure
plot(hmm_lls)
xlabel('iteration')
ylabel('log likelihood')


t=1:length(X);
post_probs=Ps{1};
% post probs is T x k
K=size(post_probs, 2);
colors=jet(K);

%plot observation data with states colored by jbfill shading where prob>0.8
figure
clf
subplot(211)
plot(t, X)
yl=ylim;
for k=1:K
    pp=post_probs(:,k)';
    xs=find(pp>.8);
    dxs=diff(xs);
    stops=find(dxs>1);
    starts=[1 stops+1];
    starts=starts(1:end-1);
    for i=1:length(starts)
        c=colors(k,:);
        x=xs(starts(i):stops(i));
        aux.jbfill(x,0*x+yl(1),0*x+yl(2),c,c,1,.1);
    end
end

%this plots posterior probabilities of each state
%also with state color-coding by jbfill
subplot(212)
plot(t, post_probs, '.-' )
ylim([0 1.1])
yl=ylim;

for k=1:K
    pp=post_probs(:,k)';
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
    
    
    for i=1:length(starts)
        c=colors(k,:);
        x=starts(i):stops(i);
        aux.jbfill(x,0*x+yl(1),0*x+yl(2),c,c,1,.1);
    end
end
set(gcf, 'pos',[82 1568 1581 420])
xlim([0 2000])
ylim([-.1 1.2])
shg

%this is the transition probability matrix TPM
figure
imagesc(TM)
caxis([0 .2])
axis square
colorbar
colormap hot;shg
title('true transition probability matrix')
