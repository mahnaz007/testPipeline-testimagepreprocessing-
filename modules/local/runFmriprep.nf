// File: modules/local/run_fmriprep.nf
process runFmriprep {
    // Use NF-core schema to inherit resources
    label 'process_fmriprep'

    input:
    val participantID
    path bidsDir
    path outputDir
    path fsLicense
    path workDir
    val containerPath

    output:
    path "${outputDir}/sub-${participantID}", mode: 'copy'

    script:
    """
    singularity run --cleanenv \\
        --bind ${workDir}:/workdir \\
        ${containerPath} \\
        ${bidsDir} \\
        ${outputDir} \\
        participant \\
        --participant-label ${participantID} \\
        --fs-license-file ${fsLicense} \\
        --skip_bids_validation \\
        --nprocs ${task.cpus} \\
        --omp-nthreads 1 \\
        --mem_mb $(( ${task.memory.toMega()} )) \\
        --random-seed 13 \\
        --skull-strip-fixed-seed \\
        --work-dir /workdir > ${outputDir}/sub-${participantID}/fmriprep_log_${participantID}.txt 2>&1

    if [ \$? -ne 0 ]; then
        echo "fMRIPrep crashed for participant ${participantID}" >> ${outputDir}/fmriprep_crash_log.txt
    fi
    """
}
