// Define the `ON_TARGET_RATIO` process that calculates on target ratio
process ON_TARGET_RATIO {
    container 'glebusasha/bwa_samtools'
    conda 'samtools'
    tag {
        sid.length() > 40 ? "${sid.take(20)}...${sid.takeRight(20)}" : sid
    }
    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${params.launch_name}/ON_TARGET_RATIO"
//    debug true
    errorStrategy 'ignore'

    input:
    tuple val(sid), path(bam), path(bamIndex)
    tuple val(sid), path(bed), path(bed_index)
    
    output:
    path "${sid}_on_target_ratio.txt", emit: on_target_ratio

    script:
    """
    on_target_bases=\$(zcat $bed | awk '{sum+=\$4*(\$3-\$2)} END {print sum}')
    total_bases=\$(samtools view -c $bam)
    on_target_ratio=\$(awk "BEGIN {print \$on_target_bases / \$total_bases}")

    echo "on_target_bases: \$on_target_bases" > "${sid}_on_target_ratio.txt"
    echo "total_bases: \$total_bases" >> "${sid}_on_target_ratio.txt"
    echo "On-Target Ratio: \$on_target_ratio" >> "${sid}_on_target_ratio.txt"
    """
}
