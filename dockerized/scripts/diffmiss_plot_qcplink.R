#Load SNP differential missingness file and generate distribution
b.frq <- read.table("clean_inds_qcplink_test_missing.missing",header=T)
if (nrow(b.frq) >= 1) {
b.frq$logP = log10(b.frq$P)
pdf("qcplink_plots/diffmiss_plot.pdf")
plot(ecdf(b.frq$logP), xlim=c(-10,0),ylim=c(0,1),pch=20, main="Distribution of differential missingness P-values", xlab="logP Differential Missingness", ylab="Fraction of SNPs",col="red",axes=T)
} else {
    print("No differential missingness info to plot")}