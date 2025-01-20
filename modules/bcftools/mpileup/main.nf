// Define the `BCFTOOLS_MPILEUP` process that performs variant calling
process BCFTOOLS_MPILEUP {
    container 'staphb/bcftools:latest'
    conda 'bcftools'
    tag { 
        sid.length() > 40 ? "${sid.take(20)}...${sid.takeRight(20)}" : sid
    }
//    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${params.launch_name}/BCFTOOLS_MPILEUP"
//	debug true
//  errorStrategy 'ignore'
	
    input:
    path reference
    tuple val(sid), path(bamFile), path(bai)
    path fai
    
    output:
    tuple val(sid), path("${sid}.bcf")    ,     emit: bcf
    
    script:
    """    
    bcftools mpileup -f $reference $bamFile -Ou | bcftools call -m -Ob -o ${sid}.bcf --threads ${task.cpus}
    """
}
