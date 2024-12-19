// Define the `DEEPVARIANT` process that performs variant calling
process DEEPVARIANT {
    container = 'google/deepvariant:1.6.1'
    tag "$bamFile"
    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${workflow.runName}/DEEPVARIANT"
//    cache "lenient" 
//    debug true
//    errorStrategy 'ignore'
	
    input:
    path reference
    tuple val(sid), path(bamFile), path(bai)
    path fai

    output:
    val sid
    tuple val(sid), path("${sid}.vcf.gz")  ,     emit: vcf
    tuple val(sid), path("${sid}.g.vcf.gz"),     emit: gvcf
    path '*.html'                          ,     emit: html
    
    script:
    """
    /opt/deepvariant/bin/run_deepvariant \
    --model_type=WES \
    --ref=$reference \
    --reads=$bamFile \
    --output_vcf=${sid}.vcf.gz \
    --output_gvcf=${sid}.g.vcf.gz \
    --num_shards=1
    """
}