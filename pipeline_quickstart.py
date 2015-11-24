#!/bin/env python

""" pipeline_quickstart.py 

    -One line description of the pipeline.
=============================================================================


Authors:


Goal of the pipeline:
This program implements a <<type of pipeline e.g. QC, association testing, etc>> workflow 
for human GWAS analysis using <<name_of_program e.g. PLINK>>
 

Pipeline features:
List the features of the pipeline:

 - Feature 1
 - Feature 2
 - Feature 3
 
Assumptions:
This pipeline assumes the following steps have been carried out:


Task management:
It employs Rubra for sending jobs to a linux cluster via PBS Torque (version 2.5). 
Rubra is a pipeline system for bioinformatics workflows that is built on top
of the Ruffus (http://www.ruffus.org.uk/) Python library (Ruffus version 2.2). 
Rubra adds support for running pipeline stages on a distributed computer cluster 
(https://github.com/bjpop/rubra) and also supports parallel evaluation of independent 
pipeline stages. (Rubra version 0.1.5)

The pipeline is configured by an options file in a python file,
including the actual commands which are run at each stage.


References:

"""


# system imports
import sys        # will use to exit sys if no input files are detected
import os		  # for changing directories
import datetime   # for adding timestamps to directories
import subprocess # for executing shell command, can be used instead of os.system()


# rubra and ruffus imports
from ruffus import *
from rubra.utils import pipeline_options
from rubra.utils import (runStageCheck, mkLogFile, mkDir, mkForceLink)

# witsGWAS banner
from pyfiglet import Figlet

# user defined module imports
import Filemanager as FM
import WitsgwasSoftware as SW
import WitsgwasScripts as SC



# Shorthand access to options defined in pipeline_quickstart_config.py
#==========================================

working_files = pipeline_options.working_files
logDir = pipeline_options.pipeline['logDir']



# Data setup process and input organisation
#==========================================

f = Figlet(font='standard')
print f.renderText('witsGWAS')
print "(C) 2015 Lerato E. Magosi, Scott Hazelhurst"
print "http://magosil86.github.io/witsGWAS/"    
print "witsGWAS v0.1.0 is licensed under the MIT license. See LICENSE.txt"
print "----------------------------------------------------------------"


# create a directory for the current project
# note: The pipeline will use this dir. for output and intermediate files.
SC.CURRENT_PROJECT_DIR = (os.path.join(SC.witsGWAS_PROJECTS_DIR, working_files['projectname']) + 
	'-pipeline_quickstart-' + datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S') + '/')

print "Current project directory %s" % SC.CURRENT_PROJECT_DIR

FM.create_dir(SC.CURRENT_PROJECT_DIR)


# path to the witsGWAS directory
global witsGWAS_SCRIPTS_ROOT_DIR
witsGWAS_SCRIPTS_ROOT_DIR = "absolute/path/to/witsGWAS/"


# cd into the current project dir.
os.chdir(SC.CURRENT_PROJECT_DIR)


# Check current working directory.
curr_work_dir = os.getcwd()
print "Current working directory %s" % curr_work_dir

 
# create a dir. for storing plots
pipeline_quickstart_plots = (os.path.join(witsGWAS_SCRIPTS_ROOT_DIR, SC.CURRENT_PROJECT_DIR, "pipeline_quickstart_plots") + '/') 
FM.create_dir(pipeline_quickstart_plots)




# Paths to intermediate result files
#==========================================






# Print project information
#==========================================

print "Starting project %s" % working_files['projectname']
print
print "Intermediate files and output will be stored in %s" % SC.CURRENT_PROJECT_DIR
print "Log dir is %s" % logDir
print "Project author is %s" % working_files['projectauthor'] 
print



# Pipeline declarations
#==========================================

# create a flagfile to start the pipeline as well as permutation association testing
FM.create_emptyfile('pipeline_quickstart.Start')





# Pipeline tasks
#==========================================









