% utility cleanup script to delete a bazillion epoch clip avi files in many subfolders

rootdir='/Volumes/Projects/Social Approach/save_OEablationSocial/param_search'
cd(rootdir)
d=dir('state-epoch-clips*');


str=sprintf('you are in %s\nDo you want to delete all ssm_state_epoch_clip*.avi files \n in %d state-epoch-clips* subdirectories? \ntype y to continue\n\n', pwd, length(d));
x = input(str, 's');
if ~strcmp(x, 'y')
    warning('canceled by user')
    return
end


for i=1:length(d)
    if d(i).isdir
        fprintf('\nsubdirectory %s', d(i).name)
        cd(d(i).name)
        d2=dir('ssm_state_epoch_clip*.avi');
        fprintf('\n deleting %d ssm_state_epoch_clip avi files', length(d2))

        delete ssm_state_epoch_clip*.avi

        cd ..
    end
end
