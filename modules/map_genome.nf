process map_genome {

    label 'map_genome'
    label 'mid_mem'
    container = 'docker://community.wave.seqera.io/library/minimap2_samtools:03e1e7cf6ec6695d'

    tag {smpl_id}

    input:
    tuple path(fastq_proc), val(smpl_id), path(genome_idx_ch)

    output:
    tuple path("${smpl_id}_all_alns.minimap2.bam"), val(smpl_id), emit: mapped_genome_ch
    //tuple path("${smpl_id}_all_alns.minimap2.bam"), path("${smpl_id}_all_alns.minimap2.bam.bai"), val(smpl_id), emit: mapped_genome_ch
    path "versions.txt"
    path "${smpl_id}_all_alns.minimap2.stats.txt"

    script:

    def args = task.ext.args ?: ''

    """
    paftools.js gff2bed ${params.refGTF} > junctions.bed

    minimap2 -t ${task.cpus} \\
    ${args} -a \\
    --junc-bed junctions.bed \\
    ${genome_idx_ch} ${fastq_proc} \\
    | samtools sort -@ ${task.cpus} \\
    --write-index \\
    -o "${smpl_id}_all_alns.minimap2.bam" -

    samtools stats -@ ${task.cpus} ${smpl_id}_all_alns.minimap2.bam > ${smpl_id}_all_alns.minimap2.stats.txt
    
    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process ** map_genome **
    minimap2
    \$( minimap2 --version )
    samtools
    \$( samtools --version )
    END_VERSIONS
    """


}