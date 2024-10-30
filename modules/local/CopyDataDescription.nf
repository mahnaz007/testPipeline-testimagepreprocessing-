process CopyDatasetDescription {
    // Tag process for easy tracking
    tag "Copy dataset_description.json"
    label 'process_copy'

    input:
    tuple path(bidsDir), path(datasetDescription)

    // Output directory setup for BIDS output
    output:
    path "${bidsDir}/bids_output", emit: bids_output

    script:
    """
    # Create BIDS output directory if it doesn't exist
    mkdir -p ${bidsDir}/bids_output

    # Copy dataset_description.json to the BIDS output directory
    cp ${datasetDescription} ${bidsDir}/bids_output/dataset_description.json
    """
}
