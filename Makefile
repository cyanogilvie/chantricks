VER="1.0.3"
TCLSH="tclsh"
DESTDIR=
PREFIX="/usr/local"

all: tm docs

tm/chantricks-$(VER).tm: chantricks.tcl
	mkdir -p tm
	cp chantricks.tcl tm/chantricks-$(VER).tm

doc/chantricks.n: doc/chantricks.md
	pandoc --standalone --from markdown --to man doc/chantricks.md --output doc/chantricks.n

README.md: doc/chantricks.md
	pandoc --standalone --from markdown --to gfm doc/chantricks.md --output README.md

install-tm: tm
	mkdir -p "$(DESTDIR)$(PREFIX)/lib/tcl8/site-tcl/"
	cp tm/chantricks-$(VER).tm "$(DESTDIR)$(PREFIX)/lib/tcl8/site-tcl/"

tm: tm/chantricks-$(VER).tm

test: all
	$(TCLSH) tests/all.tcl $(VER) $(TESTFLAGS)

install: install-tm install-doc

docs: doc/chantricks.n README.md

install-doc: docs
	mkdir -p "$(DESTDIR)$(PREFIX)/man/mann"
	cp doc/chantricks.n "$(DESTDIR)$(PREFIX)/man/mann/"

clean:
	-rm -r tm doc/chantricks.n

.PHONY: all test tm install docs install-tm install-doc clean
