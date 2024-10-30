#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/testimagepreprocessing
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/mahnaz007/testPipeline-testimagepreprocessing
    Website: https://nf-co.re/testimagepreprocessing
    Slack  : https://nfcore.slack.com/channels/testimagepreprocessing
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / PROCESSES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ConvertDicomToBIDS           } from './modules/local/ConvertDicomToBIDS.nf'
include { ValidateBIDS                 } from './modules/local/ValidateBIDS.nf'
include { PyDeface                     } from './modules/local/PyDeface.nf'
include { CopyDatasetDescription        } from './modules/local/CopyDatasetDescription.nf'
include { CopyDatasetDescriptionRoot    } from './modules/local/CopyDatasetDescriptionRoot.nf'
include { runMRIQC                     } from './modules/local/runMRIQC.nf'
include { runFmriprep                  } from './modules/local/runFmriprep.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// WORKFLOW: Main image preprocessing pipeline
workflow NFCORE_IMAGEPREPROCESSING {

    take:
    dicomDirChannel

    main:

    //
    // STEP 1: Convert DICOM to BIDS format
    //
    convertedBIDS = ConvertDicomToBIDS(dicomDirChannel)

    //
    // STEP 2: Validate the BIDS output structure
    //
    validation = ValidateBIDS(convertedBIDS)

    //
    // STEP 3: Perform defacing on anatomical NIfTI files
    //
    anatFiles = convertedBIDS.flatMap { it }.filter { it.name.endsWith(".nii.gz") && it.toString().contains("/anat/") }
    defacedFiles = PyDeface(anatFiles)

    //
    // STEP 4: Copy dataset description to BIDS output
    //
    CopyDatasetDescription(convertedBIDS, params.datasetDescription)
    CopyDatasetDescriptionRoot(convertedBIDS, params.datasetDescription)

    //
    // STEP 5: Run MRIQC on defaced BIDS data
    //
    mriqcResults = runMRIQC(defacedFiles)

    //
    // STEP 6: Run fMRIPrep on MRIQC outputs
    //
    fmriPrepResults = runFmriprep(mriqcResults)
    
    emit:
    output_dir = fmriPrepResults
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:

    //
    // Define input DICOM channel from input directory
    //
    dicomDirChannel = Channel.fromPath("${params.inputDir}/*", type: 'dir')
        .map { dir ->
            def folderName = dir.name
            def match = (folderName =~ /IRTG\\d+_(\\d+)(_S\\d+)?_b\\d+/)
            if (match) {
                def participantID = match[0][1]
                def session_id = match[0][2] ? match[0][2].replace('_S', 'ses-') : "ses-01"
                return tuple(participantID, session_id, file(dir))
            }
            return null
        }
        .filter { it != null }

    //
    // RUN MAIN WORKFLOW
    //
    NFCORE_IMAGEPREPROCESSING(dicomDirChannel)
}

