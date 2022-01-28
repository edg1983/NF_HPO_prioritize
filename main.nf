nextflow.enable.dsl=2

// At the moment works only for GRCh38 data

// Print help message when --help is used
params.help = false
if (params.help) {
    println """\
        HPO-based prioritization pipeline - PARAMETERS    
        ============================================
        --exomiser                  :   activate exomiser prioritisation
        --GADO                      :   activate GADO prioritisation
        --HPO HPO.tsv               :   TSV file containg HPO profiles.
                                        Column1 is caseID, then HPOs id tab-separated
        --exomiser_input input.tsv  :   TSV file describing the inputs, no header
                                        col1: caseID, col2: VCF_file, col3: PED_file, col4: proband
        --exomiser_cli              :   Location of the exomiser CLI .jar file
        --exomiser_appsettings      :   Location of the application.settings file to use with Exomiser
        --exomiser_template         :   Location of the template .yml file for exomiser
        --GADO_cli                  :   Location of the GADO CLI .jar file
        --GADO_datafolder           :   Folder containing GADO supporting files 
                                        see https://github.com/molgenis/systemsgenetics/wiki/GADO-Command-line
        --HPO_obofile               :   .obo file for the HPO ontology
        --out                       :   Output folder for annotated files
        """
        .stripIndent()

    exit 1
}

// Checks at least one input is specified
if (!params.exomiser && !params.GADO) {
    exit 1, "Specify at least one between --GADO and --exomiser"
}

log.info """\
    ==============================================
     HPO prioritization  -  N F   P I P E L I N E    
    ==============================================
    Exomiser                : ${params.exomiser ? "active" : "NO"}
    GADO                    : ${params.GADO ? "active" : "NO"}
    HPO profiles            : ${params.HPO}
    input exomiser          : ${params.exomiser_input}
    exomiser cli            : ${params.exomiser_cli}
    exomiser appsettings    : ${params.exomiser_appsettings}
    exomiser template       : ${params.exomiser_template}
    GADO_datafolder         : ${params.GADO_datafolder}
    output folder           : ${params.out}
    ==============================================
    """
    .stripIndent()

// Check input files exist
if (params.GADO) {
    checkPathParamList = [
        params.GADO_cli, params.HPO, params.HPO_obofile
    ]
    for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }
}
if (params.exomiser) {
    checkPathParamList = [
        params.exomiser_cli, params.HPO, params.exomiser_appsettings, params.exomiser_input
    ]
    for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }
}


//Make output dir and set prefix
output_exomiser = file("$params.out/exomiser")
output_exomiser_settings = file("$params.out/exomiser/settings")
output_gado = file("$params.out/GADO")

workflow {
    // EXOMISER
    if (params.exomiser) {
        output_exomiser.mkdirs()
        output_exomiser_settings.mkdirs()

        appsetting_exomiser = file(params.exomiser_appsettings)
        hpo_file_exomiser = file(params.HPO)
        input_file_exomiser = file(params.exomiser_input)
        exomiser_template = file(params.exomiser_template)
        
        configure_exomiser(exomiser_template, input_file_exomiser, hpo_file_exomiser)
        exomiser(configure_exomiser.out, appsetting_exomiser)
    }

    // GADO
    if (params.GADO) { 
        output_gado.mkdirs()
        hpo_file_gado = file(params.HPO)
        gado_preprocess(hpo_file_gado)
        gado_predict(gado_preprocess.out)
    }
}

process configure_exomiser {
    publishDir "$output_exomiser_settings", mode: 'copy' 

    input:
        file(template)
        file(input_file)
        file(hpo_file)

    output:
        path '*.yml'

    script:
    """
    python $projectDir/bin/Configure_exomiser.py \
        -t $template \
        -i $input_file \
        -p $hpo_file  
    """
}

process exomiser {
    publishDir "$output_exomiser", mode: 'move' 

    input:
        file(analysis_setting)
        file(application_setting)

    output:
        file '*.tsv'
        file '*.json'

    script:
    """
    java -jar ${params.exomiser_cli} \
        -analysis $analysis_setting
    """
}

process gado_preprocess {
    input:
        file(hpo_file)

    output:
        file 'gado_processed_hpo.txt'

    script:
    """
    java -jar ${params.GADO_cli} \
        -m PROCESS \
        -ch $hpo_file \
        -g ${params.GADO_datafolder}/hpo_predictions_genes.txt \
        -ho ${params.HPO_obofile} \
        -hp ${params.GADO_datafolder}/hpo_predictions_matrix_spiked.dat \
        -hpi ${params.GADO_datafolder}/hpo_predictions_info.txt \
        -o gado_processed_hpo.txt
    """
}

process gado_predict {
    publishDir "$output_gado", mode: 'move' 

    input:
        file(processed_hpo)

    output:
        file '*.txt'

    script:
    """
    mkdir predictions
    java -jar ${params.GADO_cli} \
        -m PRIORITIZE \
        -chp $processed_hpo \
        -g ${params.GADO_datafolder}/hpo_predictions_genes.txt \
        -ho ${params.HPO_obofile} \
        -hp ${params.GADO_datafolder}/hpo_predictions_matrix_spiked.dat \
        -hpi ${params.GADO_datafolder}/hpo_predictions_info.txt \
        -o ./
    """
}