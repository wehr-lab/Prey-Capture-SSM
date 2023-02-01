# loads training data from mat-file, saves posterior probabilities into ssm_posterior_probs.mat
# runs through a range of HMM params in a for loop
# activate the environment first like this:
# source ~/virtualenvironment/ssmenv/bin/activate


import numpy 
import ssm
from scipy import io
import time
import os
import sys
from datetime import datetime

root="/Volumes/Projects/Social Approach/save_OEablationSocial/param_search"
os.chdir(root)
#load data using loadmat
mat=io.loadmat('training_data.mat') 
X = mat['X']

for num_states in range(4, 31, 2):
    for logkappa in range(6, 16, 2):
        for AR_lags in range(2, 15, 4):
            kappa = 10**logkappa
            print([num_states, logkappa, kappa, AR_lags])
            path="state-epoch-clips-%s-%d-1e%d-%d" % (datetime.today().strftime('%Y-%b-%d'), num_states, logkappa, AR_lags)
            print(path)
            os.mkdir(path)
            os.chdir(path)
            # Build an HMM instance and set parameters
            observation_class = 'autoregressive'
            obs_dim = 4       # dimensionality of observation
            transitions = 'sticky'
            hmm = ssm.HMM(num_states, obs_dim,
                          observations=observation_class, observation_kwargs={'lags': AR_lags},
                          transitions=transitions, transition_kwargs={'kappa': kappa})



            #fit hmm to data
            N_iters=10;
            hmm_lls = hmm.fit(X, method="em", num_iters=N_iters)
            Z = hmm.most_likely_states(X)
            Ps = hmm.expected_states(X)
            TM = hmm.transitions.transition_matrix
            run_on = time.asctime( time.localtime(time.time()) )
            run_from = os.getcwd()

            #save output files using savemat
            mdict={'Z': Z, 'Ps': Ps, 'num_states': num_states, 'obs_dim': obs_dim, 'transitions': transitions, 'kappa': kappa, 'AR_lags': AR_lags, 'hmm_lls':hmm_lls, 'TM':TM, 'observation_class': observation_class, 'run_on':run_on, 'run_from':run_from}
            io.savemat('ssm_posterior_probs.mat', mdict)
            os.chdir(root)








