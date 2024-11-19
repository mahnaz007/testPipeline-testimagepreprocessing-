workflow {
    // کانال ورودی
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

    // مراحل پردازش
    bidsFiles = dicomDirChannel | ConvertDicomToBIDS
    validatedFiles = bidsFiles.collect().map { true } | ValidateBIDS
}
