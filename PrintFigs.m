function PrintFigs(outputdir)
%just print -append open figures to a ps file

psfilename='figs.ps';
cd(outputdir) %absolute
figs=findobj('type', 'figure');
figs=fliplr(figs');
for f=figs
    figure(f)
    drawnow
    pause(.1)
    print('-dpsc2', '-append', '-bestfit', psfilename)
    pause(.1)
    close
end
