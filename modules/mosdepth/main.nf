// Define the `MOSDEPTH` process that calculates coverage depth
process MOSDEPTH {
    container 'nanozoo/mosdepth:0.3.2--892ca95'
    conda 'mosdepth'
    tag {
        sid.length() > 40 ? "${sid.take(20)}...${sid.takeRight(20)}" : sid
    }
//    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${params.launch_name}/MOSDEPTH"
//    debug true
//    errorStrategy 'ignore'

    input:
    tuple val(sid), path(bam), path(bamIndex)
    val tag
    path bed

    output:
    tuple val(sid), path("${sid}${tag}.mosdepth.global.dist.txt"), emit: global_dist
    tuple val(sid), path("${sid}${tag}.mosdepth.summary.txt")    , emit: summary
    tuple val(sid), path("${sid}${tag}.mosdepth.region.dist.txt"), emit: region_dist
    tuple val(sid), path("${sid}.regions.bed.gz"), path("${sid}.regions.bed.gz.csi"), emit: bed

    script:
    """
    mosdepth \
        -n \
        -t 6 \
        --by ${bed}  \
        ${sid} ${bam}

    if [ -n "${tag}" ]; then
        mv ${sid}.mosdepth.global.dist.txt ${sid}${tag}.mosdepth.global.dist.txt
        mv ${sid}.mosdepth.summary.txt ${sid}${tag}.mosdepth.summary.txt
        mv ${sid}.mosdepth.region.dist.txt ${sid}${tag}.mosdepth.region.dist.txt
    fi
    """
}
