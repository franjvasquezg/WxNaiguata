Download Information and Files
==============================

The Services Tools Bundle (STB) is made available as a single
self-extracting installer bundle supporting all Solaris standard
operating systems and architectures.

Services Tools Bundle (STB) Installer
-------------------------------------
Release: 19.1.1
Build: 20190212

Oracle Explorer Data Collector
------------------------------
Release: 19.1.1
Build: 20190212

Remote Diagnostic Agent (RDA)
-----------------------------
Release: 19.1
Build: 20190115

Oracle Serial Number in EEPROM (SNEEP)
--------------------------------------
Release: 19.1.1
Build: 20190212

Lightweight Availability Collection Tool (LWACT)
------------------------------------------------

The Lightweight Availability Collection Tool (LWACT) is no longer shipped as 
part of the Services Tool Bundle (STB). It was last included in STB 8.12. 
The information it provided is available from Enterprise Manager Ops Center, 
among other sources.

Service Tag (ST) packages
-------------------------
Release: 1.1.5

Oracle Autonomous Crashdump Tool
--------------------------------
Release: 8.17

Oracle Autonomous Crashdump Tool (ACT) is not supported on Solaris 11 Express. 
When launching an STB installation on Solaris 11 Express, you will see the
warning "STB-02023: IPS installation of support/act failed".
This warning can be ignored because ACT is not supported on Solaris 11 Express.

Solaris Architecture and Version Information
============================================

The STB is supported for the following platforms:
- Solaris/SPARC versions 11, 11 Express, 10, 9, and 8.
- Solaris/x86 versions 11, 11 Express, 10, and 9.

On Solaris 11 and Solaris 11 Express, only Explorer/RDA, SNEEP, and ACT are
installed. 
For Solaris 9/x86 no service tags are installed.
The Explorer package is also included in Solaris 11.x distributions; it is
installed by default with Solaris 11.3 GA onwards and hence, for such
installations, can only be updated from Solaris SRU releases. It can no 
longer be updated from an IPS package (that is, from STB).

Note:
The available download file is a zip file, which contains this file and the
install_stb.sh for all the platforms mentioned above.

Documentation:
==============
Check the following Knowledge article on My Oracle Support, which has 
attachments and links for all included products:
https://support.oracle.com/rs?type=doc&id=1153444.1

Inter-dependencies in STB components:
=====================================
There are certain dependency criteria with a few application components bundled
in STB, which need to be met to ensure seamless installation.

The list of these criteria and their corresponding dependencies are as follows:

Explorer and RDA:
-----------------
On Solaris 8, 9, and 10 Explorer constitutes the following application packages:
- SUNWexplo
- SUNWexplu
- SUNWrda
(Explorer delegates some of its collections to RDA.)

On Solaris 11 the IPS package with partial FMRI pkg://oraddt/support/explorer
is installed, which contains both Explorer and RDA.

Service Tags:
-------------
Service Tags constitutes the following application packages:
- SUNWpsn
- SUNWservicetagr
- SUNWservicetagu
- SUNWstosreg
- SUNWsthwreg

On Solaris/SPARC 8 and 9, Service Tags require the following packages
for successful installation:
- SUNWcar
- SUNWkvm
- SUNWcsr
- SUNWcsu
- SUNWcsd
- SUNWcsl

On Solaris 10, Service Tags require the following packages for
successful installation:
- SUNWcar
- SUNWkvm
- SUNWcsr
- SUNWcsu
- SUNWcsd
- SUNWcsl
- SUNWlxml
