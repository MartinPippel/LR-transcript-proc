process preprocess_reads {
    /*
    Concatenate reads from a sample directory.
    Classify, trim, and orient cDNA reads using pychopper
    
    WORK IN PROGRESS:
    When new pychopper + pigz container is available use pigz multithreaded compression - hence saving uncompressed file at the moment
    
    parametrise the extension of fastq files in input
    */

    label 'preprocess_reads'
    label 'wftrx'
    tag {smpl_id}
    container = 'docker://ontresearch/wf-transcriptomes:shac733d952a14257cf3c5c5d5d44c6aed84d5fe5a1'
    
    input:
    tuple path(path2fastq), val(smpl_id)

    output:
    tuple path("${smpl_id}_full_length_reads.fastq.gz"), val("${smpl_id}"), emit: full_len_reads
    path "*.pdf", optional: true
    path "*.tsv", optional: true
    path "versions.txt"


    script:
    
    def args = task.ext.args ?: ''
    
    """
    cat ${path2fastq}/*.fastq.gz > all.raw.fastq.gz
    
    if [[ ${params.seqtype} == "cDNA" ]]
    then 
        # alt
        pychopper -t $task.cpus \\
            ${args} \\
            all.raw.fastq.gz - | bgzip -c -@ $task.cpus > ${smpl_id}_full_length_reads.fastq.gz

        mv pychopper.tsv "${smpl_id}.pychopper.tsv"
        mv pychopper.pdf "${smpl_id}.pychopper.pdf"
    else #dRNA 
        ln -s -r all.raw.fastq.gz ${smpl_id}_full_length_reads.fastq.gz
    fi 

    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process ** preprocess_reads **
    pychopper
    \$( pychopper -h )
    END_VERSIONS


    """

}