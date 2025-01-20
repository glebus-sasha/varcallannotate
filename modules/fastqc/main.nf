// Define the `FASTQC` process that performs quality trimming and filtering of reads
process FASTQC {
    container 'staphb/fastqc:0.12.1'
    conda 'fastqc'
    tag { 
        sid.length() > 40 ? "${sid.take(20)}...${sid.takeRight(20)}" : sid
    }
    publishDir "${params.outdir}/${workflow.start.format('yyyy-MM-dd_HH-mm-ss')}_${params.launch_name}/FASTQC", pattern: '*.html'
//	debug true
//  errorStrategy 'ignore'

    input:
    tuple val(sid), path(read1), path(read2)

    output:
    path "*.html", emit: html
    path "*.zip" , emit: zip

    script:
    """
    fastqc $read1 $read2 --threads 6
    """

    stub:
    """

    """
}
