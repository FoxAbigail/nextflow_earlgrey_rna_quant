#!/usr/bin/env nextflow

process TELESCOPE_ASSIGN {

    container "oras://community.wave.seqera.io/library/telescope:1.0.4.1--da268e5a6722c6bd"

    input:
    tuple val(sampleName), path(bam)
    path anno

    output:
    path "*-checkpoint.npz", emit: checkpoint
    path "*-telescope_report.tsv", emit: report

    script:
    """
    telescope assign \\
        --attribute transcript_id \\
        --outdir ./ \\
        --exp_tag ${sampleName} \\
        ${bam} \\
        ${anno}
    """
}


process TELESCOPE_MERGE {

    // process to merge final counts from all telescope report TSVs
    container "oras://community.wave.seqera.io/library/sed_tsv-utils:5a6eebaf3674c378"

    input:
    path '*'

    output: path "telescope-report-merged.tsv", emit: merged_report

    script:
    """
    ## Trim the first line so that TSVs start with the header
    for infile in *-telescope_report.tsv; do
        tail -n +2 \$infile > \$(basename \$infile .tsv).trimmed.tsv
    done

    ## Make rows with first column, ensuring we have all possible values represented
    tsv-select -H -f 1 *.trimmed.tsv | tsv-uniq > out.tsv

    ## Merge all final_counts columns, ensuring that any transcript_ids not present in a report are filled in with 0 for that sample
    for trimmedfile in *.trimmed.tsv; do
        tsv-join -H --filter-file \$trimmedfile \\
            --key-fields 1 \\
            --append-fields final_count \\
            --prefix \$(basename \$trimmedfile -telescope_report.trimmed.tsv) \\
            --write-all '0' \\
            out.tsv > tmp.tsv
        mv tmp.tsv out.tsv
    done

    ## Remove "final_count" to make colnames match samplename prefix
    sed 's/final_count//g' out.tsv > telescope-report-merged.tsv
    """
}
