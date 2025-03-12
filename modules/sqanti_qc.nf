process sqanti_qc {

    label 'sqanti_qc'
    label 'mid_mem'
    container = 'docker://anaconesalab/sqanti3:5.3.6-conda-fix'

    input:
    path espresso_gtf_ch

    output:
    path "SQANTI_QC/*"
    path "versions.txt"

    script:
    def args = task.ext.args ?: ''
    """
    sqanti3_qc.py ${args} \\
        -t ${task.cpus} \\
        -o ${params.prefixOut} \\
        -d SQANTI_QC \\
        ${espresso_gtf_ch} ${params.refGTF} ${params.refFa} 


    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process **  sqanti_qc **
    SQANTI
    \$( sqanti3_qc.py --version )
    END_VERSIONS
    """


}