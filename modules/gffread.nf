#!/usr/bin/env nextflow

process GFF_TO_GTF {

    container "oras://community.wave.seqera.io/library/cufflinks:2.2.1--eb0a4691cd020167"

    input:
    path gff

    output:
    path "*.gtf", emit: gtf

    script:
    """
    gffread -E ${gff} -FOT --force-exons -o ${gff.baseName}.gtf
    """
}
