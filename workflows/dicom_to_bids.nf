include { CONVERT_DICOM_TO_BIDS } from '../modules/local/convert_dicom_to_bids'

workflow DICOM_TO_BIDS {
    take:
    dicom_ch // channel: [ val(meta), path(dicom_dir) ]
    config_file // path: config.json

    main:
    CONVERT_DICOM_TO_BIDS ( dicom_ch, config_file )

    emit:
    bids_files = CONVERT_DICOM_TO_BIDS.out.bids_files
    versions   = CONVERT_DICOM_TO_BIDS.out.versions
}
