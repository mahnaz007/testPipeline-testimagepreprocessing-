process ValidateBIDS {
    // Tag for process tracking
    tag "BIDS Validation"

    // Assign a label for resource allocation
    label 'process_bids_validation'

    // Specify the container path for Singularity or Docker
    container "${params.singularity_image}"

    input:
    val trigger  // Trigger input to ensure the process waits for ConvertDicomToBIDS

    output:
    path "${params.bidsValidatorLogs}/validation_log.txt", emit: logs
    path "versions.yml", emit: versions

    // Define error strategy for robustness
    errorStrategy 'ignore'

    script:
    """
    # Create the logs directory if it doesn't exist
    mkdir -p ${params.bidsValidatorLogs}

    # Run BIDS validator and save output to log file
    echo "Running BIDS validation..."
    singularity run --cleanenv \\
        ${params.singularity_image} \\
        ${params.inputDirValidationLog} \\
        --verbose 2>&1 | tee ${params.bidsValidatorLogs}/validation_log.txt

    # Record version information for reproducibility
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bids-validator: \$(singularity exec ${params.singularity_image} bids-validator --version)
    END_VERSIONS

    echo "Validation log saved at ${params.bidsValidatorLogs}/validation_log.txt"
    """
}
