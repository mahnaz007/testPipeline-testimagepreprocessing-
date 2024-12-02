process ConvertDicomToBIDS {
    label 'process_dicom_to_bids'

    input:
    val participantID
    val session_id
    path dicomDir
    path configFile
    val containerPath

    output:
    path "bids_output/**", emit: bids_files

    script:
    """
    mkdir -p bids_output
    apptainer run -e --containall \\
        -B ${dicomDir}:/dicoms:ro \\
        -B ${configFile}:/config.json:ro \\
        -B ./bids_output:/bids \\
        ${containerPath} \\
        --session ${session_id} \\
        -o /bids \\
        -d /dicoms \\
        -c /config.json \\
        -p ${participantID}
    """
}
