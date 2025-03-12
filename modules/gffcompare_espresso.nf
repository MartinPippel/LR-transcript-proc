process gffcompare_espresso {

    label 'gffcompare_stringtie'
    label 'small'
    container = 'docker://community.wave.seqera.io/library/gffcompare_gffread:0ec3e114ccf09e35'

    input:
    path espresso_gtf_ch

    output:
    path("gffcompare_espresso.stats")
    path("gffcompare_espresso.annotated.gtf")
    path("gffcompare_espresso.loci")
    path("gffcompare_espresso.${espresso_gtf_ch}.refmap")
    path("gffcompare_espresso.${espresso_gtf_ch}.tmap")
    path "versions.txt"

    script:
    def args = task.ext.args ?: ''
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