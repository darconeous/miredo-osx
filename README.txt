Miredo for OSX Preview 1
http://www.deepdarc.com/2007/02/21/miredo-osx/
Packaged by Robert Quattlebaum <darco@deepdarc.com>
-----------

This package contains the following software packages:
	Miredo (GPL) - http://www.remlab.net/miredo/
	libJudy (LGPL) - http://judy.sourceforge.net/
	OSX tuntap drivers (Other License, see COPYING in tuntap
		dir) - http://www-user.rhrk.uni-kl.de/~nissler/tuntap/

Anything else included in this package which is not a part of
the above three projects can be considered public domain unless
clearly marked otherwise.

A diff has been applied to the stock 1.0.6 miredo, which can be
found in misc/miredo.diff.

IMPORTANT: This package is a prerelease version intended for
early adopters, and is NOT intended for widespread deployment.
If you decide to install and use this experimental package, you
should subscribe to the miredo mailing list, paying serious
attention to any security advisories.

In this release, Miredo does not drop privileges! This means
that if a remote code execution flaw is found in miredo 1.0.6,
then your machine could be easily compromised. (Miredo usually
drops privileges when running, which makes the effects of a
remote code execution hole less damaging) Just be aware of it,
and don't "install and forget".

*** Important Build targets:

make package
	Builds the installer package, and creates both a zip
	and a tarball

make zip
	Builds the installer package, building a zip

make tarball
	Builds the installer package, building a tarball

make clean
	Wipes clean the build and all intermediate files. (erases
	the build directory, any built packages, etc)


*** Obscure Build Targets:

make miredo
	Builds miredo. (Will also build libjudy)

make tuntap
	Builds the tuntap drivers.

make uninst-script
	Builds the uninstall script

make libjudy
	Builds both x86 and ppc versions of libjudy
	(static-link only)

make libjudy-bootstrap
	Bootstraps libjudy. You shouldn't have to use this
	target.

make mrproper
	A more complete version of the 'clean' target. Rolls
	back any autoconf stuff in the packages. Don't do this
	unless you have autoconf, automake, and libtool
	installed and up to date.

