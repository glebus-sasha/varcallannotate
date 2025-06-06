# varcallannotate
Nextflos pipeline for variat calling and annotation

[Instruction](https://docs.google.com/document/d/11jPyh1NyD_TsrZC6RyAPUcdcDu9lFdHw2Kj4nD7wyvw/edit?pli=1&tab=t.0#heading=h.4ikn9g84g3gq)

## Pipeline Main Steps

- Quality Control: FastQC
- Trimming: Fastp
- Alignment: BWA MEM
- Variant Calling: DeepVariant
- Annotation: VEP (Variant Effect Predictor)

```mermaid
%%{init: {'theme':'base'}}%%
flowchart LR
    subgraph " "
    v0["Channel.fromPath"]
    v2["Channel.fromFilePairs"]
    v3["Channel.fromPath"]
    v5["Channel.fromPath"]
    v7["Channel.fromPath"]
    v25["tag"]
    end
    subgraph QC_TRIM
    v9([FASTQC_BEFORE])
    v11([FASTP])
    v13([FASTQC_AFTER])
    end
    subgraph " "
    v10[" "]
    v12[" "]
    v14[" "]
    v20[" "]
    v21[" "]
    v22["sid"]
    v24[" "]
    v28["align"]
    v30[" "]
    v38[" "]
    end
    subgraph ALIGN_VARCALL
    v15([BWA_MEM])
    v16([SAMTOOLS_FLAGSTAT])
    v17([SAMTOOLS_INDEX])
    v19([DEEPVARIANT])
    v23([BCFTOOLS_INDEX])
    v26([BCFTOOLS_STATS])
    v1(( ))
    v4(( ))
    v6(( ))
    v18(( ))
    v27(( ))
    end
    v29([VEP])
    v37([MULTIQC])
    v8(( ))
    v31(( ))
    v0 --> v1
    v2 --> v9
    v2 --> v11
    v3 --> v4
    v5 --> v6
    v7 --> v8
    v9 --> v10
    v9 --> v31
    v11 --> v13
    v11 --> v12
    v11 --> v15
    v11 --> v31
    v13 --> v14
    v13 --> v31
    v1 --> v15
    v4 --> v15
    v15 --> v16
    v15 --> v17
    v15 --> v18
    v15 --> v27
    v16 --> v31
    v17 --> v18
    v17 --> v27
    v1 --> v19
    v6 --> v19
    v18 --> v19
    v19 --> v22
    v19 --> v23
    v19 --> v21
    v19 --> v20
    v19 --> v26
    v19 --> v29
    v23 --> v24
    v25 --> v26
    v26 --> v31
    v27 --> v28
    v1 --> v29
    v8 --> v29
    v29 --> v30
    v29 --> v31
    v31 --> v37
    v37 --> v38
```
## Description
- **FASTQC_BEFORE**: Quality control of raw sequencing data using FastQC before trimming.
- **FASTP**: Trimming of reads to remove adapters and low-quality sequences using fastp.
- **FASTQC_AFTER**: Quality control of trimmed sequencing data using FastQC after trimming.
- **BWA_MEM**: Alignment of reads to the reference genome using BWA MEM.
- **SAMTOOLS_FLAGSTAT**: Quality assessment of alignment using SAMtools flagstat.
- **SAMTOOLS_INDEX**: Indexing of BAM files using SAMtools index.
- **DEEPVARIANT**: Variant calling using DeepVariant.
- **BCFTOOLS_INDEX**: Indexing of VCF files using BCFtools index.
- **BCFTOOLS_STATS**: Statistical analysis of variant calls using BCFtools stats.
- **VEP**: Variant Effect Predictor for annotating variants.
- **MULTIQC**: Compilation of a comprehensive report including QC metrics, alignment results, and variant calling statistics.

## Usage

### Quick Start

To quickly run the pipeline, use the following command:

```bash
nextflow run <your-username>/<your-repository> \
    -profile <docker/singularity> 
```

### Requirements

- Nextflow (https://www.nextflow.io/docs/latest/install.html)
- Docker (https://docs.docker.com/engine/install/) or
- Apptainer (https://apptainer.org)

### Running the Pipeline
```bash
nextflow run main.nf
```

## Contributors

- Oxana Kolpakova ([@OxanaKolpakova](https://github.com/OxanaKolpakova))
- Glebus Aleksandr ([@glebus-sasha](https://github.com/glebus-sasha/))

## License

This project is licensed under the [MIT License](LICENSE).

