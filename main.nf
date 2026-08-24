#!/usr/bin/env nextflow

// INCLUDE modules
// If you need to edit the calls to any of the programs, edit the modules.

include { FASTQC } from './modules/fastqc.nf'
include { TRIMGALORE } from './modules/trimgalore.nf'
include { STAR_INDEX } from './modules/star.nf'
include { STAR_ALIGN } from './modules/star.nf'
include { GFF_TO_GTF } from './modules/gffread.nf'
include { TELESCOPE_ASSIGN } from './modules/telescope.nf'
include { TELESCOPE_MERGE } from './modules/telescope.nf'
include { MULTIQC } from './modules/multiqc.nf'

/*
 * Pipeline Parameters
 * Pass values with --PARAM VALUE (e.g. "--genome path/to/genome.fa")
 * Options are passed to nextflow itself with -OPTION (e.g. "-resume")
 */

params {

    // input samplesheet with header. Required columns are "sample_id", "fastq_1", and "fastq_2"
    input: Path

    // genome fasta
    genome: Path

    // number of cpus to use
    ncpus: String = '1'

    // saindexnbases to use for STAR. Decrease for smaller genomes = min(14, log2(GenomeLength)/2 - 1). 10 is a conservative default.
    saindexnbases: String = '10'

    // other parameters to pass to STAR. Defaults enable multiple mapping; make sure you include these if you want to capture TEs.
    star_params: String = '--winAnchorMultimapNmax 200 --outFilterMultimapNmax 100'

    // GFF annotation output by EarlGrey. Found in summaryFiles and will have a name of the form *_filteredRepeats.gff
    te_anno: Path
}

workflow {

    main:
    // create input channel from samplesheet csv
    read_ch = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> [row.sample_id, file(row.fastq_1), file(row.fastq_2)] }
        .view() //print to debug TODO remove this

    // QC: Create FastQC report on input reads
    FASTQC(
        read_ch
    )

    // TRIMMING: Automatically detect and trim adaptors
    // QC: Create post-trimming QC report
    TRIMGALORE(
        read_ch,
        params.ncpus
    )

    // ALIGNMENT: Create genome index for alignment with STAR.
    // If this step fails or takes too long, you may need to adjust params.saindexnbases.
    STAR_INDEX(
        params.genome,
        params.ncpus,
        params.saindexnbases
    )

    // ALIGNMENT: Align reads to genome index with STAR.
    // Default for --star_params includes sensible defaults for multiple-mapping parameters; consider tweaking these for better results.
    STAR_ALIGN(
        TRIMGALORE.out.trimmed,
        STAR_INDEX.out,
        params.ncpus,
        params.star_params
    )

    // QUANTIFICATION: Convert the GFF3 annotation from EarlGrey into a GTF annotation for telescope
    GFF_TO_GTF(
        params.te_anno
    )

    // QUANTIFICATION: Reassign ambiguous reads to specific loci and quantify reads mapping to each TE in the annotation
    TELESCOPE_ASSIGN(
        STAR_ALIGN.out.bam,
        GFF_TO_GTF.out.gtf
    )

    // QUANTIFICATION: Merge the read counts from each sample into a final count matrix
    TELESCOPE_MERGE(
        TELESCOPE_ASSIGN.out.report.collect()
    )

    // QC: Collect QC files for MultiQC report
    multiqc_files_ch = channel.empty().mix(
        FASTQC.out.zip,
        FASTQC.out.html,
        TRIMGALORE.out.trimming_reports,
        TRIMGALORE.out.fastqc_reports_1,
        TRIMGALORE.out.fastqc_reports_2,
        STAR_ALIGN.out.logFinal
    ).collect()

    // QC: Create MultiQC report from collected QC files
    MULTIQC(
        multiqc_files_ch
    )

    // Publish results to output
    publish:
    QC_FASTQC_zip = FASTQC.out.zip
    QC_FASTQC_html = FASTQC.out.html
    QC_TRIMGALORE_trimming_reports = TRIMGALORE.out.trimming_reports
    QC_TRIMGALORE_fastqc_reports_1 = TRIMGALORE.out.fastqc_reports_1
    QC_TRIMGALORE_fastqc_reports_2 = TRIMGALORE.out.fastqc_reports_2
    QC_MULTIQC_data = MULTIQC.out.data
    QC_MULTIQC_report = MULTIQC.out.report
    TRIMMING_TRIMGALORE_trimmed = TRIMGALORE.out.trimmed
    ALIGNMENT_STAR_ALIGN_bam = STAR_ALIGN.out.bam
    ALIGNMENT_STAR_ALIGN_logFinal = STAR_ALIGN.out.logFinal
    QUANTIFICATION_TELESCOPE_ASSIGN_report = TELESCOPE_ASSIGN.out.report
    QUANTIFICATION_TELESCOPE_ASSIGN_checkpoint = TELESCOPE_ASSIGN.out.checkpoint
    QUANTIFICATION_TELESCOPE_MERGE_merged_report = TELESCOPE_MERGE.out.merged_report
}

output {
    QC_FASTQC_zip {
        path '00_QC/fastqc'
    }
    QC_FASTQC_html {
        path '00_QC/fastqc'
    }
    QC_TRIMGALORE_trimming_reports {
        path '00_QC/trimgalore'
    }
    QC_TRIMGALORE_fastqc_reports_1 {
        path '00_QC/trimgalore'
    }
    QC_TRIMGALORE_fastqc_reports_2 {
        path '00_QC/trimgalore'
    }
    QC_MULTIQC_data {
        path '00_QC'
    }
    QC_MULTIQC_report {
        path '00_QC'
    }
    TRIMMING_TRIMGALORE_trimmed {
        path '01_TRIMMING'
    }
    ALIGNMENT_STAR_ALIGN_bam {
        path '02_ALIGNMENT'
    }
    ALIGNMENT_STAR_ALIGN_logFinal {
        path '02_ALIGNMENT'
    }
    QUANTIFICATION_TELESCOPE_ASSIGN_checkpoint {
        path '03_QUANTIFICATION/checkpoints'
    }
    QUANTIFICATION_TELESCOPE_ASSIGN_report {
        path '03_QUANTIFICATION/reports'
    }
    QUANTIFICATION_TELESCOPE_MERGE_merged_report {
        path '03_QUANTIFICATION'
    }
}
