#!/usr/bin/env nextflow

process MULTIQC {

    container "oras://community.wave.seqera.io/library/multiqc:1.35--562c547b518ebe20"

    input:
    path '*'

    output:
    path "multiqc_data", emit: data
    path "multiqc_report.html", emit: report

    script:
    """
    multiqc .
    """
}
