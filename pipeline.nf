/*
 * pipeline input parameters
 */
params.input_bam = "/home/ubuntu/data/HG002.10kb.Q20.GRCh38.pbmm2.bam"
params.outdir = "/home/ubuntu/pipeline-output"
params.reference_fasta = "/home/ubuntu/data/reference/"
params.bed = "/home/ubuntu/data/candidates.bam"

println "input bam: $params.input_bam"
println "outdir: $params.outdir"

ref = file(params.reference_fasta)
bed_path = file(params.smrtsv_bed)
sniffles_path =/home/ubuntu/Sniffles-1.0.10/bin/sniffles-core-1.0.10/sniffles/

input_depth = 30
bams = Channel.fromPath(params.input_bam)
depths = Channel.from(5,10,20,30)
bam_depths = depths.combine(bams).map{ depth, bam -> tuple(depth,bam.basename,bam)} 

processdownsample{
    input:
    set depth, basename, bam from bam_depths

    output:
    set depth, basename, file("*.ds.bam") into ds_bams #need to add bai files?

    script
    '''
      frac=$( bc -l <<< "scale=16; !{depth}/!{input_depth}" )

      if [[ frac < 0.9 ]]; then 
        sambamba view -t 8 -f bam -s $frac -o "!{basename}.${depth}x.bam" "!{bam}"
      else
        ln -s "!{bam} "!{basename}_!{depth}x.bam"
      fi
    '''
}

ds_bams.into { bam_sniffles; bam_pbsv; }

/*
 * sniffles
 */
process sniffles {
    publishDir "${params.outdir}/sniffles", mode:'copy'

    input:
    set depth, basename, file (bam) into bam_sniffles
 

    output:
    file "sniffles.vcf" into sniffles_vcf_ch

    script:
    """
    "!{sniffles_path}/sniffles" -s 3 --skip_parameter_estimation -m !{bam} -v "!{basename}.${depth}x.Sniffles_s3_ignoreParam.vcf"
    """
}
/*
 * pbsv
 */
process pbsv {
    publishDir "${params.outdir}/pbsv", mode:'copy'

    input:
    file bam from bam_pbsv

    output:
    output:
    file "pbsv.svsig.gz" into pbsv_vcf_ch

    script:
    """
    pbsv discover $bam pbsv.svsig.gz
    """
}

/*
 * truevari
 */
process truevari {
    publishDir "${params.outdir}/truevari", mode:'copy'

    input:
    file pbsv_vcf from pbsv_vcf_ch
    file smartsv_vcf from smartsv_vcf_ch
    file sniffles_vcf from sniffles_vcf_ch

    output:
    file '*' into truevari_out_channel

    script:
    """

    """
}
