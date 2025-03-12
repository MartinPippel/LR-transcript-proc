process espresso_q_input {

    label 'espresso_q_input'

    container = 'docker://community.wave.seqera.io/library/espresso_perl:7d848c582b3ebb18'

    input:
    path espresso_c_smpl_ch
    path espresso_s_samplesheet_ch

    output:
    path "*updated.gtf", emit: espresso_gtf_ch
    path "*abundance.esp"
    path "versions.txt"

    script:
    def ext_args = task.ext.args ?: ''
    def ext_args2 = task.ext.args2 ?: ''
    """
    perl /espresso/src/ESPRESSO_Q.pl  ${ext_args} \\
        -L sample_sheet.tsv.updated \\
        -A ${params.refGTF} \\
        -T ${task.cpus} \\
        -O .
    
    ## igv visualisation 
    if [[ "x${ext_args2}" != "x" ]]
    then 
        python /espresso/visualization/visualize.py --genome-fasta ${params.refFa} \\
            ${ext_args2}\\
            --updated-gtf sample_sheet_N2_R0_updated.gtf \\
            --abundance-esp sample_sheet_N2_R0_abundance.esp \\
            --output-dir visualization
    fi
    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process ** espresso_q_input **
    ESPRESSO_Q.pl
    \$(perl /espresso/src/ESPRESSO_Q.pl --help | grep -E "Program | Version" )
    END_VERSIONS
    """


}