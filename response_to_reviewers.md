# Aaron's comments

Sweet! Here’s my comments, though keep in mind that this is after about 30 hours w/o sleep, so several grains of salt required:

> Specific comments:
> Major:
> - How do the wrapper functions for running kallisto and Salmon in scater deal with UMI data?  e.g. I don’t believe the current implementation of Salmon has built-in functionality for handle scRNA-seq data with UMIs?

Um. They don’t, I guess?

> - Could the authors add an assessment of how long it takes to perform basic tasks depending on number of genes/cells? With new droplet technologies to sort cells, will R be the best tool to analyze potentially 100s of 1000s of cells?

Point out C++ extension to allow memory- and time-efficient calculations of QC metrics, manipulations, etc. Scales to Zeisel data set (3000 cells, 10000 genes post-filtering) on a desktop machine (8 GB RAM). Larger data sets inevitably require HPC resources; perhaps can get more savings with sparse matrix representations, but this is not easily compatible with downstream methods (e.g., t-SNE, PCA) requiring the full matrix. So just suck it up and fork out some cash.

> - Are there functions to extract the highly variable (or expressed) genes? There are options to visualize most highly expressed features and dim reduction plots that use highly variable genes, but how to extract?  Also, how would you decide what set of genes to look at (e.g. DE genes, highly expressed or highly variable genes) depending on if you were interested in rare cell types versus identifying common major cell types?  Is there an option to control this in the data visualization tools?

Extended in scran - deviation-from-median (DM) method in Kolodziejczyk et al., CV2-based method (technicalCV2) by Brennecke et al., and Lun et al.’s variance of log-expression based methods. HVG selection can be a complicated procedure, so plotPCA/plotTSNE just uses sample variance as a quick-and-dirty default. However, selection based on these more complex methods can be performed by specifying the detected HVGs in feature_set=, allowing consideration of technical contributions to the variance, fitting of the mean-variance trend, rigorous hypothesis testing for HVGs, etc. See example from workflow for how this gets accommodated.

Also planning on testing and implementing the Gini index (Giniclust, can’t remember the paper) as a HVG selection option in scran; focuses on genes that are upregulated in rare cell types, to highlight these cells upon visualisation.

> - For normalization, does it make sense to use bioC packages such as svaseq where if you are trying to discover biological conditions (e.g. novel cell types) from scRNA-seq data, you could be removing the interesting biological variation in the latent factors? What are the author’s opinions of using spike-ins or control genes? Could the authors provide a discussion on this topic or at least refer the reader to other papers to help guide them?

Yes, you could potentially be removing interesting biological variation in the latent variables, in cases where discovery of new and interesting things is the main aim. Perhaps a note about this would be prudent.

Also, see F1000 workflow for discussion of benefits of spike-in normalisation vs non-DE normalisation. Blah blah blah.

> - How did the authors decide on the selection of variable genes? Is there a reason the authors applied the specific normalization of FPKMs to identify the variable genes instead of something like the distance-to-median approach in Kolodziejczyk et al. (2015) Cell Stem Cell. I would like to see a larger discussion of this and I would like the authors to consider other approaches of identifying highly variable genes and how this affects their downstream clustering results?

We used variance of log-values, I believe, in selecting the HVGs within plotPCA, etc.? This has several advantages over CV2-based methods:

1) plotPCA/plotTSNE use log-expression values, so HVGs based on high variance of logged values -> high Euclidean distances, maximise log-fold change and discrimination between cells.
2) log-transformation protect against genes with outlier expression patterns, i.e., very strong expression in only one cell.
3) logged counts are more normal-ish than the raw counts themselves, making it easier to construct tests for significance of HVG’ness.

In general, the quantitative differences between HVG selection methods are modest. Strong HVGs distinguishing cell types get picked up no matter what you do, so you should be able to see separate clusters. It is likely that differences occur in visualisation of more subtle features, e.g., rare cell types (CV2 is better, as it selects outlier-like genes) or weak clusters (where log might be better if it selects more discriminatory genes).

Note, the fact that we’re using FPKMs is irrelevant here, as the length scaling factor cancels out when computing the sample variance within a gene. No mean-variance trend is fitted so the absolute values don’t matter.

> - What if researchers have two types of data (e.g. scRNA-Seq and DNA methylation in scMT-seq https://genomebiology.biomedcentral.com/articles/10.1186/s13059-016-0950-z). How does the SCEset container handle this?  Are there different assays that would allow multiple types of information to be held in the same object?

Not well, as it's outside the design remit of the single cell expression set. But Vince Carey’s MultiAssay object (or something like that, can’t remember exact name) can be used.

> - Stegle et al. 2015 noted there is a big 3’ bias in scRNA-Seq protocols (particularly for the SMART-Seq protocol used by Fluidigm). Therefore, normalizing for transcript length (e.g. FPKM) can lead to an underestimate of expression in long transcripts and over expression in short transcripts. I would like to see the authors create a data visualization function in scater that would allow a user to check this in their own data.

Sure, I guess.

> Minor:
> - Pg 3, line 26: could the authors include new salmon reference listed in bioRxiv (http://biorxiv.org/content/early/2016/08/30/021592)

Yeah, fine, whatever. At least we know who this reviewer is likely to be, then. Who else would care?

> Reviewer: 2
>
> Comments to the Author
> The work by McCarthy and colleagues describes an R package to pre-process and QC single-cell RNA-seq data. The authors did a very nice job with documentation at all levels: manuscript, supplements and especially with the package vignette/case study, which was also provided as supplementary information.
>
> The package itself does not introduce any novel method to QC or normalize single-cell RNA-seq. Rather, it aims at becoming a one-stop solution for loading and organizing single-cell data, which can then be fed to existing methods. While the absence of novel analytical strategies diminishes the scope of the work and may somewhat mitigate its impact, I note that the design choices behind this package, particularly the data structures, are very elegant and polished, and fit well with the R/Bioconductor universe. Visualizations are useful, appealing and pleasant. A regular R user will immediately recognize the quality of this package, which therefore has the potential to become "the" choice for single-cell RNA-seq QC, pretty much like edgeR/DESeq are for differential gene expression.
>
> My points are minor and optional:
>
> - the authors may consider allocating more text to outlier identification. They provide a reference, but it may be worth summarizing briefly how outliers are identified. The metrics used for outlier detection are listed in the package vignette, but I feel this is important information that should go in the main text.

Okay…. are these the QC outliers detected with the PCA-based method in mvoutlier? Guess we could talk about it a bit more?

> - some packages already provide routines for batch correction. This is the case, for instance, of scde. Indeed, scde requires very little upstream pre-processing, mostly just filtering out outliers. So there is no one-size-fits-all workflow. In this regard, I wonder whether the authors might further elaborate on Figure 1 and Supplementary Figure 3 by providing schematics of the most common workflows for the most popular tools, highlighting which portions would be scater-specific and which would be third-party tool-specific?

I’m pretty sure scde requires a bit more work… at the very least, QC on genes and cells isn’t so simple as to be fobbed off in a single sentence. Probably mention the inputs to each of these tools; methods require a count matrix (scde, edgeR) or expression matrix (monocle) or log-expression matrix (plotTSNE, PCA, etc.). Last lot will require batch correction as batches cannot be modelled in the methods themselves.

scde appears to provide one function "clean.counts" for "QC" before running its functions, but this function will only filter cells by minimum library size and genes by minimum total reads and minimum number of cells a gene should be seen in. Thus, preparing a dataset with scater upstream of using scde offers many more possibilities for QC of both cells and genes. scde indeed offers the option to include a known batch effect in its DE models - scater again offers many options for exploring batch effects that should prove useful upstream of modelling with scde.

*Can very easily show some possible workflows with an extra Supp Fig for, for example DE with scde, DE with edgeR, clustering with SC3, ...*


> - the authors did a good job highlighting the possible influence of cell cycle on measurements. I wonder whether the effect of cell cycle should be also mentioned in the latent variable section of the case study. It is not infrequent that a treatment significantly alters the cell cycle, partially masking the phenotype of interest. This can be explicitly investigated by using cell cycle genes to drive PCA, for example, as the authors pointed out. However, there may be cases where the user did not suspect an involvement of cell cycle, but latent variable analysis may reveal it, prompting a more directed investigation.

Fine. Can combined with cyclone (implemented in scran) to determine if levels of the latent variable are associated with cell cycle classification.

> - I wonder whether scater might provide some simple summary stats regarding the distribution of genes. Roughly, genes may show 4 types of distributions: 1) noise 2) zero inflated 3) bimodal 4) log normal. It would be nice if scater provided related information, perhaps upon GMM fitting, such as the number of genes in each class for every sample, and then some basics such as the median expression and standard deviation of log normally distributed genes etc.

Sounds like a pain, not sure what it would tell you. Doesn’t tell you anything about QC - is having lots of bimodal genes good or bad? Who knows? We already get zero-inflation diagnostics from drop-out rate plots. Similarly, it doesn’t tell you much about the interesting genes - log-normally distributed genes can be high or low variance, in which case it is interesting and not interesting respectively. Finally, it’s a pain to draw a clear boundary between noise and zero-inflation (as large dispersions will automatically have a point mass at zero), bimodal and zero inflation (probably the same, if the mean of the non-zero component is large enough), and bimodal and log-normal (test for bimodality - can’t remember the name - seems to involve a few iffy assumptions).

> - minor details: how did the authors set the perplexity parameter of tSNE? How many of the top variable genes are used in PCA and dimensionality reduction in general? Are violin plots scaled to take into account that different groups might have different number of cells?

Default perplexity (20?), 500 genes, dunno, respectively.

-------------------
