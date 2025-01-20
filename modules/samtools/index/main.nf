// Define the `SAMTOOLS_INDEX` process that prepares the bam file indices
process SAMTOOLS_INDEX {
    container 'glebusasha/bwa_samtools'
    conda 'bioconda::bwa bioconda::samtools'
    tag ""
//   publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${workflow.runName}/SAMTOOLS_INDEX"
//	  debug true
//    errorStrategy 'ignore'
    input:
    tuple val(sid), path(bamFile)

    output:
    tuple val(sid), path('*.bai'), emit: bai

    script:
    """
	samtools index ${bamFile}
    """
}