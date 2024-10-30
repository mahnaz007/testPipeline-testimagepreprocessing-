process CopyDatasetDescriptionRoot {
    // Tag the process for tracking
    tag "Copy dataset_description.json to root"
    label 'process_copy_root'

    input:
    tuple path(bidsDir), path(datasetDescription)

    // Output the root BIDS directory
    output:
    path "${bidsDir}", emit: bids_root

    script:
    """
    # Ensure the root BIDS directory exists
    mkdir -p ${bidsDir}

    # Copy dataset_description.json to the root BIDS directory
    cp ${datasetDescription} ${bidsDir}/dataset_description.json
    """
}
