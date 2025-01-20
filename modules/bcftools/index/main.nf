// Define the `BCFTOOLS_INDEX` process that performs vcf statistics
process BCFTOOLS_INDEX {
    container 'staphb/bcftools:latest'
    conda 'bcftools'
    tag { 
        sid.length() > 40 ? "${sid.take(20)}...${sid.takeRight(20)}" : sid
    }
//    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${workflow.runName}/BCFTOOLS_INDEX"

//    cache "lenient" 
//    debug true
    errorStrategy 'ignore'
	
    input:
    tuple val(sid), path(vcf)

    output:
    path "${sid}.*.csi",      emit: index
    
    script:
    """
    bcftools index $vcf
    """
}