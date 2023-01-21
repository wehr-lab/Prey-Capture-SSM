function PrintFigs(outputdir)
%just print -append open figures to a ps file

psfilename='figs.ps';
cd(outputdir) %absolute
figs=findobj('type', 'figure');
figs=fliplr(figs');
figs=sort(figs);
fprintf('\nfigs: ');
fprintf(' %d', figs.Number);

numfigs=length(figs);
%this may seem like crazy overkill but it keeps crashing when trying to
%print a figure that is already closed, still cannot figure out why
for f=figs

    try
        figure(f)
        drawnow
        pause(.1)
        fprintf('\nprinting figure %d/%d', f.Number, numfigs)
        print('-dpsc2', '-append', '-bestfit', psfilename)
        pause(.1)
        fprintf('\n closing figure %d/%d', f.Number, numfigs)
        close
    catch
        fprintf('\nfailed to print figure')
    end
end
