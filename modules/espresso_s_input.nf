process espresso_s_input {

    label 'espresso_s_input'
    
    container = 'community.wave.seqera.io/library/espresso_perl:7d848c582b3ebb18'

    input:
    val(args)

    output:
    path("*.tsv")
    path("ESPRESSO_S"), emit: espresso_s_out_ch
    path("ESPRESSO_S/sample_sheet.tsv.updated"), emit: espresso_s_samplesheet_ch
    path("espresso_s_summary.txt")
    path "versions.txt"

    script:
    def ext_args = task.ext.args ?: ''
    def gigabyte = (task.memory ?: MemoryUnit.of('2.Gb')).getGiga() / task.cpus
    """
    bash $projectDir/bin/save-espressoS-input.sh ${args}

    perl /espresso/src/ESPRESSO_S.pl ${ext_args} \\
        -L sample_sheet.tsv \\
        -O ESPRESSO_S \\
        -M ${params.espresso_mito} \\
        -T ${task.cpus} \\
        --sort_buffer_size ${gigabyte}G \\
        -F ${params.refFa} \\
        -A ${params.refGTF}

    cp ESPRESSO_S/espresso_s_summary.txt .



    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process **  espresso_s_input **
    ESPRESSO_S.pl
    \$(perl /espresso/src/ESPRESSO_S.pl --help | grep -E "Program | Version" )
    END_VERSIONS
    """
}