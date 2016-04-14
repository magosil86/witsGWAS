#Load SNP frequency file and generate cumulative freequency distribution
b.frq <- read.table("qced_clean_inds_freq.frq",header=T)
pdf("qcplink_plots/maf_plot.pdf")
plot(ecdf(b.frq$MAF), xlim=c(0,0.10),ylim=c(0,1),pch=20, main="MAF cumulative distribution",xlab="Minor allele frequency (MAF)", ylab="Fraction of SNPs",axes=T)
