// Define the `SAMTOOLS_FLAGSTAT` process that aligns stats
process SAMTOOLS_FLAGSTAT {
    container = 'glebusasha/bwa_samtools'
    tag ""
//    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${workflow.runName}/SAMTOOLS_FLAGSTAT"
//	  debug true
//    errorStrategy 'ignore'

    input:
    tuple val(sid), path(bamFile)
    
    output:
    path "*.flagstat", emit: flagstat
    
    script:
    """
    samtools flagstat $bamFile > ${sid}.flagstat
    """
}
