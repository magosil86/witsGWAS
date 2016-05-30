#!/bin/env python

""" pipeline_quickstart_config.py 

    -Configuration file to set input files, directories and parameters 
    specific to pipeline_quickstart.py
=============================================================================
"""

import os
import WitsgwasScripts as SC 
import QuickstartUserInput as I


# This section is used by the pipeline_quickstart.py to specify input data and 
# working directories.

# Required inputs:
# 1. path to input1 
# 2. path to input2
# 3. input3

'''
note: project name will be used by the pipeline to generate a 
time stamped output directory '''


working_files = {
}


# This OPTIONAL section is used by the pipeline_quickstart.py to submit preselected user cutoffs

preselected_cutoff = {
}



# This section is used by the pipeline_quickstart.py to specify configuration options 
# for itself (pipeline_quickstart.py) as well as Rubra. 

# Rubra variables:
#  - logDir: the directory where batch queue scripts, stdout and sterr dumps are stored.
#  - logFile: the file used to log all jobs that are run.
#  - style: the default style, one of 'flowchart', 'print', 'run', 'touchfiles'. Can be 
#      overridden by specifying --style on the command line.
#  - procs: the number of python processes to run simultaneously. This determines the
#      maximum parallelism of the pipeline. For distributed jobs it also constrains the
#      maximum total jobs submitted to the queue at any one time.
#  - verbosity: one of 0 (quiet), 1 (normal), 2 (chatty). Can be overridden by specifying
#      --verbose on the command line.
#  - end: the desired tasks to be run. Rubra will also run all tasks which are dependencies 
#      of these tasks. Can be overridden by specifying --end on the command line.
#  - force: tasks which will be forced to run, regardless of timestamps. Can be overridden
#      by supplying --force on the command line.
#  - rebuild: one of 'fromstart','fromend'. Whether to calculate which dependencies will
#      be rerun by working back from an end task to the latest up-to-date task, or forward
#      from the earliest out-of-date task. 'fromstart' is the most conservative and 
#      commonly used as it brings all intermediate tasks up to date.


# pipeline_quickstart variables:
# nothing at this stage, but could be used to add more features in future

pipeline = {
    'logDir': os.path.join(SC.CURRENT_PROJECT_DIR, "log_quickstart"),
    'logFile': 'pipeline_quickstart.log',
    'style': 'print',
    'procs': 30,
    'verbose': 1,
    'end': ['quickstart_end_task' 
            ],
    'force': [],
    'rebuild' : "fromstart",

    'restrict_samples': False,
    'allowed_samples': []
    
}
