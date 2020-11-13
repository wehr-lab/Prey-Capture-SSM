function PlotTPM(datadir)
% loads pruned_tpm generated by PruneTPM
% and plots a few things
%
% Note that now this file only plots stuff, it's not part of the data
% processing pipeline

cd()
%load ssm_posterior_probs.mat
%load training_data
load pruned_tpm
num_states=double(num_states);
fprintf('\n%d states', num_states)

% post-pruning inspection
durs=[];
for k=1:pruned_num_states
    nf=pruned_epochs(k).numframes;
    durs=[durs nf];
end
figure
hist(durs, 100)
xlabel('post-pruning epoch duration');ylabel('count')

figure
imagesc(tpm)
% caxis([0 .2])
axis square
colorbar
colormap hot;shg
title('symbolic transition probability matrix')

% hierarchical clustering of tpm, for all data
%note that dendrogram only returns 30 leaves by default, so you have to
%include 0 as arg 2
figure
tree=linkage(tpm, 'average');
colorthresh=.9*max(tree(:,3)); %threshold for color-coding the clusters
[H,T,outperm] = dendrogram(tree,0,'Orientation','left','ColorThreshold',colorthresh);
set(H,'LineWidth',2)
size(outperm)
figure
imagesc(tpm(outperm,outperm))
colormap(hot)
axis square
set(gca, 'xtick', 1:length(T), 'ytick', 1:length(T), 'xticklabel', outperm, 'yticklabel', outperm)
title('symbolic tpm all data, clustered')
