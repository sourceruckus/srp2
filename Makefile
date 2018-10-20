MAKEFILE      =	Makefile

PRODUCT	      =	srp
VERSION	      =	2.5.0
PACKAGEREV    =	1
DEVTAG	      = dev

# Whereas the core SRP source files don't really require anythong beyond
# Python 2.3 or so, setting this officially to 2.5 means package maintainers
# can use anything added in 2.4 or 2.5 in their PREPOSTLIBs (the subprocess
# module, function decorators, etc).
MIN_PYTHON=2.5
PYTHON := $(shell which python)

PREFIX = /usr
BINDIR = ${PREFIX}/bin
LIBDIR = ${PREFIX}/lib/srp
MANDIR = ${PREFIX}/share/man/man8
INFODIR = ${PREFIX}/share/info
DOCDIR = ${PREFIX}/share/doc/${PRODUCT}-${VERSIONSTRING}

# this is used to install into another rootfs
# example: you've booted up into source ruckus linux 3.0 and you
# want to install into your redhat rootfs which is mounted on
# /mnt/rh_root...  you just change SRP_ROOT_PREFIX to /mnt/rh_root
# and everything is taken care of.
SRP_ROOT_PREFIX = 

RUCKUS = ${PREFIX}/src/ruckus

RUCKUS_for_makefile = ${SRP_ROOT_PREFIX}${PREFIX}/src/ruckus

# how can we recursively create directories?
# works on: linux, hpux 10.20
RMKDIR = /bin/mkdir -p

# how can we get archive copies of a file?
# works on: linux
ACOPY = /bin/cp -a
# works on: hpux 10.20
#ACOPY="/bin/cp -pr"

# what shell should we invoke for our scripts?
SH = /bin/bash

# what is the preferred checksum algorithm?
CHECKSUM = "sha1"

BIN =	srp

LIBS =	sr.py \
	sr_package2.py \
	utils.py

DOCS =	AUTHORS \
	BUGS \
	BUGS-SQUASHED \
	COPYING \
	ChangeLog \
	INSTALL \
	NEWS \
	README \
	TODO \
	examples

CONFIG = 	sr.py

MAN = 		srp.8
TEXINFO	= 	srp.texinfo
INFO = 		srp.info
PDF =		srp.pdf

SUBDIRS=examples

OFFICIALDIR=.
TEMPLATE_KEYS =	PYTHON LIBDIR VERSIONSTRING SRP_ROOT_PREFIX RUCKUS RMKDIR ACOPY SH CHECKSUM BINDIR

.PHONY: all mostly_all configure info ruckusdir install install-info dist
.PHONY: install-dist-srp uninstall clean
.PHONY: distclean docs man
.PHONY: ${SUBDIRS} ${SUBDIRS:=-clean} ${SUBDIRS:=-distclean}

all: configure mostly_all

include Makefile.common

mostly_all: bin libs man info

bin: ${BUILDDIR}/${BIN}

configure:
	PYTHON=${PYTHON} ./python-test ${MIN_PYTHON}
	@echo "PYTHON: ${PYTHON}"
	@if [ -z "${PYTHON}" ]; then \
	  echo "Couldn't find a suitable version of Python!"; \
	  echo "${DISTNAME} requires Python >= ${MIN_PYTHON}!"; \
	  echo "It also requires a few bugs to be fixed, see python-test.d for details."; \
	  exit 1; \
	fi

libs: ${LIBS:%=${BUILDDIR}/%}
	${PYTHON} -c "import compileall; compileall.compile_dir('${BUILDDIR}')"

man: ${BUILDDIR}/${MAN} ${BUILDDIR}/${MAN}.gz 

info: ${BUILDDIR}/${TEXINFO} ${BUILDDIR}/${INFO} ${BUILDDIR}/${INFO}.gz

docs: mostly_all docs-pdf docs-html examples

docs-pdf: ${BUILDDIR}/${PDF}

docs-html: ${BUILDDIR}/${TEXINFO}
	makeinfo --html -o ${BUILDDIR}/html $<

ruckusdir:
	mkdir -p ${DESTDIR}${RUCKUS_for_makefile}/build
	mkdir -p ${DESTDIR}${RUCKUS_for_makefile}/package
	mkdir -p ${DESTDIR}${RUCKUS_for_makefile}/tmp
	mkdir -p ${DESTDIR}${RUCKUS_for_makefile}/installed
	mkdir -p ${DESTDIR}${RUCKUS_for_makefile}/brp

install: install-bin install-libs install-man install-info ruckusdir

install-docs: install-pdf install-html install-examples

install-bin: bin
	install -vD ${BUILDDIR}/${BIN} ${DESTDIR}${BINDIR}/${BIN}

install-libs: libs
	install -vd ${DESTDIR}${LIBDIR}
	install -vD --mode=644 ${LIBS:%=${BUILDDIR}/%} ${DESTDIR}${LIBDIR}
	install -vD --mode=644 ${BUILDDIR}/*.pyc ${DESTDIR}${LIBDIR}
	install -vD --mode=644 Makefile.common ${DESTDIR}${LIBDIR}/Makefile.common
	install -vD python-test ${DESTDIR}${LIBDIR}/python-test

install-man: man
	install -vD --mode=644 ${BUILDDIR}/${MAN}.gz ${DESTDIR}${MANDIR}/${MAN}.gz


install-info: info
	install -vD --mode=644 ${BUILDDIR}/${INFO}.gz ${DESTDIR}${INFODIR}/${INFO}.gz
	install-info ${INFODIR}/${INFO}.gz ${DESTDIR}${INFODIR}/dir

install-pdf: docs-pdf
	install -vD --mode=644 ${BUILDDIR}/${PDF} ${DESTDIR}${DOCDIR}/${PDF}

install-html: docs-html
	cd ${BUILDDIR}/html && find . -type d -exec install -vd ${DESTDIR}${DOCDIR}/html/{} \;
	cd ${BUILDDIR}/html && find . ! -type d -exec install -v --mode=644 {} ${DESTDIR}${DOCDIR}/html/{} \;

install-examples: mostly_all
	cd examples && find . -type d -a ! -path \*/CVS\* -a ! -path \*/${BUILDDIR}\* -exec install -vd ${DESTDIR}${DOCDIR}/examples/{} \;
	cd examples && find . ! -type d -a ! -path \*/CVS\* -a ! -path \*/${BUILDDIR}\* -exec install -v --mode=644 {} ${DESTDIR}${DOCDIR}/examples/{} \;

dist: dist-srp

install-dist-srp: ruckusdir dist-srp mostly_all
	./${BUILDDIR}/srp -i ${DIST_SRP}

uninstall: uninstall-bin uninstall-libs uninstall-man uninstall-info
	rmdir --ignore-fail-on-non-empty ${DESTDIR}${RUCKUS_for_makefile}/build
	rmdir --ignore-fail-on-non-empty ${DESTDIR}${RUCKUS_for_makefile}/package
	rmdir --ignore-fail-on-non-empty ${DESTDIR}${RUCKUS_for_makefile}/tmp
	rmdir --ignore-fail-on-non-empty ${DESTDIR}${RUCKUS_for_makefile}/installed
	rmdir --ignore-fail-on-non-empty ${DESTDIR}${RUCKUS_for_makefile}/brp
	rmdir --ignore-fail-on-non-empty ${DESTDIR}${RUCKUS_for_makefile}

uninstall-docs: uninstall-pdf uninstall-html uninstall-examples

uninstall-bin:
	rm -f ${DESTDIR}${BINDIR}/${BIN}

uninstall-libs:
	rm -f ${LIBS:%=${DESTDIR}${LIBDIR}/%}
	rm -f ${DESTDIR}${LIBDIR}/*.pyc
	rm -f ${DESTDIR}${LIBDIR}/python-test
	rm -f ${DESTDIR}${LIBDIR}/Makefile.common
	rmdir --ignore-fail-on-non-empty ${DESTDIR}${LIBDIR}

uninstall-man:
	rm -f ${DESTDIR}${MANDIR}/${MAN}.gz

uninstall-info:
	install-info --delete ${DESTDIR}${INFODIR}/${INFO}.gz ${DESTDIR}${INFODIR}/dir
	rm -f ${DESTDIR}${INFODIR}/${INFO}.gz

uninstall-pdf:
	rm -f ${DESTDIR}${DOCDIR}/${PDF}
	rmdir --ignore-fail-on-non-empty ${DESTDIR}${DOCDIR}

uninstall-html:
	rm -rf ${DESTDIR}${DOCDIR}/html
	rmdir --ignore-fail-on-non-empty ${DESTDIR}${DOCDIR}

uninstall-examples:
	rm -rf ${DESTDIR}${DOCDIR}/examples
	rmdir --ignore-fail-on-non-empty ${DESTDIR}${DOCDIR}

clean: ${SUBDIRS:=-clean}
	find . \( -name \*~ -o -name .\#\* -o -name \*.pyc \) -exec rm -fv {} \;
	rm -rf ${BUILDDIR} ${DISTNAME}

distclean: clean ${SUBDIRS:=-distclean}
	rm -f ${PRODUCT}-${VERSION}*.tar.bz2
	rm -f ${PRODUCT}-${VERSION}*.srp
	rm -f ${PRODUCT}-*${VERSION}*.brp
	rm -f examples/*/Makefile.common

${SUBDIRS}:
	${MAKE} -C $@

${SUBDIRS:=-clean}:
	${MAKE} -C ${@:-clean=} clean

${SUBDIRS:=-distclean}:
	${MAKE} -C ${@:-distclean=} distclean
