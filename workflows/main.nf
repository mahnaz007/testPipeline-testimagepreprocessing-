#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Import local modules
include { ConvertDicomToBIDS } from './modules/local/ConvertDicomToBIDS.nf'
include { ValidateBIDS } from './modules/local/ValidateBIDS.nf'
include { PyDeface } from './modules/local/PyDeface.nf'
include { CopyDatasetDescription } from './modules/local/CopyDatasetDescription.nf'
include { runMRIQC } from './modules/local/runMRIQC.nf'
include { runFmriprep } from './modules/local/runFmriprep.nf'

// Define workflow
workflow {
    // Step 1: Prepare DICOM directory channel
    dicomDirChannel = Channel
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

    // Step 2: Convert DICOM to BIDS
    bidsFiles = dicomDirChannel | ConvertDicomToBIDS

    // Step 3: Validate BIDS output
    validateTrigger = bidsFiles.collect()
    validateTrigger.map { true } | ValidateBIDS

    // Step 4: Run PyDeface on NIfTI files
    niiFiles = bidsFiles.flatMap { it }.filter { it.name.endsWith(".nii.gz") }
    anatFiles = niiFiles.filter { it.toString().contains("/anat/") && "fslval ${it} dim4".execute().text.trim() == "1" }
    defacedFiles = anatFiles | PyDeface

    // Step 5: Copy dataset_description.json
    bidsDirChannel = bidsFiles.map { file(params.bidsDir) }
    descriptionChannel = Channel.of(file(params.datasetDescription))
    bidsDirChannel.combine(descriptionChannel) | CopyDatasetDescription

    // Step 6: Run MRIQC
    participantIDs = bidsFiles
        .map { bidsFile -> (bidsFile.name =~ /sub-(\d+)/)[0][1] }
        .distinct()
    participantIDs | runMRIQC

    // Step 7: Run fMRIPrep
    participantIDs | runFmriprep
}
