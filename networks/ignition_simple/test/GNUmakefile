NDEBUG := 
MPI    :=
OMP    :=

COMP := gfortran

MKVERBOSE := t

MICROPHYSICS_HOME := ../../..

# programs to be compiled
programs += testburn
#programs += eval
#programs += testjacobian

f90sources += testburn.f90

EOS_DIR := helmholtz
NETWORK_DIR := ignition_simple
INTEGRATOR_DIR := BS

TEST_DIR = $(MICROPHYSICS_HOME)/networks/ignition_simple/test

ALL:

include $(MICROPHYSICS_HOME)/GMicrophysics.mak

ALL: $(pnames)

# include the fParallel Makefile rules
include $(BOXLIB_HOME)/Tools/F_mk/GMakerules.mak

