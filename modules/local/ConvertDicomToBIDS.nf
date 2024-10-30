process ConvertDicomToBIDS {
    // Tag process using participant ID and session for clarity in logs
    tag "Participant: ${participantID}, Session: ${session_id}"
    label 'process_dicom_to_bids'

    // Specify container path for Apptainer
    container "${params.containerPath_dcm2bids}"

    publishDir "${params.bidsDir}", mode: 'copy'

    input:
    tuple val(participantID), val(session_id), path(dicomDir)

    output:
    path "bids_output/**", emit: bids_files
    path "versions.yml", emit: versions

    script:
    """
    # Create output directory for BIDS files
    mkdir -p bids_output

    # Run the dcm2bids command using Apptainer
    apptainer run -e --containall \\
        -B ${dicomDir}:/dicoms:ro \\
        -B ${params.configFile}:/config.json:ro \\
        -B ./bids_output:/bids \\
        ${params.containerPath_dcm2bids} \\
        --session ${session_id} \\
        -o /bids \\
        -d /dicoms \\
        -c /config.json \\
        -p ${participantID} 

    # Capture the version information for reproducibility
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dcm2bids: \$(apptainer exec ${params.containerPath_dcm2bids} dcm2bids --version | sed 's/dcm2bids //g')
    END_VERSIONS
    """
}
