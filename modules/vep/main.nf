// Define the `VEP` process that performs annotation
process VEP {
    container = 'ensemblorg/ensembl-vep:latest'
//    containerOptions "-B ${params.vepcache}:/opt/vep/.vep"
    tag "$vcf"
    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${workflow.runName}/VEP"
//    debug true
//    cache "lenient"
    errorStrategy 'ignore'

    input:
    tuple val(sid), path(vcf)
    path vep_cache
    path reference

    output:
    path "${sid}.vep", emit: vep
    path "${sid}.vep.html", emit: html

    script:
    """
    vep \
    -i $vcf \
    -o ${sid}.vep \
    --stats_file ${sid}.vep.html \
    --fork ${task.cpus} \
    --cache \
    --dir_cache ${vep_cache} \
    --everything \
    --species homo_sapiens \
    --offline \
    --vcf \
    --assembly GRCh38
    """
}

