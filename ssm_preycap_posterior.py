# loads training data from mat-file, saves posterior probabilities into ssm_posterior_probs.mat

import numpy 
import ssm
from scipy import io
import time
import os

# Build an HMM instance and set parameters
#np.random.seed(1)
num_states = 20    # number of discrete states
observation_class = 'autoregressive'
obs_dim = 12       # dimensionality of observation
transitions = 'sticky'
kappa = 1E16
AR_lags =  20
hmm = ssm.HMM(num_states, obs_dim,
              observations=observation_class, observation_kwargs={'lags':AR_lags},
              transitions=transitions, transition_kwargs={'kappa': kappa})
print([num_states, kappa, AR_lags])

#load data using loadmat
mat=io.loadmat('training_data.mat') 
#mat=io.loadmat('C:/Users/Kat/Resilio Sync/Prey Capture/state_epoch_clips-06-Jan-2021/training_data.mat') 
X = mat['X']

#fit hmm to data
N_iters=10;
#N_iters=10
hmm_lls = hmm.fit(X, method="em", num_iters=N_iters)
Z = hmm.most_likely_states(X)
Ps = hmm.expected_states(X)
TM = hmm.transitions.transition_matrix
run_on = time.asctime( time.localtime(time.time()) )
run_from = os.getcwd()

#save output files using savemat
mdict={'Z': Z, 'Ps': Ps, 'num_states': num_states, 'obs_dim': obs_dim, 'transitions': transitions, 'kappa': kappa, 'AR_lags': AR_lags, 'hmm_lls':hmm_lls, 'TM':TM, 'observation_class': observation_class, 'run_on':run_on, 'run_from':run_from}
io.savemat('ssm_posterior_probs.mat', mdict)



