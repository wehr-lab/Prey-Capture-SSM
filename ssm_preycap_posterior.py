# loads training data from mat-file, saves posterior probabilities into ssm_posterior_probs.mat

import numpy 
import ssm
from scipy import io

# Build an HMM instance and set parameters
#np.random.seed(1)
num_states = 39    # number of discrete states
obs_dim = 14       # dimensionality of observation
#cov="gaussian"
cov="diagonal_gaussian"
hmm = ssm.HMM(num_states, obs_dim, observations=cov)

#load data using loadmat
mat=io.loadmat('training_data.mat')
X = mat['X']

#fit hmm to data
#N_iters=200
N_iters=10
hmm_lls = hmm.fit(X, method="em", num_iters=N_iters)
Z = hmm.most_likely_states(X)
Ps = hmm.expected_states(X)
TM = hmm.transitions.transition_matrix

#save output files using savemat
mdict={'Z': Z, 'Ps': Ps, 'num_states': num_states, 'obs_dim':obs_dim, 'hmm_lls':hmm_lls, 'TM':TM, 'cov':cov}
io.savemat('ssm_posterior_probs.mat', mdict)



