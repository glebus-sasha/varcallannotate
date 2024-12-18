// Define the `MULTIQC` process that performs report
process MULTIQC {
    container = 'staphb/multiqc:latest'
    tag ""
    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${workflow.runName}/MULTIQC"
//	  debug true
//    errorStrategy 'ignore'
	
    input:
    path fastp
    path fastqc1
    path fastqc2
    path flagstat
    path bcfstats1
    path bcfstats2

    output:
    path '*.html', emit: html

    script:
    """
    multiqc $fastqc1 $fastqc2 $fastp $flagstat $bcfstats1 $bcfstats2
    """
}