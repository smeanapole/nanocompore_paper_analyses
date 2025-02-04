library(tidyverse)
library(zoo)

ROOTDIR=system2("git", args=c("rev-parse", "--show-toplevel"), stdout=T)

trials_meta <- read_tsv(paste0(ROOTDIR, "/in_silico_dataset/data/simulated_datasets2/index.tsv"))

combined <- read_tsv(paste0(ROOTDIR, "/in_silico_dataset/analysis/roc_data/all_datasets.txt"), col_names=c("dataset_id", "method", "threshold", "TPR", "FPR")) %>% left_join(., trials_meta)


#combined <- group_by(combined, dataset_id, method) %>% 
#	mutate(TPR_rm=rollmean(x = TPR, 3, align = "center", fill = NA), FPR_rm=rollmean(x = FPR, 3, align = "center", fill = NA)) %>% 
#	mutate(TPR_rm=case_when(is.na(TPR_rm)~TPR, T~TPR_rm), FPR_rm=case_when(is.na(FPR_rm)~FPR, T~FPR_rm))

pdf("ROC_GMM_anova.pdf", width=12, height=12)
filter(combined, method=="GMM_anova") %>%
ggplot(aes(x=FPR, y=TPR, colour=factor(mod_reads_freq), group=mod_reads_freq)) + 
	geom_line() + 
	facet_grid(intensity_mod~dwell_mod) +
	xlab("False Positive Rate") + 
	ylab("True Positive Rate") + 
	labs(title="GMM anova test", color="Fraction of\nmodified reads") +
	theme_bw(14) +
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5))
dev.off()

pdf("ROC_GMM_logit.pdf", width=12, height=12)
filter(combined, method=="GMM_logit") %>%
ggplot(aes(x=FPR, y=TPR, colour=factor(mod_reads_freq), group=mod_reads_freq)) + 
	geom_line() + 
	facet_grid(intensity_mod~dwell_mod) +
	xlab("False Positive Rate") + 
	ylab("True Positive Rate") + 
	labs(title="GMM logit test", color="Fraction of\nmodified reads") +
	theme_bw(14) +
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5))
dev.off()

pdf("ROC_ks_intensity.pdf", width=12, height=12)
filter(combined, method=="KS_int") %>%
ggplot(aes(x=FPR, y=TPR, colour=factor(mod_reads_freq), gro_p=mod_reads_freq)) + 
	geom_line() + 
	facet_grid(intensity_mod~dwell_mod) +
	xlab("False Positive Rate") + 
	ylab("True Positive Rate") + 
	labs(title="KS intensity test", color="Fraction of modified reads") +
	theme_bw(14) + 
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5))
dev.off()

pdf("ROC_ks_dwell.pdf", width=12, height=12)
filter(combined, method=="KS_dwell") %>%
ggplot(aes(x=FPR, y=TPR, colour=factor(mod_reads_freq), gro_p=mod_reads_freq)) + 
	geom_line() + 
	facet_grid(intensity_mod~dwell_mod) +
	xlab("False Positive Rate") + 
	ylab("True Positive Rate") + 
	labs(title="KS dwell test", color="Fraction of modified reads") +
	theme_bw(14) +
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5))
dev.off()

pdf("ROC_GMM_anova_1sd.pdf", width=12, height=12)
filter(combined, method=="GMM_anova") %>%
filter(intensity_mod>=1, dwell_mod>=1) %>%
ggplot(aes(x=FPR, y=TPR, colour=factor(mod_reads_freq), group=mod_reads_freq)) + 
	geom_line() + 
	facet_grid(intensity_mod~dwell_mod) +
	xlab("False Positive Rate") + 
	ylab("True Positive Rate") + 
	labs(title="GMM anova test", color="Fraction of\nmodified reads") +
	theme_bw(21) +
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5))
dev.off()

pdf("ROC_GMM_logit_1sd.pdf", width=12, height=12)
filter(combined, method=="GMM_logit") %>%
filter(intensity_mod>=1, dwell_mod>=1) %>%
ggplot(aes(x=FPR, y=TPR, colour=factor(mod_reads_freq), group=mod_reads_freq)) + 
	geom_line() + 
	facet_grid(intensity_mod~dwell_mod) +
	xlab("False Positive Rate") + 
	ylab("True Positive Rate") + 
	labs(title="GMM logit test", color="Fraction of\nmodified reads") +
	theme_bw(21) +
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5))
dev.off()

pdf("ROC_ks_intensity_1sd.pdf", width=12, height=12)
filter(combined, method=="KS_int") %>%
filter(intensity_mod>=1, dwell_mod>=1) %>%
ggplot(aes(x=FPR, y=TPR, colour=factor(mod_reads_freq), gro_p=mod_reads_freq)) + 
	geom_line() + 
	facet_grid(intensity_mod~dwell_mod) +
	xlab("False Positive Rate") + 
	ylab("True Positive Rate") + 
	labs(title="KS intensity test", color="Fraction of modified reads") +
	theme_bw(21) +
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5))
dev.off()

pdf("ROC_ks_dwell_1sd.pdf", width=12, height=12)
filter(combined, method=="KS_dwell") %>%
filter(intensity_mod>=1, dwell_mod>=1) %>%
ggplot(aes(x=FPR, y=TPR, colour=factor(mod_reads_freq), gro_p=mod_reads_freq)) + 
	geom_line() + 
	facet_grid(intensity_mod~dwell_mod) +
	xlab("False Positive Rate") + 
	ylab("True Positive Rate") + 
	labs(title="KS dwell test", color="Fraction of modified reads") +
	theme_bw(21) +
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5))
dev.off()

auroc <- function(TPR, FPR){
	sens=TPR
	omspec=FPR
	height = (sens[-1]+sens[-length(sens)])/2
	width = -diff(omspec) # = diff(rev(omspec))
	return(sum(height*width))
}

pdf("auroc.pdf", width=18, height=18)
group_by(combined, method, mod_reads_freq, intensity_mod, dwell_mod) %>% 
	summarise(AUROC=auroc(TPR, FPR)) %>% 
	ggplot(aes(x=method, y=AUROC, fill=as.factor(mod_reads_freq))) + 
	geom_col(colour="black", position="dodge") + 
	facet_grid(intensity_mod~dwell_mod) +
	scale_fill_brewer() +
	theme_bw(12) +
	xlab("Testing Method") +
	ylab("AUROC") +
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5)) +
	labs(fill="Fraction of\nmodified reads")
dev.off()

pdf("auroc_1sd.pdf", width=18, height=18)
group_by(combined, method, mod_reads_freq, intensity_mod, dwell_mod) %>% 
	filter(intensity_mod>=1, dwell_mod>=1) %>%
	summarise(AUROC=auroc(TPR, FPR)) %>% 
	ggplot(aes(x=method, y=AUROC, fill=as.factor(mod_reads_freq))) + 
	geom_col(colour="black", position="dodge") + 
	facet_grid(intensity_mod~dwell_mod) +
	scale_fill_brewer() +
	theme_bw(21) +
	xlab("Testing Method") +
	ylab("AUROC") +
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5)) +
	labs(fill="Fraction of\nmodified reads")
dev.off()

pdf("auroc_lines.pdf", width=18, height=18)
group_by(combined, method, mod_reads_freq, intensity_mod, dwell_mod) %>% 
	summarise(AUROC=auroc(TPR, FPR)) %>% 
	ggplot(aes(colour=method, y=AUROC, x=mod_reads_freq)) + 
	geom_line() + geom_point() +
	facet_grid(intensity_mod~dwell_mod) +
	theme_bw(12) +
	xlab("Fraction of modified reads") +
	ylab("AUROC") +
	labs(color="Testing method")
dev.off()

pdf("auroc_lines_1sd.pdf", width=18, height=18)
group_by(combined, method, mod_reads_freq, intensity_mod, dwell_mod) %>% 
	filter(intensity_mod>=1, dwell_mod>=1) %>%
	summarise(AUROC=auroc(TPR, FPR)) %>% 
	ggplot(aes(colour=method, y=AUROC, x=mod_reads_freq)) + 
	geom_line() + geom_point() +
	facet_grid(intensity_mod~dwell_mod) +
	theme_bw(21) +
	xlab("Fraction of modified reads") +
	ylab("AUROC") +
	labs(color="Testing method")
dev.off()
