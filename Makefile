all : pms.pdf
html : pms.html

clean :
	rm -f *~ *.pdf *.dvi *.log *.aux *.bbl *.blg *.toc *.lol *.loa *.lox \
	    *.lot *.out *.html *.css *.png *.4ct *.4tc *.idv *.lg *.tmp *.xref vc.tex || true

LATEXFILES = $(shell find -name  '*.tex') pms.cls
LISTINGFILES = $(shell ls *.listing)
SOURCEFILES = $(LATEXFILES) $(LISTINGFILES)

pms.pdf: $(SOURCEFILES) pms.bbl vc.tex eapi-cheatsheet.pdf
	pdflatex pms
	pdflatex pms
	pdflatex eapi-cheatsheet
	pdflatex pms

pms.html: $(SOURCEFILES) pms.bbl
	@# need to do it twice to make the big env var table work
	mk4ht xhlatex pms
	mk4ht xhlatex pms
	@# some www servers ignore meta tags, resulting in a wrong charset.
	@# therefore recode the very few non-ascii characters
	recode -d l1..h3 pms.html
	@# work around irregularity in how links to longtables are
	@# formatted in the List of Tables
	LC_ALL=C sed -i -e '/<span class="lotToc" >&#x00A0;/{N;N;s/\(&#x00A0;<a \nhref="[^"]\+">\)\([0-9A-Z.]\+\)[ \n]/\2\1/}' pms.html
	@# fix xhtml syntax in longtable captions
	LC_ALL=C sed -i -e 's%</td>\( *<div class="multicolumn"\)%\1%;tx;b;:x;s%</tr>%</td>&%;t;n;bx' pms.html
	@# indent algorithms properly, and avoid adding extra vertical
	@# space in Konqueror
	LC_ALL=C sed -i -e 's/span style="width:/span style="display:-moz-inline-box;display:inline-block;height:1px;width:/' pms.html
	@# align algorithm line numbers properly
	LC_ALL=C sed -i -e '/<span class="ALCitem">/{N;s/\n\(class="[^"]\+">\)\([0-9]:<\/span>\)/\1\&#x2007;\2/}' pms.html

pms.bbl: pms.bib pms.tex vc.tex eapi-cheatsheet.pdf
	latex pms
	bibtex pms

eapi-cheatsheet.pdf: vc.tex
	pdflatex eapi-cheatsheet

eapi-cheatsheet-nocombine.pdf: vc.tex
	@# cheat sheet with separate pages, for proofreading
	pdflatex -jobname eapi-cheatsheet-nocombine \
	  '\PassOptionsToClass{nocombine}{leaflet}\input{eapi-cheatsheet.tex}'

vc.tex: pms.tex vc-git.awk
	/bin/sh ./vc

pms.dvi: $(SOURCEFILES) pms.bbl
	latex pms
	latex pms
	latex pms

upload:
	scp pms.pdf eapi-cheatsheet.pdf pms*.html pms.css \
	  dev.gentoo.org:public_html/pms/head/

.default: all

.phony: clean upload
