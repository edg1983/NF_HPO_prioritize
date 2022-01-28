# HPO prioritization pipeline
Based on HPO profiles and input files provided this pipeline run [GADO](https://www.nature.com/articles/s41467-019-10649-4) and/or [Exomiser](https://github.com/exomiser/Exomiser)


## Before you run
Before you can use the pipeline you need to install Exomiser, GADO and some supporting files

### Exomiser
You can download the latest version of Exomiser from the [Monarch initiative FTP](http://data.monarchinitiative.org/exomiser/latest/index.html)

1. Update `exomiser_cli` params in the `nextflow.config` to point to the `.jar` file of exomiser CLI.
2. Update the `config/application.properties` file to point to your exomiser data folder. 
3. Note that the current configuration also use CADD score, so you need to have CADD score files installed as well and you need to configure the corresponding file location in `config/application.properties` (or remove CADD from the template files in `config`)

### GADO
1. Download the GADO cli 1.0.1 from the [official release](https://github.com/molgenis/systemsgenetics/releases/download/v1.0.4/GadoCommandline-1.0.1-dist.zip)
2. Download dataset files. You can find the links in the [GADO github wiki](https://github.com/molgenis/systemsgenetics/wiki/GADO-Command-line)
3. Uncompress the prediction matrix `.zip` file and rename files so that you have a folder (let say `GADO_resources` containing the following files:
    - hpo_predictions_info.txt 
    - hpo_predictions_genes.txt  
    - hpo_predictions_matrix_spiked.cols.txt  
    - hpo_predictions_matrix_spiked.rows.txt
    - hpo_predictions_matrix_spiked.dat
4. Download the HPO ontology `.obo` file from GADO wiki or directly from [HPO ontology](http://purl.obolibrary.org/obo/hp.obo)

Then you need to update the following params in the `nextflow.config`
- GADO_cli: path to your GADO cli `.jar` file
- GADO_datafolder: path to folder containing GADO files (`GADO_resources` in this example)
- HPO_obofile: path to your `.obo` files

## Usage

When everything is properly configured in `nextflow.config` you can run the pipeline using

```
nextflow main.nf --GADO --exomiser \
    --HPO HPO_profiles.tsv \
    --exomiser_input exomiser_input.tsv \
    --exomiser_template config/template_GRCh38.yml \
    --out results
```

*NB* There are current profiles for `sge` and `slurm` in the config file, but you need to configure the queue names for your system


## Input files

Only HPO profiles file is required for GADO, while also exomiser input is required for exomiser.

### HPO profiles
This is a tab-separated file without header containing 1 case per line, with case ID in column 1 and then 1 HPO term per column 

```
case1   HP:00001   HP:000002
case2   HP:00003   HP:000004    HP:000006
```

### Exomiser input
This is a tab-separated file without header containing 1 case per line, with case ID, proband id, vcf file and ped file. **NB** `case ID` must match case ID from the HPO profiles and `proband id` must match the id of proband sample in the VCF file.

```
case1   proband1    case1_family.vcf.gz case1.ped
case2   proband2    case2_family.vcf.gz case2.ped
```

## Change exomiser settings

The exomiser annotation and filter settings are store in the `.yml` templated in the `config` folder. The provided files will filter for protein-changing variants with population AF < 1% and use CADD, PP2 and SIFT scores for variant scoring. All possible segregation models are evaluated and hiPhive is used for HPO-based prioritization. You can change these template to change analysis settings for the Exomiser. Please refer to the [exomiser documentation](https://exomiser.github.io/Exomiser/manual/7/exomiser/).