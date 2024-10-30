process PyDeface {
    // Tag to identify the process by input file name
    tag "Defacing: ${niiFile.name}"
    label 'process_pydeface'

    // Specify container path for Singularity/Apptainer
    container "${params.containerPath_pydeface}"

    // Copy results to the defaced output directory
    publishDir "${params.defacedOutputDir}", mode: 'copy'

    input:
    path niiFile

    output:
    path "defaced_${niiFile.simpleName}.nii.gz", emit: defaced_nii
    path "versions.yml", emit: versions

    script:
    """
    # Define input and output filenames
    input_file="${niiFile.getName()}"
    output_file="defaced_${niiFile.simpleName}.nii.gz"
    input_dir="\$(dirname '${niiFile}')"

    # Run PyDeface within the Apptainer container
    apptainer run --bind "\${input_dir}:/input" \\
        ${params.containerPath_pydeface} \\
        pydeface /input/"\${input_file}" --outfile "\${output_file}"

    # Record version information for reproducibility
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pydeface: \$(apptainer exec ${params.containerPath_pydeface} pydeface --version | grep -oP '[0-9]+(\\.[0-9]+)+')
    END_VERSIONS
    """
}
