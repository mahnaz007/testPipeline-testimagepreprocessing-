process CONVERT_DICOM_TO_BIDS {
    tag "Participant: ${participantID}, Session: ${session_id}"
    label 'process_dicom_to_bids'

    container "${params.containerPath_dcm2bids}"

    publishDir "${params.bidsDir}", mode: 'copy'

    input:
    tuple val(participantID), val(session_id), path(dicomDir)
    path configFile

    output:
    path "bids_output/**", emit: bids_files
    path "versions.yml"  , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p bids_output

    apptainer run -e --containall \\
        -B ${dicomDir}:/dicoms:ro \\
        -B ${configFile}:/config.json:ro \\
        -B ./bids_output:/bids \\
        ${params.containerPath_dcm2bids} \\
        --session ${session_id} \\
        -o /bids \\
        -d /dicoms \\
        -c /config.json \\
        -p ${participantID} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dcm2bids: \$(apptainer exec ${params.containerPath_dcm2bids} dcm2bids --version | sed 's/dcm2bids //g')
    END_VERSIONS
    """
}
