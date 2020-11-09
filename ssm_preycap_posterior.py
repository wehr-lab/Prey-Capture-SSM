# loads training data from mat-file, saves posterior probabilities into ssm_posterior_probs.mat

import numpy 
import ssm
from scipy import io
import time
import os

# Build an HMM instance and set parameters
#np.random.seed(1)
num_states = 39    # number of discrete states
obs_dim = 14       # dimensionality of observation
#cov="gaussian"
cov="diagonal_gaussian"
hmm = ssm.HMM(num_states, obs_dim, observations=cov)

#load data using loadmat
mat=io.loadmat('C:/Users/Kat/Resilio Sync/Prey Capture/state_epoch_clips-09-Nov-2020/training_data.mat') 
X = mat['X']

#fit hmm to data
#N_iters=200
N_iters=10
hmm_lls = hmm.fit(X, method="em", num_iters=N_iters)
Z = hmm.most_likely_states(X)
Ps = hmm.expected_states(X)
TM = hmm.transitions.transition_matrix
run_on = time.asctime( time.localtime(time.time()) )
run_from = os.getcwd()

#save output files using savemat
mdict={'Z': Z, 'Ps': Ps, 'num_states': num_states, 'obs_dim':obs_dim, 'hmm_lls':hmm_lls, 'TM':TM, 'cov':cov, 'run_on':run_on, 'run_from':run_from}
io.savemat('ssm_posterior_probs.mat', mdict)



