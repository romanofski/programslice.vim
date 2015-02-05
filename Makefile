
.PHONY: docs clean
docs: README.html

clean:
	rm -f README.html

README.html: README.asciidoc
	asciidoc -a source-highlighter=pygments README.asciidoc
