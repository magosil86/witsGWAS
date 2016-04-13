#!/usr/bin/env nextflow

/*
 * Author       : Rob Clucas
 * Description  : Nextflow pipeline for Wits GWAS.
 */

//---- General definitions --------------------------------------------------//

/* Defines the name of the docker container to run the pipeline through.
 */
params.dock_container   = 'witsgwas'

/* Defines the name of the mountpoint of the data directories in the docker
 * container. This is so that any scripts which run in the container and 
 * might need this info can run succesfully, and the user can specify the 
 * directory to each of the scripts.
 *
 * NOTE: The mountpoint is mounted in the container from the root directory,
 *       so specifying 'util' as the mount point mounts the data at '/util' in
 *       the container.
 */
params.dock_mpoint      = 'util'

/* Defines the directory where the plink 1.07 input binary files are. 
 *
 * NOTE: This must be a relative path, from where the pipeline is run.
 */
params.plink_inputpath  = "gwasdata/plink"

/* Defines the path where any scripts to be executed can be found.
 *
 * NOTE: This must be a ralative path, from where the pipeline is run.
 */
params.script_path      = 'scripts'

/* Defines the names of the plink binary files in the plink directory 
 * (.fam, .bed, .bed).
 *
 * NOTE: This must be without the extension (so if A.fam, A.bed, ... 
 *       then use 'A').
 */
params.plink_fname      = 'raw-GWA-data'

/* Defines the name of the file with high LD region information.
 * 
 * NOTE: This can have/cannot have the extension, but should be in the 
 *       plink_inputpath specified above.
 */
params.high_ld_regions_fname = 'high_LD_regions.txt'

/* Defines if sexinfo is available or not, options are:
 *  - "true"  : sexinfo is available
 *  - "false" : sexinfo is not avalable
 */
params.sexinfo_available = "false"

//---- Cutoff definitions ---------------------------------------------------//

/* Defines the cutoffs for the heterozygosity. Standard cutoff +- 3sd from 
 * mean)
 */
params.cut_het_high = 0.343
params.cut_het_low  = 0.254

/* Defines the cutoff for missingness. Using standard cutoff -- 3 - 7%.
 */
params.cut_miss      = 0.05
params.cut_diff_miss = 0.05;


/* Defines the cutoff for the SNP minor allele frequency.
 */
params.cut_maf        = 0.01

/* Defines the cutoff for SNP missingness.
 */
params.cut_genome     = 0.01

/* Defines the cutoff for the SNP Hardy Weinburg deviation.
 */
params.cut_hwe        = 0.01

//---- Modification of variables for pipeline -------------------------------//

/* Define the command to add for plink depending on whether sexinfo is
 * available or not. Command is:
 * 
 * - No sexinfo availabele  : "--allow-no-sexinfo"   
 * - Sexinfo available      : ""
 */
if ( params.sexinfo_available == "false" ) {
  params.sexinfo_command = "--allow-no-sex"
  println "Sexinfo not available, command: " + params.sexinfo_command + "\n"
} else {
  params.sexinfo_command = ""
  println "Sexinfo availabel command: " + params.sexinfo_command + "\n"
}

/* Convert the relative data path(s) to absolute, because this is required for 
 * docker when mounting.
 */
plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')
script_path     = Channel.fromPath(params.script_path, type : 'dir')

//---- Start Pipeline -------------------------------------------------------//

/* Process to check for duplicates. The process mounts the plink data to the 
 * docker container and then runs plink 1.07 through the docker container. It 
 * writes the results to a file results.
 * 
 * Inputs:
 * - filename   : The name of the plink input files wo extension
 * - container  : The name of the docker container to use
 * - data_path  : The path to the plink data
 * - mountpoint : The mountpoint of the data in the container
 * - sexinfo    : The command to add to plink for sexinfo availability
 *
 * Outputs:
 * - results    : The file with the stdout from plink.
 */
process checkDuplicateMarkers { 
  input:
  val filename    from params.plink_fname
  val container   from params.dock_container
  val data_path   from plink_data_path
  val mountpoint  from params.dock_mpoint
  val sexinfo     from params.sexinfo_command

  output:
  file 'results'

  script:
  """
  docker run -v $data_path:/$mountpoint -w /$mountpoint           \
    $container plink1 --noweb --bfile $filename $sexinfo --out    \
    tmp >> results
  """
}

//---- Process 2 ------------------------------------------------------------//

/* Process to filter all the duplicate markers from running plink.
 *
 * Inputs:
 * - results    : The file containing the stdout from running plink.
 *
 * Outputs:
 * - duplicate  : A file containing all the duplicates from plink.
 */
process filterDuplicateMarkers {
  input:
  file results

  output:
  file 'duplicates'

  script:
  """
  if grep 'Duplicates' results > duplicates; then
    echo 'Duplicates Found' >> duplicates
    echo 'Found Duplicates'
  else                                            
    echo 'No Duplicates Found' >> duplicates
    echo 'Did Not Find Duplicates'
  fi
  """
}

//---- Process 3 ------------------------------------------------------------//

/* Process to extract all the duplicate RSIDs generated by the plink command.
 *
 * Inputs:
 * - duplicates     : The list of duplicates from running plink
 * 
 * Outputs:
 * - duplicate_rdis : A file with all the duplicate RSID's
 *
 * NOTES: The indentation of the inline python script is important because of 
 *        the way python uses indentation. If this has the usual 2 space indent
 *        as the inline bash scripts do, then there is a python error. This 
 *        could be saved as a script and run through docker as well.
 */
process extractDuplicateRsids {
  input:
  file duplicates

  output:
  file 'duplicate_rsids'

  script:
  """
  #!/usr/bin/env python

input    = open('duplicates', 'r')
output   = open('duplicate_rsids', 'w')

# Remove all duplicates
for line in input:
    if (line.startswith('#') or line.startswith('\\n') or
        line == 'Duplicates Found' or line == 'No Duplicates Found\\n'):
        pass
    else:
        line = line.split(" ")
        print(line)
        duplicate_snp = line[5].strip()
        print(duplicate_snp)
        output.write(duplicate_snp + '\\n')
  """
}

//---- Process 4 ------------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to remove all the duplicate markers from the plink output.
 *
 * Inputs:
 * - duplicate_rsids  : A file containing all duplicate rsids to remove.
 * - filename         : The name of the plink input files wo extension
 * - container        : The name of the docker container to use
 * - data_path        : The path to the plink data
 * - mountpoint       : The mountpoint of the data in the container
 * - sexinfo          : The command to add to plink for sexinfo availability 
 *
 * Outputs:
 * - qcplink_log*     : Log files from plink with the output, these are the 
 *                      input to later processes. 
 *
 * NOTES              : Multiple outputs are required so that other processes 
 *                      which use the output can be started concurrently. If 
 *                      only a single file is output, then the processes will
 *                      execute sequentially, and each one will have to output
 *                      the file.
 */
process removeDuplicateMarkers {
  input:
  file duplicate_rsids
  val  filename         from params.plink_fname
  val  container        from params.dock_container
  val  data_path        from plink_data_path
  val  mountpoint       from params.dock_mpoint
  val  sexinfo          from params.sexinfo_command

  output:
  file 'qcplink_log'  into receiver
  file 'qcplink_log1' into receiver
  file 'qcplink_log2' into receiver
  file 'qcplink_log3' into receiver

  script:
  """
  if [[ -s duplicate_rsids ]]; then               
    # Copy the file to the mount path of the container
    cp duplicate_rsids $data_path/duplicate_rsids 

    # Remove duplicate ID's, running plinnk through the container
    docker run -v $data_path:/$mountpoint -w /$mountpoint       \
      $container plink1 --noweb --bfile $filename $sexinfo      \
      --exclude duplicate_rsids --make-bed --out                \
      qcplink >> qcplink_log
  else                                                          
    # There are no duplicate RSID's, so don;t specify exclude file
    docker run -v $data_path:/$mountpoint -w /$mountpoint       \
      $container plink1 --noweb --bfile $filename $sexinfo      \
      --make-bed --out qcplink >> qcplink_log
  fi

  # Create links for the outputs
  ln -s qcplink_log qcplink_log1 
  ln -s qcplink_log qcplink_log2
  ln -s qcplink_log qcplink_log3
  """
}

//---- Process 5 ------------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to identify individual discordant sex information.
 *
 * Inputs:
 * - qcplink_log  : The log file previously generated from running plink.
 * - filename     : The name of the plink input files wo extension
 * - container    : The name of the docker container to use
 * - data_path    : The path to the plink data
 * - mountpoint   : The mountpoint of the data in the container
 * - sexinfo      : The command to add to plink for sexinfo availability  
 * 
 * Outputs:
 * -sexstat_problems  : All sexinfo results which have problems.
 *
 * NOTES : The qcplink_log file is used as a 'start parameter', since when a 
 *         nextflow process uses the output of another process as input, the 
 *         process will only run once that input has become available. If we 
 *         did not do this, then the process would try and run concurrently at
 *         the start, which would not work since the input data would not be 
 *         ready.
 */
process identifyIndivDiscSexinfo {
  input:
  file qcplink_log      from receiver
  val  filename         from params.plink_fname
  val  container        from params.dock_container
  val  data_path        from plink_data_path
  val  mountpoint       from params.dock_mpoint
  val  sexinfo          from params.sexinfo_available

  output:
  file 'failed_sexcheck'

  script:
  """
  # Check that the input is available.
  if [[ -s qcplink_log ]]; then 
    echo 'Plink log received, can continue!'
  fi

  if [[ $sexinfo == 'true' ]]; then 
    # Generate all the sex info. Because this runs through docker the output
    # will be in the workdir of the container ($data_path).
    docker run -v $data_path:/$mountpoint -w /$mountpoint     \
      $container plink --bfile qcplink --check-sex            \
      --out sexstat 
  else 
    echo 'no sexinfo available for qcplink' > $data_path/sexstat.sexcheck
  fi

  # Check for all the "PROBLEM" sex information.
  if grep -Rn 'PROBLEM' $data_path/sexstat.sexcheck > failed_sexcheck; then
    echo 'Discordant sex info found'
  else                                                      
    echo 'No discordant sex info found'
  fi
  """
}

//---- Process 6 ------------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to calculate the sample missingness.
 *
 * Inputs:
 * - qcplink_log1   : The log file previously generated from running plink.
 * - filename       : The name of the plink input files wo extension
 * - container      : The name of the docker container to use
 * - data_path      : The path to the plink data
 * - mountpoint     : The mountpoint of the data in the container
 * - sexinfo        : The command to add to plink for sexinfo availability  
 * 
 * Outputs:
 * - qcplink_imiss* : Information for the missingness. Again multiple files so
 *                    that later processes start concurrently.
 *
 * NOTES : The qcplink_log file is used as a 'start parameter', since when a 
 *         nextflow process uses the output of another process as input, the 
 *         process will only run once that input has become available. If we 
 *         did not do this, then the process would try and run concurrently at
 *         the start, which would not work since the input data would not be 
 *         ready.
 */
process calculateSampleMissingness {
  input:
  file qcplink_log1  from receiver
  val  filename      from params.plink_fname
  val  container     from params.dock_container
  val  data_path     from plink_data_path
  val  mountpoint    from params.dock_mpoint
  val  sexinfo       from params.sexinfo_command

  output:
  file 'qcplink_missing'
  file 'qcplink_missing1'
  file 'qcplink_missing2'

  script:
  """
  if [[ -s qcplink_log1 ]]; then 
    echo 'Plink log received, can continue!'
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint     \
    $container plink --bfile qcplink $sexinfo --missing     \
    --out qcplink_missing

  # Create output links
  ln -s $data_path/qcplink_missing.imiss qcplink_missing
  ln -s $data_path/qcplink_missing.imiss qcplink_missing1
  ln -s $data_path/qcplink_missing.imiss qcplink_missing2
  """
}

//---- Process 7 ------------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to calculate the heterozygosity for the samples.
 *
 * Inputs:
 * - qcplink_log2 : The log file previously generated from running plink.
 * - filename     : The name of the plink input files wo extension
 * - container    : The name of the docker container to use
 * - data_path    : The path to the plink data
 * - mountpoint   : The mountpoint of the data in the container
 * - sexinfo      : The command to add to plink for sexinfo availability  
 * 
 * Outputs:
 * - qcplink_het* : Information about the heterozygosity. Again multiple 
 *                  so that multiple processes can start.
 *
 * NOTES : The qcplink_log file is used as a 'start parameter', since when a 
 *         nextflow process uses the output of another process as input, the 
 *         process will only run once that input has become available. If we 
 *         did not do this, then the process would try and run concurrently at
 *         the start, which would not work since the input data would not be 
 *         ready.
 */
process calculateSampleHetrozygosity {
  input:
  file qcplink_log2  from receiver
  val  filename      from params.plink_fname
  val  container     from params.dock_container
  val  data_path     from plink_data_path
  val  mountpoint    from params.dock_mpoint
  val  sexinfo       from params.sexinfo_command

  output:
  file 'qcplink_het'
  file 'qcplink_het1'

  script:
  """ 
  if [[ -s qcplink_log2 ]]; then 
    echo 'Plink log received, can continue!'
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint   \
    $container plink --bfile qcplink $sexinfo --het       \
    --out qcplink_het

  # Link the result in the data path to the output stream 
  ln -s $data_path/qcplink_het.het qcplink_het
  ln -s $data_path/qcplink_het.het qcplink_het1
  """
}

//---- Process 8 ------------------------------------------------------------//

script_path = Channel.fromPath(params.script_path, type : 'dir')

/* Process to generate plots for the missingness and heterozygosity.
 *
 * Inputs:
 * - qcplink_missing  : Link to the missingness data
 * - qcplink_het      : Link to the heterozygosity data
 * - script_dir       : Script directory to find scripts
 * - container        : Docker container to use
 * - mountpoint       : Mountpoint in container
 *
 * Outputs:
 * - qcplink_missing  : Results for the missingness.
 * - qcplink_het      : Results for the heterozygosity.
 * - failed_miss_het  : Failed results for the missingness and heterozygosity.
 */
process generateMissHetPlot {
  input:
  file qcplink_missing
  file qcplink_het     
  val  script_dir       from script_path
  val  container        from params.dock_container
  val  mountpoint       from params.dock_mpoint

  output:
  file 'qcplink_missing'
  file 'qcplink_het'
  file 'failed_miss_het'

  script:
  """
  # Delete link if it exists, probably from old process.
  if [[ -s $script_dir/qcplink_miss.imiss ]]; then 
    rm $script_dir/qcplink_miss.imiss
  fi

  # Delete link if it exists, probably from old process.
  if [[ -s $script_dir/qcplink_het.het ]]; then
    rm $script_dir/qcplink_het.het
  fi

  # Create link for the missingness file.
  if [[ -s qcplink_missing ]]; then
    ln qcplink_missing $script_dir/qcplink_miss.imiss
  fi

  # Create link for the heterozygosity file.
  if [[ -s qcplink_het ]]; then
    ln qcplink_het $script_dir/qcplink_het.het
  fi

  docker run -v $script_dir:/$mountpoint -w /$mountpoint  \
    $container Rscript miss_het_plot_qcplink.R

  # Create a link which is the output file
  ln $script_dir/fail_miss_het_qcplink.txt failed_miss_het
  """
}


//---- Process 9 ------------------------------------------------------------//

script_path = Channel.fromPath(params.script_path, type : 'dir')

/*
 * Process to find individuals with extreme missingness and heterozygosity
 * scores.
 *
 * Inputs:
 * - qcplink_missing1   : A link to the missingness file
 * - qcplink_het1       : A link to the heterozygosity file
 * - script_dir         : The scripts directory
 * - container          : The docker container to use
 * - mountpoint         : The mountpoint in the container
 * - cut_het_high       : The high values for heterozygosity
 * - cut_het_low        : The low values for heterozygosity
 * - cut_miss           : The missingness rate
 *
 * Outputs:
 * - None, the results are written to the scripts directory.
 */
process findIndivWithHighMissExtremeHet {
  input:
  file qcplink_missing1
  file qcplink_het1  
  val  script_dir       from script_path
  val  container        from params.dock_container
  val  mountpoint       from params.dock_mpoint
  val  cut_het_high     from params.cut_het_high 
  val  cut_het_low      from params.cut_het_low
  val  cut_miss         from params.cut_miss

  script:
  """
  # Check for missingness files in script dir -- 
  # should be there from the previous process.
  if [[ -s $script_dir/qcplink_miss.imiss ]]; then
    echo "Missingness file present in script dir"
  else
    # Create a link fot the missingness files 
    ln qcplink_missing1 $script_dir/qcplink_miss.imiss
  fi

  # Check for heterozygosity file in script dir -- 
  # should also be there from previous process
  if [[ -s $script_dir/qcplink_het.het ]]; then 
    echo "Heterozygosity file present in script dir"
  else
    # Create a link to the heterozygosity file.
    ln qcplink_het1 $script_dir/qcplink_het.het
  fi 

  docker run -v $script_dir:/$mountpoint -w /$mountpoint $container   \
    perl select_miss_het_qcplink.pl $cut_het_high $cut_het_low $cut_miss
  """
}

//---- Process 10 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to prune for IBD.
 * 
 * Inputs:
 * - qcplink_log3   : File specifying the the plink input files are ready.
 * - high_ld_file   : File specifying high ld regions to exclude
 * - container      : The docker container to use
 * - data_path      : The path where the data is, mounted onto container
 * - mountpoint     : The location on the container where data is mounted
 * - sexinfo        : Command to add based on sexinfo availability
 *
 * Outputs:
 * - qcplink_ibd_prune_status* : 
 *    The status of the process, when complete this file is created.
 *
 * NOTES : Plink data is written to the data_path directory.
 */
process pruneForIBD {
  input:
  file qcplink_log3 from receiver
  val  high_ld_file from params.high_ld_regions_fname
  val  container    from params.dock_container
  val  data_path    from plink_data_path
  val  mountpoint   from params.dock_mpoint
  val  sexinfo      from params.sexinfo_command

  output:
  file 'qcplink_ibd_prune_status'
  file 'qcplink_ibd_prune_status1'

  script:
  """
  if [[ -s qcplink_log3 ]]; then 
    echo 'Qcplink log received, pruning IBD'
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint                   \
    $container plink --bfile qcplink $sexinfo --exclude $high_ld_file     \
    --range --indep-pairwise 50 5 0.2 --out qcplink_ibd

  echo 'Complete' > qcplink_ibd_prune_status
  ln qcplink_ibd_prune_status qcplink_ibd_prune_status1
  """
}

//---- Process 11 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to calculate the IBD.
 *  
 * Inputs: 
 * - qc_plink_ibd_prune_status  : The status of the pruning process.
 * - container      : The docker container to use
 * - data_path      : The path where the data is, mounted onto container
 * - mountpoint     : The location on the container where data is mounted
 * - sexinfo        : Command to add based on sexinfo availability
 * 
 * Outputs:
 * - None : Output files are written to the data_path directory.
 */
process calculateIBD {
  input:
  file qcplink_ibd_prune_status
  val  container    from params.dock_container
  val  data_path    from plink_data_path
  val  mountpoint   from params.dock_mpoint
  val  sexinfo      from params.sexinfo_command

  script:
  """
  if [[ -s qcplink_ibd_prune_status ]]; then 
    echo "IBD Prune status file received, calculating IBD"
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint                       \
    $container plink --bfile qcplink $sexinfo --extract qcplink_ibd.prune.in  \
    --genome --out qcplink_ibd
  """
}

//---- Process 12 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to calculate the IBD with Min Pi Hat.
 *
 * - qc_plink_ibd_prune_status1  : The status of the pruning process.
 * - container      : The docker container to use
 * - data_path      : The path where the data is, mounted onto container
 * - mountpoint     : The location on the container where data is mounted
 * - sexinfo        : Command to add based on sexinfo availability
 * 
 * Outputs:
 * - qcplink_ind_min_004*   : The IBD results from plink.
 */
process calculateIBDMinPiHat {
  input:
  file qcplink_ibd_prune_status1
  val  container    from params.dock_container
  val  data_path    from plink_data_path
  val  mountpoint   from params.dock_mpoint
  val  sexinfo      from params.sexinfo_command

  output:
  file 'qcplink_ibd_min_004'
  file 'qcplink_ibd_min_0041'

  script:
  """
  if [[ -s qcplink_ibd_prune_status1 ]]; then
    echo "IBD prune status recieved"
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint                      \
    $container plink --bfile qcplink $sexinfo --extract qcplink_ibd.prune.in \
    --genome --min 0.04 --out qcplink_ibd_min_0_04

  ln $data_path/qcplink_ibd_min_0_04.genome qcplink_ibd_min_004
  ln $data_path/qcplink_ibd_min_0_04.genome qcplink_ibd_min_0041
  """
}

//---- Process 13 -----------------------------------------------------------//

/* Proces to sort the results from runnning IBD Min Pi hat.
 *
 * Inputs:
 * -qcplink_ibd_min_004   : The input file to sort.
 *
 * Outputs:
 * - qc_plink_ibd_min_004_sorted_pihat.txt  : The sorted results.
 */
process sortByPiHat {
  input:
  file qcplink_ibd_min_004

  output:
  file 'qcplink_ibd_min_0_04_sorted_pihat.txt'

  """
  sort -k10n qcplink_ibd_min_004 > qcplink_ibd_min_0_04_sorted_pihat.txt
  """
}

//---- Process 14 -----------------------------------------------------------//

script_path     = Channel.fromPath(params.script_path, type : 'dir')

/* Filters all the related individuals.
 *
 * Inputs:
 * - qcplink_missing2     : A link to the missingness file
 * - qcplink_ibd_min_0041 : A link to the ind file.
 * - script_dir           : The scripts directory
 * - container            : The docker container to use
 * - mountpoint           : The directory in the conmtainer to mount to.
 *
 * Outputs:
 * - None : Results are written to the scripts directory.
 */
process filterRelatedIndiv {
  input:
  file qcplink_missing2
  file qcplink_ibd_min_0041
  val  script_dir   from script_path
  val  container    from params.dock_container
  val  mountpoint   from params.dock_mpoint

  script:
  """
  # Check that there are no old links
  if [[ -s $script_dir/qcplink_missing.imiss ]]; then
    rm $script_dir/qcplink_missing.imiss
  fi

  if [[ -s $script_dir/qcplink_genome.genome ]]; then
    rm $script_dir/qcplink_genome.genome
  fi

  # Make a link for the missing file so that the file has .imiss ext
  if [[ -s qcplink_missing2 ]]; then 
    ln qcplink_missing2 $script_dir/qcplink_missing.imiss
  fi

  if [[ -s qcplink_ibd_min_0041 ]]; then
    ln qcplink_ibd_min_0041 $script_dir/qcplink_genome.genome
  fi

  docker run -v $script_dir:/$mountpoint -w /$mountpoint $container \
    perl run_IBD_QC_qcplink.pl qcplink_missing qcplink_genome
  """
}

//---- Process 15 -----------------------------------------------------------//

/* Process to join the failed individuals into a single file.
 * 
 * Inputs:
 * - failed_miss_het  : The failed missingness and heterozygosity results.
 * - failed_sexcheck  : The failed sex stat results.
 *
 * Ouputs:
 * - failed_qc_plink_inds : The combined failed results.
 */
process joinQcplinkFailedIndivIntoSingleFile {
  input:
  file failed_miss_het
  file failed_sexcheck 

  output:
  file 'failed_qc_plink_inds'

  script:
  """
  cat failed_sexcheck failed_miss_het | sort -k1 | \
    uniq > failed_qc_plink_inds
  """
}


//---- Process 16 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to remove all failed individuals.
 *
 * Inputs:
 * - failed_qc_plink_inds : The failed individuals to remove.
 * - script_dir           : The scripts directory
 * - container            : The docker container to use
 * - mountpoint           : The directory in the conmtainer to mount to.
 *
 * Outputs:
 * - qced_qcplink_status* : The output file indicating that the process is done.
 */
process removeQcPlinkFailedIndiv {
  input:
  file failed_qc_plink_inds
  val  container    from params.dock_container
  val  data_path    from plink_data_path
  val  mountpoint   from params.dock_mpoint
  val  sexinfo      from params.sexinfo_command

  output:
  file 'qced_qcplink_status1'
  file 'qced_qcplink_status2'
  file 'qced_qcplink_status3'
  file 'qced_qcplink_status4'
  file 'qced_qcplink_status5'
  file 'qced_qcplink_status6'

  script:
  """
  # Check if there is already a link, an remove it if there is
  if [[ -s $data_path/qcplink_failed_inds ]]; then
    rm -rf $data_path/qcplink_failed_inds
  fi

  # Make a link in the data_path directory for the failed indices
  if [[ -s failed_qc_plink_inds ]]; then 
    ln failed_qc_plink_inds $data_path/qcplink_failed_inds
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint           \
    $container plink --noweb --bfile qcplink $sexinfo --remove   \
    qcplink_failed_inds --make-bed --out qc_plink_clean_inds

  # Create output files
  echo 'Qced complete' > qced_qcplink_status1
  echo 'Qced complete' > qced_qcplink_status2
  echo 'Qced complete' > qced_qcplink_status3
  echo 'Qced complete' > qced_qcplink_status4
  echo 'Qced complete' > qced_qcplink_status5
  echo 'Qced complete' > qced_qcplink_status6
  """
}

//---- Process 17 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to calculate the Maf results.
 * 
 * Inputs:
 * - qced_qcplink_status1 : The file indicating input data is available.
 * - container            : The docker container to use
 * - data_path            : The path the input data.
 * - mountpoint           : The directory in the conmtainer to mount to.
 * - sexinfo              : The command to add for sexinfo.
 *
 * Outputs:
 * - qxced_clean_inds_freq  : The output results for Maf calculation.
 */
process calculateMaf {
  input:
  file qced_qcplink_status1
  val  container    from params.dock_container
  val  data_path    from plink_data_path
  val  mountpoint   from params.dock_mpoint
  val  sexinfo      from params.sexinfo_command

  output:
  file 'qced_clean_inds_freq'

  script:
  """
  if [[ -s qced_qcplink_status1 ]]; then
    echo "Input available, can calculate maf"
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint            \
    $container plink --noweb --bfile qc_plink_clean_inds $sexinfo  \
    --freq --out qc_plink_clean_inds_freq

  ln $data_path/qc_plink_clean_inds_freq.frq qced_clean_inds_freq
  """
}

//---- Process 18 -----------------------------------------------------------//

script_path     = Channel.fromPath(params.script_path, type : 'dir')

/* Process to generate the Maf plot.
 *
 * Inputs:
 * - qced_clean_inds_freq : A link to the input data from the calculateMaf 
 *                          process.
 * - container            : The docker container to use
 * - mountpoint           : The directory in the conmtainer to mount to.
 * - script_dir           : The directory where scripts are.
 *
 * Outputs:
 * - generate_maf_status  : The status of the process.
 */
process generateMafPlot {
  input:
  file qced_clean_inds_freq
  val  container    from params.dock_container
  val  mountpoint   from params.dock_mpoint
  val  script_dir   from script_path

  output:
  file 'generate_maf_status'

  script:
  """
  if [[ -s $script_dir/qced_clean_inds_freq.frq ]]; then 
    rm -rf $script_dir/qced_clean_inds_freq.frq
  fi

  if [[ -s qced_clean_inds_freq ]]; then 
    ln qced_clean_inds_freq $script_dir/qced_clean_inds_freq.frq
  fi

  docker run -v $script_dir:/$mountpoint -w /$mountpoint $container  \
    Rscript maf_plot_qcplink.R

  echo "Complete" > generate_maf_status
  """
}

//---- Process 19 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to calculate the snp missingness.
 *
 * Inputs:
 * - qced_qcplink_status2 : The file indicating input data is available.
 * - container            : The docker container to use
 * - data_path            : The path the input data.
 * - mountpoint           : The directory in the conmtainer to mount to.
 * - sexinfo              : The command to add for sexinfo.
 *
 * Outputs:
 * - qxced_clean_inds_missing  : The output results for missingness calculation
 */
process calculateSnpMissigness {
  input:
  file qced_qcplink_status2
  val  container    from params.dock_container
  val  data_path    from plink_data_path
  val  mountpoint   from params.dock_mpoint
  val  sexinfo      from params.sexinfo_command

  output:
  file 'qced_clean_inds_missing'

  script:
  """
  if [[ -s qced_qcplink_status2 ]]; then 
    echo "Input available, can calculate missingness"
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint              \
    $container plink --bfile qc_plink_clean_inds $sexinfo --missing  \
    --out qc_plink_clean_inds_missing

  ln $data_path/qc_plink_clean_inds_missing.lmiss qced_clean_inds_missing
  """
}

//---- Process 20 -----------------------------------------------------------//

script_path     = Channel.fromPath(params.script_path, type : 'dir')

/* Proces to generate a plot of the missingness results.
 *
 * Inputs:
 * - qced_clean_inds_missing : A link to the input data from the missingness
 *                             calculatio process.
 * - container               : The docker container to use
 * - mountpoint              : The directory in the conmtainer to mount to.
 * - script_dir              : The directory where scripts are.
 *
 * Outputs:
 * - generate_missingness_status : The status of the missingness plot 
 *                                 generation.
 */
process generateSnpMissingnessPlot {
  input:
  file qced_clean_inds_missing
  val  container    from params.dock_container
  val  mountpoint   from params.dock_mpoint
  val  script_dir   from script_path

  output: 
  file 'generate_snp_missingness_status'

  script:
  """
  if [[ -s $script_dir/clean_inds_qcplink_missing.lmiss ]]; then
    rm -rf $script_dir/clean_inds_qcplink_missing.lmiss
  fi

  if [[ -s qced_clean_inds_missing ]]; then 
    echo 'Finished calculating snp missingness, now plotting'
    ln qced_clean_inds_missing $script_dir/clean_inds_qcplink_missing.lmiss
  fi

  docker run -v $script_dir:/$mountpoint -w /$mountpoint $container  \
    Rscript snpmiss_plot_qcplink.R

  echo "Complete" > generate_snp_missingness_status
  """
}

//---- Process 21 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to calculate the snp differential missingness.
 *
 * Inputs:
 * - qced_qcplink_status3 : The file indicating input data is available.
 * - container            : The docker container to use
 * - data_path            : The path the input data.
 * - mountpoint           : The directory in the conmtainer to mount to.
 * - sexinfo              : The command to add for sexinfo.
 *
 * Outputs:
 * - qced_clean_inds_test_missing* : The results of the process.
 */
process calculateSnpDifferentialMissingness {
  input:
  file qced_qcplink_status3
  val  container    from params.dock_container
  val  data_path    from plink_data_path
  val  mountpoint   from params.dock_mpoint
  val  sexinfo      from params.sexinfo_command

  output:
  file 'qced_clean_inds_test_missing1'
  file 'qced_clean_inds_test_missing2'

  script:
  """
  if [[ -s qced_qcplink_status3 ]]; then 
    echo "Input available, can calculate differential missingness"
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint              \
    $container plink --bfile qc_plink_clean_inds $sexinfo --missing  \
    --out qc_plink_clean_inds_test_missing

  ln $data_path/qc_plink_clean_inds_missing.lmiss qced_clean_inds_test_missing1
  ln $data_path/qc_plink_clean_inds_missing.lmiss qced_clean_inds_test_missing2
  """
}  

//---- Process 22 -----------------------------------------------------------//

script_path     = Channel.fromPath(params.script_path, type : 'dir')

/* Process to generate a plot for the differential missngness.
 * 
 * Inputs: 
 * - qced-clean_inds_test_missing1 : The results to use to generate the plot.
 * - container                     : The docker container to use
 * - mountpoint                    : The directory in the conmtainer to mount to.
 * - script_dir                    : The directory where scripts are.
 *
 * Outputs:
 * - generate_diff_miss_status     : The status of the plot generation.
 *
 * NOTES : Specifying "ignore" for the error strategy allows the pipeline to 
 *         continue but still reports an error -- remove if this is not desired
 */
process generateDifferentialMissingnessPlot {
  errorStrategy 'ignore'

  input:
  file qced_clean_inds_test_missing1
  val  container    from params.dock_container
  val  mountpoint   from params.dock_mpoint
  val  script_dir   from script_path

  output:
  file 'generate_diff_miss_status'

  script:
  """
  if [[ -s $script_dir/clean_inds_qcplink_test_missing.missing ]]; then
    rm -rf $script_dir/clean_inds_qcplink_test_missing.missing
  fi

  if [[ -s qced_clean_inds_test_missing1 ]]; then 
    ln qced_clean_inds_test_missing1 \
      $script_dir/clean_inds_qcplink_test_missing.missing
  fi

  docker run -v $script_dir:/$mountpoint -w /$mountpoint $container  \
    Rscript diffmiss_plot_qcplink.R

  echo "Complete" > generate_diff_miss_status
  """
}

//---- Process 23 -----------------------------------------------------------//

script_path     = Channel.fromPath(params.script_path, type : 'dir')

/* Process to find snps with extreme differential missingness.
 *
 * Inputs:
 * - qced_clean_inds_test_staus2 : The file indicating input data is available.
 * - container                   : The docker container to use
 * - data_path                   : The path the input data.
 * - mountpoint                  : The directory in the conmtainer to mount to.
 * - sexinfo                     : The command to add for sexinfo.
 * - cut_diff_miss               : The value to use to evaluate diff miss.
 *
 * Outputs:
 * - failed_diffmiss : The failed results for the process.
 */
process findSnpExtremeDifferentialMissingness {
  input:
  file qced_clean_inds_test_missing2
  val  container                      from params.dock_container
  val  mountpoint                     from params.dock_mpoint
  val  script_dir                     from script_path
  val  cut_diff_miss                  from params.cut_diff_miss

  output:
  file 'failed_diffmiss'

  script:
  """ 
  if [[ -s $script_dir/clean_inds_qcplink_test_missing.missing ]]; then
    rm -rf $script_dir/clean_inds_qcplink_test_missing.missing
  else 
    ln qced_clean_inds_test_missing2 \
      $script_dir/clean_inds_qcplink_test_missing.missing
  fi 

  docker run -v $script_dir:/$mountpoint -w /$mountpoint $container  \
    perl select_diffmiss_qcplink.pl $cut_diff_miss

  ln $script_dir/fail_diffmiss_qcplink.txt failed_diffmiss
  """
}

//---- Process 24 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to find snps with extreme Hardy Weinburg deviations.
 * 
 * Inputs:
 * - qced_qcplink_status4 : The file indicating input data is available.
 * - container            : The docker container to use
 * - data_path            : The path the input data.
 * - mountpoint           : The directory in the conmtainer to mount to.
 * - sexinfo              : The command to add for sexinfo.
 *
 * Outputs:
 * - qced_clean_inds_hwe  : The results with extreme hwe deviations.
 */
process findSnpsExtremeHweDeviations {
  input:
  file qced_qcplink_status4
  val  container    from params.dock_container
  val  data_path    from plink_data_path
  val  mountpoint   from params.dock_mpoint
  val  sexinfo      from params.sexinfo_command

  output:
  file 'qced_clean_inds_hwe'

  script:
  """
  if [[ -s qced_qcplink_status4 ]]; then 
    echo "Input available, can find extreme hew variations"
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint              \
    $container plink --bfile qc_plink_clean_inds $sexinfo --hardy    \
    --out qc_plink_clean_inds_hwe

  ln $data_path/qc_plink_clean_inds_hwe.hwe qced_clean_inds_hwe
  """
}

//---- Process 25 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to find unaffected from HWE.
 *
 * Inputs:
 * - qced_clean_inds_hwe  : The hwe results from the previous process.
 * - data_path            : The path to all data.
 *
 * Outputs:
 * - qced_clean_inds_hweu : The results for those unaffected from HWE.
 */
process findUnaffectedForHwePlot {
  input:
  file qced_clean_inds_hwe
  val data_path    from plink_data_path
 
  output:
  file 'qced_clean_inds_hweu'

  script:
  """
  if [[ -s qced_clean_inds_hwe ]]; then 
    echo "Prev stage complete, continuing"
  fi

  head -1 $data_path/qc_plink_clean_inds_hwe.hwe          \
    > qc_plink_clean_inds_hweu.hwe |                      \
    grep 'UNAFF' $data_path/qc_plink_clean_inds_hwe.hwe   \
    >> qc_plink_clean_inds_hweu.hwe

  ln qc_plink_clean_inds_hweu.hwe qced_clean_inds_hweu
  """
}

//---- Process 26 -----------------------------------------------------------//

script_path     = Channel.fromPath(params.script_path, type : 'dir')

/* Process to generate a plot for the HWE results.
 *
 * Inputs:
 * qced_clean_inds_hweu : The result of those unaffected from HWE.
 * - container          : The docker container to use
 * - mountpoint         : The directory in the conmtainer to mount to.
 * - scipt_dir          : The directory where the scripts are.
 *
 * Outputs:
 * - generate_hwe_status : The status of the plot generation.
 */
process generateHwePlot {
  input:
  file  qced_clean_inds_hweu
  val  container    from params.dock_container
  val  mountpoint   from params.dock_mpoint
  val  script_dir   from script_path

  output:
  file 'generate_hwe_status'

  script:
  """
  if [[ -s $script_dir/clean_inds_qcplink_hweu.hwe ]]; then
    rm -rf $script_dir/clean_inds_qcplink_hweu.hwe
  fi

  if [[ -s qced_clean_inds_hweu ]]; then 
    ln qced_clean_inds_hweu \
      $script_dir/clean_inds_qcplink_hweu.hwe
  fi

  docker run -v $script_dir:/$mountpoint -w /$mountpoint $container  \
    Rscript hwe_plot_qcplink.R

  echo "Complete" > generate_hwe_status
  """
}

//---- Process 27 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to remove snps which failed QC.
 *
 * Inputs:
 * - qced_qcplink_status5 : The file indicating input data is available.
 * - failed_diffmiss      : The file with the failed diffmiss results.
 * - cut_maf              : Value for maf cut.
 * - cut_geno             : Value of genome cut.
 * - cut_hwe              : Value for hwe cut.
 * - container            : The docker container to use
 * - data_path            : The path the input data.
 * - mountpoint           : The directory in the conmtainer to mount to.
 * - sexinfo              : The command to add for sexinfo.
 *
 * Outputs:
 * - None : Results are written to the data_path directory.
 *
 * NOTES : Specifying "ignore" for the error strategy allows the pipeline to 
 *         continue but still reports an error -- remove if this is not desired
 */
process removeSnpsFailingQc {
  errorStrategy 'ignore'

  input:
  file qced_qcplink_status5
  file failed_diffmiss
  val  cut_maf              from params.cut_maf
  val  cut_geno             from params.cut_genome
  val  cut_hwe              from params.cut_hwe
  val  container            from params.dock_container
  val  data_path            from plink_data_path
  val  mountpoint           from params.dock_mpoint
  val  sexinfo              from params.sexinfo_command  

  script:
  """
  if [[ -s qced_qcplink_status5 ]]; then 
    echo "Input available, can find extreme hew variations"
  fi

  if [[ -s $data_path/failed_diffmiss.txt ]]; then 
    rm -rf $data_path/failed_diffmiss.txt
  fi

  if [[ -s failed_diffmiss ]]; then
    ln failed_diffmiss $data_path/failed_diffmiss.txt
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint           \
    $container plink --bfile qc_plink_clean_inds $sexinfo         \
    --maf $cut_maf --geno $cut_geno --exclude failed_diffmiss.txt  \
    --hwe $cut_hwe --make-bed --out qc_plink_cleaned
  """
}

//---- Process 28 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to find Xchr snps.
 *
 * Inputs:
 * - qced_qcplink_status6 : The file indicating input data is available.
 * - container            : The docker container to use
 * - data_path            : The path the input data.
 * - mountpoint           : The directory in the conmtainer to mount to.
 * - sexinfo              : The command to add for sexinfo.
 *
 * Outputs:
 * - xsnps_staus          : The status of the process.
 *
 * NOTES : Specifying "ignore" for the error strategy allows the pipeline to 
 *         continue but still reports an error -- remove if this is not desired
 */
process findXchrSnps {
  errorStrategy 'ignore'

  input:
  file qced_qcplink_status6
  val  container            from params.dock_container
  val  data_path            from plink_data_path
  val  mountpoint           from params.dock_mpoint
  val  sexinfo              from params.sexinfo_command  

  output:
  file "xsnps_status"

  script:
  """
  if [[ -s qced_qcplink_status6 ]]; then 
    echo "Input available, can find extreme hew variations"
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint       \
    $container plink --bfile qc_plink_clean_inds --chr 23     \
      --make-bed --out xsnps
  """
}

//---- Process 29 -----------------------------------------------------------//

plink_data_path = Channel.fromPath(params.plink_inputpath, type : 'dir')

/* Process to remove Xchr snps.
 *
 * Inputs:
 * - xsnps_status : The file indicating that the process can start.
 * - cut_maf      : Value for maf cut.
 * - cut_geno     : Value of genome cut.
 * - container    : The docker container to use
 * - data_path    : The path the input data.
 * - mountpoint   : The directory in the conmtainer to mount to.
 * - sexinfo      : The command to add for sexinfo.
 *
 * Outputs:
 * - None : Results are written to the data_path directory.
 */
process removeXchrSnps {
  input:
  file xsnps_status
  val  cut_maf      from params.cut_maf
  val  cut_geno     from params.cut_genome
  val  container    from params.dock_container
  val  data_path    from plink_data_path
  val  mountpoint   from params.dock_mpoint
  val  sexinfo      from params.sexinfo_command

  script:
  """
  if [[ -s xsnps_status ]]; then 
    echo "Have input data"
  fi

  docker run -v $data_path:/$mountpoint -w /$mountpoint       \
    $container plink --bfile qc_plink_clean_inds $sexinfo     \
    --maf $cut_maf --geno $cut_geno --exclude xsnps.bim       \
    --make-bed --out xsnps_removed
  """
}`
