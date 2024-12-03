/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ConvertDicomToBIDS       } from '../modules/local/ConvertDicomToBIDS'
include { ValidateBIDS            } from '../modules/local/ValidateBIDS'
include { PyDeface                } from '../modules/local/PyDeface'
include { CopyDatasetDescription  } from '../modules/local/CopyDatasetDescription'
include { runMRIQC                } from '../modules/local/runMRIQC'
include { runFmriprep             } from '../modules/local/runFmriprep'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    // Initialize channels
    ch_dicom_dirs = Channel
        .fromPath("${params.inputDir}/*", type: 'dir')
        .map { dir ->
            def folderName = dir.name
            def match = (folderName =~ /IRTG\d+_(\d+)(_S\d+)?_b\d+/)

            if (match) {
                def participantID = match[0][1]
                def session_id = match[0][2] ? "ses-" + match[0][2].replace('_S', '').padLeft(2, '0') : "ses-01"

                if (params.participantList.isEmpty() || params.participantList.contains(participantID)) {
                    println "Processing participant: $participantID, session: $session_id"
                    return tuple(participantID, session_id, file(dir))
                }
            }
            return null
        }
        .filter { it != null }

    //
    // MODULE: Convert DICOM to BIDS
    //
    ch_bids_files = ch_dicom_dirs | ConvertDicomToBIDS

    //
    // MODULE: Validate BIDS
    //
    ch_bids_validation = ch_bids_files.collect()
    ch_bids_validation.map { true } | ValidateBIDS

    //
    // MODULE: PyDeface
    //
    ch_nii_files = ch_bids_files
        .flatMap { it }
        .filter { it.name.endsWith(".nii.gz") } // NIfTI files only
    ch_anat_files = ch_nii_files
        .filter { it.toString().contains("/anat/") && "fslval ${it} dim4".execute().text.trim() == "1" } // Anatomical files

    ch_defaced_files = ch_anat_files | PyDeface

    //
    // MODULE: Copy Dataset Description
    //
    ch_bids_dir_channel = ch_bids_files.map { file(params.bidsDir) }
    ch_description_channel = Channel.of(file(params.datasetDescription))

    ch_bids_dir_channel
        .combine(ch_description_channel)
        | CopyDatasetDescription

    //
    // MODULE: Run MRIQC
    //
    ch_participant_ids = ch_bids_files
        .map { bidsFile -> (bidsFile.name =~ /sub-(\d+)/)[0][1] }
        .distinct()

    ch_participant_ids | runMRIQC

    //
    // MODULE: Run fMRIPrep
    //
    ch_participant_ids | runFmriprep
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
