// modules for LR-trx-proc.nf


params.st="stringtie"
params.stOut="${params.outdir}/${params.st}"

params.stm="stringtie_merge"
params.stmOut="${params.outdir}/${params.stm}"

params.stm_gffcmp="stringtie_gff_compare"
params.stGffCmpOut="${params.outdir}/${params.stm_gffcmp}"

params.esp="ESPRESSO"
params.espOut="${params.outdir}/${params.esp}"

params.espm="espresso_merge"
params.espmOut="${params.outdir}/${params.espm}"

params.espm_gffcmp="espresso_gff_compare"
params.espGffCmpOut="${params.outdir}/${params.espm_gffcmp}"


params.espressoOutS="${params.outdir}/ESPRESSO/ESPRESSO_S"
params.espressoOutC="${params.outdir}/ESPRESSO/ESPRESSO_C"
params.espressoOutQ="${params.outdir}/ESPRESSO/ESPRESSO_Q"

params.readsPreprocOut="${params.outdir}/pychopper"
params.readsMappedOut="${params.outdir}/minimap2"


// assets
//params.countertemplate="${projectDir}/assets/template.properties"


// scripts
params.scripts="${projectDir}/bin"

// versions
params.verfile="versions.txt"

/// modules

process preprocess_reads {
    /*
    Concatenate reads from a sample directory.
    Optionally classify, trim, and orient cDNA reads using pychopper
    */

    publishDir params.readsPreprocOut, mode:'copy',
    saveAs: {filename ->
        if (filename.endsWith(".fastq.gz")) "$filename"
    }



    label 'wftrx'

    input:
    tuple path(path2fastq), val(smpl_id)

    output:
    tuple path("${smpl_id}_full_length_reads.fastq.gz"), val("${smpl_id}"), emit: full_len_reads

    script:
    """
    #pychopper -t ${params.threads_wftrx} ${params.pychopper_opts} ${path2fastq} - | pigz -p ${params.threads_wftrx} > ${smpl_id}_full_length_reads.fastq.gz
    pychopper -t ${params.threads_wftrx} ${params.pychopper_opts} ${path2fastq} - | gzip > ${smpl_id}_full_length_reads.fastq.gz
    
    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process ** preprocess_reads **
    pychopper
    \$( pychopper -h )
    END_VERSIONS


    """

}



process genome_idx {

    label 'mid_mem'

    input:
    path genome_ch

    output:
    path "genome.minimap.idx.mmi", emit: genome_idx_ch

    script:
    """
    minimap2 -t ${params.threads_mid_mem} ${params.minimap_index_opts} -I 1000G -d genome.minimap.idx.mmi ${genome_ch}"
    """
}


process map_genome {

    publishDir params.readsMappedOut, mode:'copy',
    saveAs: {filename ->
        if (filename.endsWith(".bam")) "$filename"
        else if (filename.endsWith(".bai")) "$filename"
    }


    label 'mid_mem'

    input:
    tuple path(fastq_proc), val(smpl_id)
    path genome_idx_ch

    output:
    tuple path("${smpl_id}_all_alns.minimap2.bam"), val(smpl_id), emit: mapped_genome_ch
    //tuple path("${smpl_id}_all_alns.minimap2.bam"), path("${smpl_id}_all_alns.minimap2.bam.bai"), val(smpl_id), emit: mapped_genome_ch

    script:
    """
    minimap2 -t ${params.threads_mid_mem} -ax splice -uf ${genome_idx_ch} ${fastq_proc} | samtools view -hbo -| samtools sort -@ ${params.threads_mid_mem} -o ${smpl_id}_all_alns.minimap2.bam - "

    samtools index ${smpl_id}_all_alns.minimap2.bam


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




process stringtie {
    publishDir params.stOut, mode:'copy',
    saveAs: {filename ->
        if (filename.endsWith(".gtf")) "$filename"
        else if (filename.endsWith(".txt")) "$filename"
        else null
    }


    label 'mid_mem'

    input:
    tuple path(bamfile), val(smpl_id)

    output:
    path("*.gtf"), emit: stringtie_gtf_ch
    path "versions.txt"

    script:
    """
    stringtie $bamfile --rf -L -p ${task.cpus} -v -G ${params.refGTF} >${smpl_id}.stringtie.gtf

    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process ** stringtie **
    stringtie
    \$( stringtie --version )
    END_VERSIONS
    """

}


process stringtie_merge {
    publishDir params.stmOut, mode:'copy'

    label 'mid_mem'

    input:
    path stringtie_gtfs

    output:
    path("${params.projname}.stringtie.merged.gtf"), emit: stringtie_merged_ch

    script:
    """
    stringtie --merge ${stringtie_gtfs}  -G ${params.refGTF} -o ${params.projname}.stringtie.merged.gtf

    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process ** stringtie_merge **
    stringtie
    \$( stringtie --version )
    END_VERSIONS

    """

}


process gffcompare_stringtie {
    publishDir params.stGffCmpOut, mode:'copy'

    label 'small'

    input:
    path stringtie_merged

    output:
    path("gffcompare_stringtie.stats")
    path("gffcompare_stringtie.annotated.gtf")
    path("gffcompare_stringtie.loci")
    path("gffcompare_stringtie.${stringtie_merged}.refmap")
    path("gffcompare_stringtie.${stringtie_merged}.tmap")


    script:
    """
    gffcompare -R -r ${params.refGTF} -o gffcompare_stringtie $stringtie_merged
    
    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process **  gffcompare_stringtie **
    gffcompare
    \$( gffcompare --version )
    END_VERSIONS
    """

}



// process espresso_run {
//     publishDir params.espOut, mode:'copy'

//     label 'big_mem'

//     input:
//     tuple path(bamfile), val(smpl_id)
    
//     output:
//     path "${smpl_id}/espresso_s_summary.txt"
//     path "${smpl_id}/SJ_group_all.fa"
//     path "${smpl_id}/*abundance.esp"
//     path "${smpl_id}/*updated.gtf"
//     path "${smpl_id}/1_SJ_simplified.list"
//     path "${smpl_id}/espresso_q_summary.txt"
//     path "${smpl_id}/0/1_read_final.txt"
//     path "${smpl_id}/0/espresso_c_summary.txt"
//     path "${smpl_id}/0/sam.list3"
//     path "${smpl_id}/0/sj.list"
//     path "${smpl_id}/${smpl_id}.espresso.updated.gtf", emit: espresso_gtf_ch


//     script:
//     """
//     mkdir ${smpl_id}

//     echo "${bamfile}\t${smpl_id}" >>sample_sheet.tsv

//     #perl /espresso/src/ESPRESSO_S.pl -M M -L sample_sheet.tsv -T ${task.cpus} --sort_buffer_size ${task.memory} -F ${params.refFa} -A ${params.refGTF} -O ${smpl_id}
//     #perl /espresso/src/ESPRESSO_C.pl -I ${smpl_id} -F ${params.refFa} -X 0 -T ${task.cpus} --sort_buffer_size ${task.memory}
//     #perl /espresso/src/ESPRESSO_Q.pl -L "${smpl_id}/sample_sheet.tsv.updated" -A ${params.refGTF} -T ${task.cpus}

//     perl /espresso/src/ESPRESSO_S.pl -M M -L sample_sheet.tsv -T ${params.espresso_cpus} --sort_buffer_size ${params.espresso_mem} -F ${params.refFa} -A ${params.refGTF} -O ${smpl_id}
//     perl /espresso/src/ESPRESSO_C.pl -I ${smpl_id} -F ${params.refFa} -X 0 -T ${params.espresso_cpus} --sort_buffer_size ${params.espresso_mem}
//     perl /espresso/src/ESPRESSO_Q.pl -L "${smpl_id}/sample_sheet.tsv.updated" -A ${params.refGTF} -T ${params.espresso_cpus}

//     cp ${smpl_id}/*updated.gtf ${smpl_id}/${smpl_id}.espresso.updated.gtf 

//     date >>${params.verfile}
//     echo "ESPRESSO" >>${params.verfile}
//     perl /espresso/src/ESPRESSO_S.pl --help >>${params.verfile}
//     echo "" >>${params.verfile}
//     perl /espresso/src/ESPRESSO_C.pl --help >>${params.verfile}
//     echo "" >>${params.verfile}
//     perl /espresso/src/ESPRESSO_Q.pl --help >>${params.verfile}
//     echo "" >>${params.verfile}
//     """
// }


// process espresso_merge {
//     publishDir params.espmOut, mode:'copy'

//     label 'mid_mem'

//     input:
//     path espresso_gtfs

//     output:
//     path("${params.projname}.espresso.merged.gtf"), emit: espresso_merged_ch

//     script:
//     """
//     stringtie --merge ${espresso_gtfs}  -G ${params.refGTF} -o ${params.projname}.espresso.merged.gtf

//     date >>${params.verfile}
//     echo "stringtie" >>${params.verfile}
//     stringtie --version >>${params.verfile}
//     echo "" >>${params.verfile}
//     """

// }


// process gffcompare_espresso {
//     publishDir params.espGffCmpOut, mode:'copy'

//     label 'small'

//     input:
//     path espresso_merged

//     output:
//     path("gffcompare_espresso.stats")
//     path("gffcompare_espresso.annotated.gtf")
//     path("gffcompare_espresso.loci")
//     path("gffcompare_espresso.${espresso_merged}.refmap")
//     path("gffcompare_espresso.${espresso_merged}.tmap")


//     script:
//     """
//     gffcompare -R -r ${params.refGTF} -o gffcompare_espresso $espresso_merged
    
//     date >>${params.verfile}
//     echo "gffcompare" >>${params.verfile}
//     gffcompare --version >>${params.verfile}
//     echo "" >>${params.verfile}
//     """

// }






process espresso_s_input {

    publishDir params.espressoOutS, mode:'copy',
    saveAs: {filename ->
        if (filename.endsWith(".tsv.updated")) "$filename"
        else if (filename.endsWith(".txt")) "$filename"
    }

    label 'espressoS'

    input:
    val(args)

    output:
    path("*.tsv")
    path("ESPRESSO_S"), emit: espresso_s_out_ch
    path("ESPRESSO_S/sample_sheet.tsv.updated"), emit: espresso_s_samplesheet_ch
    path("espresso_s_summary.txt")

    script:
    """
    bash save-espressoS-input.sh ${args}

    perl /espresso/src/ESPRESSO_S.pl -L sample_sheet.tsv -O ESPRESSO_S -M ${params.espresso_mito} -T ${params.espresso_threads} --sort_buffer_size ${params.espresso_mem} -F ${params.refFa} -A ${params.refGTF}

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


process espresso_c_smpl {

    publishDir params.espressoOutC, mode:'copy',
    saveAs: {filename ->
        if (filename.endsWith(".espresso_c_summary.txt")) "$filename"
    }


    label 'espressoC'


    input:
    tuple val(smpl_id), val(smpl_idx)
    path espresso_s_out_ch

    output:
    path "espressoS/${smpl_idx}", emit: espresso_c_smpl_ch
    path "${smpl_id}.espresso_c_summary.txt"


    script:
    """
    cp -r ESPRESSO_S espressoS ## to isolate the execution process

    perl /espresso/src/ESPRESSO_C.pl -I espressoS -T ${params.espresso_threads} --sort_buffer_size ${params.espresso_mem} -F ${params.refFa} -X ${smpl_idx}


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


process espresso_q_input {

    publishDir params.espressoOutQ, mode:'copy',
    saveAs: {filename ->
        if (filename.endsWith("updated.gtf")) "$filename"
        else if (filename.endsWith("abundance.esp")) "$filename"
    }


    label 'espressoQ'


    input:
    path espresso_c_smpl_ch
    path espresso_s_samplesheet_ch

    output:
    path "*updated.gtf", emit: espresso_gtf_ch
    path "*abundance.esp"

    script:
    """
    perl /espresso/src/ESPRESSO_Q.pl  -L sample_sheet.tsv.updated  -A ${params.refGTF} -T ${params.espresso_threads} -O .

    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process **  espresso_q_input **
    ESPRESSO_Q.pl
    \$(perl /espresso/src/ESPRESSO_Q.pl --help | grep -E "Program | Version" )
    END_VERSIONS
    """


}



process gffcompare_espresso {
    publishDir params.espGffCmpOut, mode:'copy'

    label 'small'

    input:
    path espresso_gtf_ch

    output:
    path("gffcompare_espresso.*")

    script:
    """
    gffcompare -R -r ${params.refGTF} -o gffcompare_espresso ${espresso_gtf_ch}
    

    cat <<-END_VERSIONS > versions.txt
    Software versions for LR-trx-proc.nf
    \$( date )
    process **  gffcompare_espresso **
    gffcompare
    \$( gffcompare --version )
    END_VERSIONS
    """

}
