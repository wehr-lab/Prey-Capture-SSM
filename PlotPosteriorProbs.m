function PlotPosteriorProbs(datadir)
fprintf('\n%s',mfilename)
% loads ssm output generated by ssm_preycap_posterior.py
% and plots a few things
%
% Note that now this file only plots stuff, it's not part of the data
% processing pipeline

%load the output of the python code and plot stuff
%note that the python code uses savemat to save several types of output
cd(datadir)
load ./ssm_posterior_probs.mat
load ./training_data
num_states=double(num_states);
fprintf('\n%d states', num_states)
%this plots goodness of fit across iterations
figure
plot(hmm_lls)
xlabel('iteration')
ylabel('log likelihood')
fprintf('\nmax log likelihood %g', max(hmm_lls))
title(datadir, 'interpreter', 'none')

t=1:length(X);
t=t/(framerate/decimate_factor);
post_probs=Ps{1};
% post probs is T x k
K=size(post_probs, 2);
colors=jet(K);

framerange=1250; %pointless and slow to plot more than this
figure
for i=1:5
    subplot(5,1,i)
    frames=(i-1)*framerange+1:i*framerange;
    h=plot(t(frames), X(frames,:));
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
            if x(end)>frames(end)
                break
            end
            x=x/(framerate/decimate_factor);
            jbfill(x,0*x+yl(1),0*x+yl(2),c,c,1,.1);
            text(mean(x), 4, int2str(k))
        end
    end
    xlim([t(frames(1)) t(frames(end))])
    ylim([-5 5])
    %highlight your favorite
    idx=find(contains(X_description, 'Range'));
    set(h(idx)', 'linewidth', 2)
end
legend(X_description)
orient tall
% try
%     title(condition.note)
% catch
%     title([condition1.note, condition2.note])
% end
print -dpng post_probs.png

%plot observation data with states colored by jbfill shading where prob>0.8
maxrange=1:10000; %pointless and slow to plot more than this
figure
clf
subplot(211)
h=plot(t(maxrange), X(maxrange,:));
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
        x=x/(framerate/decimate_factor);
        jbfill(x,0*x+yl(1),0*x+yl(2),c,c,1,.1);
    end
end
ylim([-5 5])
legend(X_description)
zoom xon
%highlight your favorite
idx=find(contains(X_description, 'Range'));
set(h(idx)', 'linewidth', 2)
xlim([1 t(maxrange(end))])

%this plots posterior probabilities of each state
%also with state color-coding by jbfill
subplot(212)
plot(t, post_probs, '.-' )
ylim([0 1.1])
yl=ylim;

for k=1:K
    pp=post_probs(:,k)';
    xs=find(pp>.8);
    if !isempty(xs)
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
            x=x/(framerate/decimate_factor);
            jbfill(x,0*x+yl(1),0*x+yl(2),c,c,1,.1);
        end
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
