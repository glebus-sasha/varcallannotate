#!/usr/bin/env nextflow

// Include workflows and modules
include { QC_TRIM       } from './workflows/qc_trim'
include { ALIGN_VARCALL } from './workflows/align_varcall'
include { MULTIQC       } from './modules/multiqc'

// Logging pipeline information
log.info """\
\033[0;36m  ==========================================  \033[0m
\033[0;34m       v a r c a l l a n n o t a t e          \033[0m
\033[0;36m  ==========================================  \033[0m
    """

// reference and reads channels
reference = Channel.fromPath("${params.reference}").collect()
input_fastqs = Channel.fromFilePairs(["${params.reads}/*[rR]{1,2}*.*{fastq,fq}*", 
                                      "${params.reads}/*_{1,2}.{fastq,fq}*"], flat: true)
// index channels
bwaidx = Channel.fromPath("${params.bwaidx}/*").collect()
faidx = Channel.fromPath("${params.faidx}/*.fai").collect()

workflow {
    QC_TRIM(
        input_fastqs
    )
    QC_TRIM.out.trimmed_reads.view()
        ALIGN_VARCALL(
        reference,
        QC_TRIM.out.trimmed_reads,
        bwaidx,
        faidx
    )
}



