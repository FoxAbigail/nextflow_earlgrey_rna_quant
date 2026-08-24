#!/usr/bin/env nextflow

process FASTQC {

    container "oras://community.wave.seqera.io/library/fastqc:0.12.1--a74c1c66ecc610d5"

    input:
    tuple val(sampleName), path(read1), path(read2)

    output:
    path "*_fastqc.zip", emit: zip
    path "*_fastqc.html", emit: html

    script:
    """
    fastqc ${read1} ${read2}
    """
}
