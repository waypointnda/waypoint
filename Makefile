NPM_BIN=node_modules/.bin
COMMONMARK=$(NPM_BIN)/commonform-commonmark
DOCX=$(NPM_BIN)/commonform-docx
HTML=$(NPM_BIN)/commonform-html
LINT=$(NPM_BIN)/commonform-lint
CRITIQUE=$(NPM_BIN)/commonform-critique
JSON=$(NPM_BIN)/json
MUSTACHE=$(NPM_BIN)/mustache

FORMATS=docx pdf odt rtf
PAPERS=letter a4
VARIANTS=long short

all: $(foreach variant,$(VARIANTS),$(foreach paper,$(PAPERS),$(foreach format,$(FORMATS),$(addsuffix -$(variant)-$(paper).$(format),build/nda)))) build/nda.html

DOCX_FLAGS= --styles styles.json -n outline --left-align-title --indent-margins --smartify

build/terms-letter.docx: build/nda.json styles.json | build $(DOCX) $(JSON)
	$(JSON) form < $< | $(DOCX) $(DOCX_FLAGS) --title "$(shell $(JSON) frontMatter.title < $<)" --edition "$(shell $(JSON) frontMatter.edition < $<)" > $@ /dev/stdin

build/terms-a4.docx: build/nda.json styles.json | build $(DOCX) $(JSON)
	$(JSON) form < $< | $(DOCX) --a4 $(DOCX_FLAGS) --title "$(shell $(JSON) frontMatter.title < $<)" --edition "$(shell $(JSON) frontMatter.edition < $<)" > $@ /dev/stdin

build/nda-long-%.docx: build/certificate-%.docx build/terms-%.docx signatures-%.docx
	docxcompose $^ -o $@

build/nda-short-%.docx: build/springboard-%.docx signatures-%.docx
	docxcompose $^ -o $@

build/certificate-%.docx: certificate-%.docx view.json docxreplace | build
	cp $< $@
	./docxreplace "$@"

build/springboard-%.docx: springboard-%.docx view.json docxreplace | build
	cp $< $@
	./docxreplace "$@"

build/%.json: %.md view.json | build $(MUSTACHE) $(COMMONMARK)
	$(MUSTACHE) view.json  $< | $(COMMONMARK) parse > $@

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

$(COMMONMARK) $(DOCX) $(HTML) $(JSON) $(MUSTACHE):
	npm ci

.PHONY: lint critique clean

lint: build/nda.json | $(LINT) $(JSON)
	$(JSON) form < $< | $(LINT) | $(JSON) -a message | sort -u

critique: build/nda.json | $(CRITIQUE) $(JSON)
	$(JSON) form < $< | $(CRITIQUE) | $(JSON) -a message | sort -u

clean:
	rm -rf build

DOCKER_TAG=waypoint-one-way-build

docker:
	bash -c "trap 'docker rm $(DOCKER_TAG)' EXIT; \
		docker build -t $(DOCKER_TAG) .; \
		docker run --name $(DOCKER_TAG) $(DOCKER_TAG); \
		docker cp $(DOCKER_TAG):/workdir/build ."
