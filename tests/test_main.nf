workflow {
    ConvertDicomToBIDS(
        participantID: '001',
        session_id: 'ses-01',
        dicomDir: file('./tests/data/dicoms'),
        configFile: file('./tests/data/config.json'),
        containerPath: './tests/data/dcm2bids.sif'
    )
}
