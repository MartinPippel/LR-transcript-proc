process espresso_c_smpl {
    
    label 'espresso_c_smpl'

    container = 'docker://community.wave.seqera.io/library/espresso_perl:7d848c582b3ebb18'

    tag {smpl_id}

    input:
    tuple val(smpl_id), val(smpl_idx)
    path espresso_s_out_ch

    output:
    path "espressoS/${smpl_idx}", emit: espresso_c_smpl_ch
    path "${smpl_id}.espresso_c_summary.txt"
    path "versions.txt"


    script:
    def ext_args = task.ext.args ?: ''
    def gigabyte = (task.memory ?: MemoryUnit.of('2.Gb')).getGiga() / task.cpus
    """
    cp -r ESPRESSO_S espressoS ## to isolate the execution process

    perl /espresso/src/ESPRESSO_C.pl ${ext_args} \\
        -I espressoS \\
        -T ${task.cpus} \\
        --sort_buffer_size ${gigabyte}G \\
        -F ${params.refFa} \\
        -X ${smpl_idx}

    cp "espressoS/${smpl_idx}/espresso_c_summary.txt" "${smpl_id}.espresso_c_summary.txt"

    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process **  espresso_c_smpl **
    ESPRESSO_C.pl
    \$(perl /espresso/src/ESPRESSO_C.pl --help | grep -E "Program | Version" )
    END_VERSIONS

    """

}