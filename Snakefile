rule all:
    'main.pdf'

rule compile_main:
    input:
        'main.tex',
        'figure/figure3_alt.pdf'
    output:
        'main.pdf'
    shell:
        """
        pdflatex main
        bibtex main
        pdflatex main
        pdflatex main
        pdflatex main
        """
