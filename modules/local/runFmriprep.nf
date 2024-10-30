process runFmriprep {
    // Set resource limits for fMRIPrep
    time '48h'
    cpus 8
    memory '32 GB'

    // Use specified container for fMRIPrep
    container "${params.containerPath_fmriprep}"

    // Tag for tracking by participant ID
    tag "fMRIPrep: Participant ${participantID}"
    label 'process_fmriprep'

    input:
    val participantID

    // Output directory setup
    publishDir "${params.fmriprepOutputDir}/sub-${participantID}", mode: 'copy', overwrite: true

    script:
    """
    # Run fMRIPrep within the Singularity container
    singularity run --cleanenv \\
        --bind ${params.workdir}:/workdir \\
        ${params.containerPath_fmriprep} \\
        ${params.bidsDir} \\
        ${params.fmriprepOutputDir} \\
        participant \\
        --participant-label ${participantID} \\
        --fs-license-file ${params.FS_LICENSE} \\
        --skip_bids_validation \\
        --nprocs ${task.cpus} \\
        --omp-nthreads 1 \\
        --mem_mb $(( ${task.memory.toMega()} )) \\
        --random-seed 13 \\
        --skull-strip-fixed-seed \\
        --work-dir /workdir > ${params.fmriprepOutputDir}/sub-${participantID}/fmriprep_log_${participantID}.txt 2>&1

    # Check if fMRIPrep completed successfully and log any crashes
    if [ \$? -ne 0 ]; then
        echo "fMRIPrep crashed for participant ${participantID}" >> ${params.fmriprepOutputDir}/fmriprep_crash_log.txt
    fi
    """
}
