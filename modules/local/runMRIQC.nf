process runMRIQC {
    // Use specified container path for MRIQC
    container "${params.containerPath_mriqc}"

    // Define resource requirements
    cpus 4
    memory '8 GB'

    // Error handling and retries
    errorStrategy 'ignore'
    maxRetries 2

    // Tag process with participant ID for tracking
    tag "MRIQC: Participant ${participant}"
    label 'process_mriqc'

    // Directory to publish output with overwrite allowed
    publishDir "${params.mriqcOutputDir}/sub-${participant}", mode: 'copy', overwrite: true

    input:
    val participant

    // Define output paths for MRIQC results
    output:
    path "reports/*.html", emit: reports  // MRIQC HTML reports
    path "metrics/*.json", emit: metrics  // JSON metrics
    path "figures/*", emit: figures       // MRIQC figures
    path "mriqc_log_${participant}.txt", emit: logs

    script:
    """
    # Create output directory for participant
    mkdir -p ${params.mriqcOutputDir}/sub-${participant}

    # Set up Singularity bind paths for BIDS input, output, and work directories
    export SINGULARITY_BINDPATH="${params.bidsDir}/bids_output,${params.mriqcOutputDir},${params.workdir}"

    # Run MRIQC with specified parameters in Singularity container
    singularity exec --bind ${params.bidsDir}/bids_output:/bidsdir \\
        --bind ${params.mriqcOutputDir}:/outdir \\
        --bind ${params.workdir}:/workdir \\
        ${params.containerPath_mriqc} \\
        mriqc /bidsdir /outdir participant \\
        --participant_label ${participant} \\
        --nprocs ${task.cpus} \\
        --omp-nthreads ${task.cpus} \\
        --mem_gb 8 \\
        --no-sub \\
        -vvv \\
        --verbose-reports \\
        --work-dir /workdir > ${params.mriqcOutputDir}/sub-${participant}/mriqc_log_${participant}.txt 2>&1

    # Capture the process's success or failure in a log
    if [ \$? -ne 0 ]; then
        echo "MRIQC failed for participant ${participant}" >> ${params.mriqcOutputDir}/mriqc_crash_log.txt
    fi
    """
}
