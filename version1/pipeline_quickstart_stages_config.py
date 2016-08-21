#!/bin/env python

""" pipeline_quickstart_stages_config.py

    -Configuration file to set options specific to each stage/task in pipeline_quickstart.py
=============================================================================
"""
import os

import QuickstartUserInput as I

import WitsgwasSoftware as SW

# python = SW.python
# plink = SW.plink
# plink1 = SW.plink1
# perl = SW.perl
# R = SW.R


# stageDefaults contains the default options which are applied to each stage (command).
# This section is required for every Rubra pipeline.
# These can be overridden by options defined for individual stages, below.
# Stage options which Rubra will recognise are: 
#  - distributed: a boolean determining whether the task should be submitted to a cluster
#      job scheduling system (True) or run on the system local to Rubra (False). 
#  - walltime: for a distributed PBS job, gives the walltime requested from the job
#      queue system; the maximum allowed runtime. For local jobs has no effect.
#  - memInGB: for a distributed PBS job, gives the memory in Gigabytes requested from the 
#      job queue system. For local jobs has no effect.
#  - queue: for a distributed PBS job, this is the name of the queue to submit the
#      job to. For local jobs has no effect. This is currently a mandatory field for
#      distributed jobs, but can be set to None.
#  - modules: the modules to be loaded before running the task. This is intended for  
#      systems with environment modules installed. Rubra will call module load on each 
#      required module before running the task. Note that defining modules for individual 
#      stages will override (not add to) any modules listed here. This currently only
#      works for distributed jobs.



stageDefaults = {
    'distributed': True,
    'queue': 'WitsLong',
    'walltime': "6:00:00",
    'memInGB': 16,
    'name': None,
    'modules': [
#         python,
#         plink,
#         perl,
#         R,
          'gwaspipe',
    ]
}



# stages should hold the details of each stage which can be called by runStageCheck.
# This section is required for every Rubra pipeline.
# Calling a stage in this way carries out checkpointing and, if desired, batch job
# submission. 
# Each stage must contain a 'command' definition. See stageDefaults above for other 
# allowable options.


stages = {
	'task1': {
		"command": ""
	},
	'task2': {
		"command": ""
	},
	'task3': {
		'command': ""
	},
}
