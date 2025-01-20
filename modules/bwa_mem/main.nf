// Define the `ALIGN` process that aligns reads to the reference genome
process BWA_MEM {
    container 'glebusasha/bwa_samtools'
    conda 'bioconda::bwa bioconda::samtools'
    tag { 
        sid.length() > 40 ? "${sid.take(20)}...${sid.takeRight(20)}" : sid
    }
    cpus 10
    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${params.launch_name}/BWA_MEM"
//	  debug true
//    errorStrategy 'ignore'

    input:
    tuple val(sid), path(fq_1_trimmed), path(fq_2_trimmed)
    path reference
    path idx
    
    output:
    tuple val(sid), path("*.sorted.bam"), emit: bam
    
    script:
    """
        bwa mem \
            -t 6 ${reference} ${fq_1_trimmed} ${fq_2_trimmed} | \
        samtools view -bh | \
        samtools sort --threads 6 -o ${sid}.sorted.bam

    """
}