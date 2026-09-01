#!/usr/bin/env nextflow

process STAR_INDEX {

    container "oras://community.wave.seqera.io/library/star_gzip:0e6cfd855da0cf8a"
    cpus { threads }

    input:
    path genome
    val threads
    val saindexnbases

    output:
    path "star_index"

    script:
    """
    mkdir star_index
    STAR --runMode genomeGenerate \\
        --genomeDir ./star_index \\
        --genomeFastaFiles ${genome} \\
        --runThreadN ${task.cpus} \\
        --genomeSAindexNbases ${saindexnbases}
    """
}

process STAR_ALIGN {

    container "oras://community.wave.seqera.io/library/star_gzip:0e6cfd855da0cf8a"
    cpus { threads }

    input:
    tuple val(sampleName), path(read1), path(read2)
    path index
    val threads
    val other_opts

    output:
    path "${sampleName}_Log.final.out", emit: logFinal
    tuple val(sampleName), path("${sampleName}_Aligned.out.bam"), emit: bam

    script:
    """
    STAR --runMode alignReads \\
        --outFileNamePrefix ${sampleName}_ \\
        --readFilesIn ${read1} ${read2} \\
        --genomeDir ${index} \\
        --runThreadN ${task.cpus} \\
        --readFilesCommand zcat \\
        --outSAMtype BAM Unsorted \\
        ${other_opts}
    """
}
