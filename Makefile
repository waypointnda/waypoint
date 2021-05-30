NPM_BIN=node_modules/.bin
COMMONMARK=$(NPM_BIN)/commonform-commonmark
DOCX=$(NPM_BIN)/commonform-docx
HTML=$(NPM_BIN)/commonform-html
LINT=$(NPM_BIN)/commonform-lint
CRITIQUE=$(NPM_BIN)/commonform-critique
JSON=$(NPM_BIN)/json

FORMATS=docx pdf odt rtf
PAPERS=letter a4

all: $(foreach format,$(FORMATS),$(foreach paper,$(PAPERS),$(addsuffix .$(format),$(addsuffix -$(paper),build/nda)))) build/nda.html

DOCX_FLAGS= --styles styles.json -n outline --left-align-title --indent-margins --smartify

build/terms-letter.docx: build/nda.json styles.json | build $(DOCX) $(JSON)
	$(JSON) form < $< | $(DOCX) $(DOCX_FLAGS) --title "$(shell $(JSON) frontMatter.title < $<)" --edition "$(shell $(JSON) frontMatter.edition < $<)" > $@ /dev/stdin

build/terms-a4.docx: build/nda.json styles.json | build $(DOCX) $(JSON)
	$(JSON) form < $< | $(DOCX) --a4 $(DOCX_FLAGS) --title "$(shell $(JSON) frontMatter.title < $<)" --edition "$(shell $(JSON) frontMatter.edition < $<)" > $@ /dev/stdin

build/nda-%.docx: certificate-%.docx build/terms-%.docx signatures-%.docx
	docxcompose $^ -o $@

build/%.json: %.md | build $(COMMONMARK)
	$(COMMONMARK) parse $< > $@

build/%.html: build/%.json | $(HTML)
	$(JSON) form < $< | $(HTML) --html5 --lists --ids --smartify --title "$(shell $(JSON) frontMatter.title < $<)" --edition "$(shell $(JSON) frontMatter.edition < $<)" > $@

build/%.pdf: build/%.docx
	soffice --headless --convert-to pdf --outdir build $<

build/%.odt: build/%.docx
	soffice --headless --convert-to odt --outdir build $<

build/%.rtf: build/%.docx
	soffice --headless --convert-to rtf --outdir build $<

build:
	mkdir -p build

$(COMMONMARK) $(DOCX) $(HTML) $(JSON):
	npm ci

.PHONY: lint critique clean

lint: build/nda.json | $(LINT) $(JSON)
	$(JSON) form < $< | $(LINT) | $(JSON) -a message | sort -u

critique: build/nda.json | $(CRITIQUE) $(JSON)
	$(JSON) form < $< | $(CRITIQUE) | $(JSON) -a message | sort -u

clean:
	rm -rf build
