workflow {
    // Include the module
    include { ConvertDicomToBIDS } from './modules/local/convert_dicom_to_bids'

    // Channel to get DICOM directories
    dicomDirChannel = Channel
        .fromPath("${params.inputDir}/*", type: 'dir')
        .map { dir -> 
            def folderName = dir.name
            def match = (folderName =~ /IRTG\d+_(\d+)(_S\d+)?_b\d+/)

            if (match) {
                def participantID = match[0][1]
                def session_id = match[0][2] ? "ses-" + match[0][2].replace('_S', '').padLeft(2, '0') : "ses-01"
                return tuple(participantID, session_id, file(dir))
            }
            return null
        }
        .filter { it != null }

    // Call the ConvertDicomToBIDS process
    bidsFiles = dicomDirChannel.map { tuple ->
        ConvertDicomToBIDS(
            participantID: tuple[0],
            session_id: tuple[1],
            dicomDir: tuple[2],
            configFile: file(params.configFile),
            containerPath: params.containerPath_dcm2bids
        )
    }
}
