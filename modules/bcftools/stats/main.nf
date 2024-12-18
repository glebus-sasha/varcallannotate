// Define the `BCFTOOLS_STATS` process that performs vcf statistics
process BCFTOOLS_STATS {
    container = 'staphb/bcftools:latest'
    tag { 
        sid.length() > 40 ? "${sid.take(20)}...${sid.takeRight(20)}" : sid
    }
//    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${workflow.runName}/BCFTOOLS_STATS"

//    cache "lenient" 
//    debug true
//    errorStrategy 'ignore'
	
    input:
    tuple val(sid), path(vcf)
    val tag

    output:
    path "${sid}_${tag}.bcfstats",      emit: bcfstats
    
    script:
    """
    bcftools stats $vcf > "${sid}_${tag}.bcfstats"
    """
}