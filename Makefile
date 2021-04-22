VER="1.0.1"
TCLSH="tclsh"
DESTDIR="/usr/local"

all: tm/chantricks-$(VER).tm docs

tm/chantricks-$(VER).tm: chantricks.tcl
	mkdir -p tm
	cp chantricks.tcl tm/chantricks-$(VER).tm

test: all
	$(TCLSH) tests/all.tcl $(VER) $(TESTFLAGS)

install: install-tm install-doc

install-tm: tm
	mkdir -p "$(DESTDIR)/lib/tcl8/site-tcl/"
	cp tm/chantricks-$(VER).tm "$(DESTDIR)/lib/tcl8/site-tcl/"

docs: doc/chantricks.n README.md

doc/chantricks.n: doc/chantricks.md
	pandoc --standalone --from markdown --to man doc/chantricks.md --output doc/chantricks.n

README.md: doc/chantricks.md
	pandoc --standalone --from markdown --to gfm doc/chantricks.md --output README.md

install-doc: docs
	mkdir -p "$(DESTDIR)/man/mann"
	cp doc/chantricks.n "$(DESTDIR)/man/mann/"

clean:
	-rm -r tm doc/chantricks.n

.PHONY: all test tm install docs install-tm install-doc clean
