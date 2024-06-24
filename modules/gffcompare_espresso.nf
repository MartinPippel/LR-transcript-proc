process gffcompare_espresso {

    label 'small'
    container = 'docker://agatasm/gffcompare-0.12.9'
    
    input:
    path espresso_gtf_ch

    output:
    path("gffcompare_espresso.*")
    path "versions.txt"

    script:
    def args = task.ext.args ? : ''
    """
    gffcompare ${args} \\
        -r ${params.refGTF} \\
        -o gffcompare_espresso ${espresso_gtf_ch}

    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process **  gffcompare_espresso **
    gffcompare
    \$( gffcompare --version )
    END_VERSIONS
    """

}