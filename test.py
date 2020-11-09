from scipy import io

x=io.loadmat('C:/Users/Kat/Resilio Sync/Prey Capture/state_epoch_clips-03-Nov-2020/test.mat')
m = x['m']
print(m)

