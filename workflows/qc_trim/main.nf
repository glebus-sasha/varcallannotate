// Include processes
include { FASTQC as FASTQC_BEFORE } from '../../modules/fastqc'
include { FASTP                   } from '../../modules/fastp'
include { FASTQC as FASTQC_AFTER  } from '../../modules/fastqc'

workflow QC_TRIM { 
    take:
    input_fastqs

    main:
    FASTQC_BEFORE(input_fastqs)
    FASTP(input_fastqs)
    FASTQC_AFTER(FASTP.out.trimmed_reads)

    emit:
    trimmed_reads   = FASTP.out.trimmed_reads
    fastp           = FASTP.out.json
    fastqc_before   = FASTQC_BEFORE.out.zip
    fastqc_after    = FASTQC_AFTER.out.zip
}