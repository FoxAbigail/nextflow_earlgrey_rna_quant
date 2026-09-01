#!/usr/bin/env nextflow

process TRIMGALORE {

    container "oras://community.wave.seqera.io/library/trim-galore:2.3.0--a56e49e832976df4"
    cpus { threads }

    input:
    tuple val(sampleName), path(read1), path(read2)
    val threads

    output:
    tuple val(sampleName), path("*val_1.fq.gz"), path("*val_2.fq.gz"), emit: trimmed
    path "*trimming_report.json", emit: trimming_reports
    path "*val_1_fastqc.{zip,html}", emit: fastqc_reports_1
    path "*val_2_fastqc.{zip,html}", emit: fastqc_reports_2

    script:
    """
    trim_galore --cores ${task.cpus} --fastqc --paired ${read1} ${read2}
    """
}
