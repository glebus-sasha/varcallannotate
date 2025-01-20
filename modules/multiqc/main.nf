// Define the `MULTIQC` process that performs report
process MULTIQC {
    container 'staphb/multiqc:latest'
    conda "${moduleDir}/environment.yml"
    tag ""
    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${workflow.runName}"
//	  debug true
//    errorStrategy 'ignore'
	
    input:
    path files

    output:
    path '*.html', emit: html

    script:
    """
    multiqc . -n "summary_report.html"
    """
}