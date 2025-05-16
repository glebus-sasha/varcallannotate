#!/usr/bin/env nextflow

// Include workflows and modules
include { QC_TRIM              } from './workflows/qc_trim'
include { ALIGN_VARCALL        } from './workflows/align_varcall'
include { MOSDEPTH             } from './modules/mosdepth'
include { ON_TARGET_RATIO      } from './modules/local/on_target_ratio'
include { VEP                  } from './modules/vep'
include { MULTIQC              } from './modules/multiqc'

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

vep_cache = Channel.fromPath("${params.vep_cache}").collect()
bed       = Channel.fromPath("${params.bed}").collect()

workflow {
    QC_TRIM(
        input_fastqs
    )
    ALIGN_VARCALL(
        reference,
        QC_TRIM.out.trimmed_reads,
        bwaidx,
        faidx
    )
    MOSDEPTH(ALIGN_VARCALL.out.align)
    VEP(
        ALIGN_VARCALL.out.vcf,
        vep_cache,
        reference
    )
    MULTIQC(
        QC_TRIM.out.fastp                          |
        mix(QC_TRIM.out.fastqc_before)             |
        mix(QC_TRIM.out.fastqc_after)              |
        mix(MOSDEPTH.out.global_dist.map{it[1]})   |
        mix(MOSDEPTH.out.region_dist.map{it[1]})   |
        mix(MOSDEPTH.out.summary.map{it[1]})       |
        mix(ALIGN_VARCALL.out.flagstat)            |
        mix(ALIGN_VARCALL.out.bcfstats)            |
        mix(VEP.out.html)                          |
        collect
    )
}