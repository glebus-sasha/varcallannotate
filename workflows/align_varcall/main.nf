// Include processes
include { BWA_MEM                           } from '../../modules/bwa_mem'
include { SAMTOOLS_FLAGSTAT                 } from '../../modules/samtools/flagstat'
include { SAMTOOLS_INDEX                    } from '../../modules/samtools/index'
include { DEEPVARIANT                       } from '../../modules/deepvariant'
include { BCFTOOLS_INDEX                    } from '../../modules/bcftools/index'
include { BCFTOOLS_STATS                    } from '../../modules/bcftools/stats'

workflow ALIGN_VARCALL { 
    take:
    reference
    trimmed_reads
    bwaidx
    faidx

    main:
    BWA_MEM(trimmed_reads, reference, bwaidx)
    SAMTOOLS_FLAGSTAT(BWA_MEM.out.bam)
    SAMTOOLS_INDEX(BWA_MEM.out.bam)
    DEEPVARIANT(reference, BWA_MEM.out.bam.join(SAMTOOLS_INDEX.out.bai), faidx)
    BCFTOOLS_INDEX(DEEPVARIANT.out.vcf)
    BCFTOOLS_STATS(DEEPVARIANT.out.vcf, '')

    emit:
    align       = BWA_MEM.out.bam.join(SAMTOOLS_INDEX.out.bai)
    flagstat    = SAMTOOLS_FLAGSTAT.out.flagstat
    bcfstats   = BCFTOOLS_STATS.out.bcfstats
    vcf         = DEEPVARIANT.out.vcf
    
}