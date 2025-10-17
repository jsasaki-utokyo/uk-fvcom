# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the UK FVCOM (Finite Volume Coastal Ocean Model) repository, maintained by the UK FVCOM Users' group. It contains modifications to the official FVCOM v5.0 release, with the main addition being the **FABM (Framework for Aquatic Biogeochemical Models) coupler** developed and maintained by Plymouth Marine Laboratory and partners.

FVCOM is a prognostic, unstructured-grid, Finite-Volume, free-surface, three-dimensional primitive equations coastal ocean circulation model developed by UMASSD-WHOI. This repository includes FABM v1 integration (currently in beta) for coupling with biogeochemical models like ERSEM.

## Build System

### CMake Build (Recommended)

The project uses CMake as the primary build system:

```bash
# Basic configuration
cmake -S . -B build

# With FABM enabled
cmake -S . -B build -DFVCOM_USE_FABM=ON -DFABM_BASE=/path/to/fabm

# Common options:
# -DFVCOM_USE_FABM=ON              # Enable FABM coupling
# -DFVCOM_USE_DOUBLE_PRECISION=ON  # Use double precision
# -DFVCOM_USE_WET_DRY=ON           # Enable wetting-drying (default ON)
# -DFVCOM_USE_MULTIPROCESSOR=ON    # Enable MPI parallelization

# Build
cmake --build build

# Executable will be: build/FVCOM_exe
```

Key CMake configuration points (CMakeLists.txt:1):
- Source directory: `FVCOM_source` is referenced but actual source is in `src/`
- Dependencies: NetCDF (required), METIS, Julian libraries
- FABM integration: Requires setting `FABM_BASE` to FABM source directory

### Make.inc Build System (Legacy)

Multiple `make_*.inc` files exist in `src/` for different platforms and configurations:
- `make_PML_ceto.inc` - PML workstation build
- `make_PML_ARCHER.inc` - ARCHER HPC build
- `make_lakeErie.inc` - Lake Erie specific configuration

These files define compiler flags, library paths, and feature flags. Reference `src/make_PML_ceto.inc:1` for a complete example.

### Required Dependencies

- **NetCDF** with Fortran bindings (mandatory)
- **HDF5** (for NetCDF4)
- **MPI** (Intel MPI or similar for parallel runs)
- **METIS** (for domain partitioning, included in `src/libs/metis/`)
- **Julian** library (for date/time, included in `src/libs/julian/`)
- **FABM** (optional, for biogeochemistry - external dependency)

## Code Structure

### Main Source Directory: `src/`

The source code is organized as Fortran modules and subroutines:

**Core modules** (mod_*.F):
- `mod_main.F` - Main data structures and global variables
- `mod_par.F` - Parallel processing utilities
- `mod_prec.F` - Precision definitions
- `mod_types.F` - Type definitions
- `mod_utils.F` - Utility functions
- `mod_time.F` - Time management
- `mod_clock.F` - Simulation clock

**Physics modules**:
- `mod_force.F` - External forcing
- `mod_spherical.F` - Spherical coordinates
- `mod_semi_implicit.F` - Semi-implicit time stepping
- `mod_ice.F`, `mod_ice2d.F` - Ice model
- `mod_gotm.F` - GOTM turbulence model integration

**FABM Integration**:
- `mod_fabm_3D.F` - Main FABM 3D coupling module (src/mod_fabm_3D.F:1)
- `mod_fabm_data.F` - FABM data structures
- `mod_fabm_3D_ge_sediment.F` - FABM-sediment interaction

**Boundary conditions and nesting**:
- `mod_obcs.F`, `mod_obcs2.F`, `mod_obcs3.F` - Open boundary conditions
- `mod_nesting.F` - Grid nesting
- `mod_esmf_nesting.F` - ESMF-based nesting

**I/O and visualization**:
- `mod_ncdio.F` - NetCDF I/O
- `mod_nctools.F` - NetCDF utilities
- `mod_visit.F` - VisIt in-situ visualization

**Main program**: `fvcom.F` (src/fvcom.F:1)

### Subdirectories

- `src/libs/` - Bundled libraries (METIS, Julian)
- `src/BIO_source/` - Biological model components
- `src/input/` - Input file handling utilities
- `src/utilities/` - Pre/post-processing utilities
- `src/testing/` - Test cases

## Compilation Flags

Key preprocessor flags (defined in make.inc or CMake):

**Required (one must be chosen)**:
- `-DLIMITED_NO` / `-DLIMITED_1` / `-DLIMITED_2` - Upwind limiter scheme
- `-DGCN` / `-DGCY1` / `-DGCY2` - Solid boundary treatment

**Common options**:
- `-DDOUBLE_PRECISION` - Use double precision floats
- `-DSINGLE_OUTPUT` - Output in single precision even with double precision computation
- `-DSPHERICAL` - Spherical coordinate system
- `-DWET_DRY` - Enable wetting/drying
- `-DMULTIPROCESSOR` - MPI parallelization
- `-DMPDATA` - MPDATA advection scheme
- `-DFABM` - Enable FABM coupling
- `-DSEDIMENT` with `-DORIG_SED` or `-DCSTMS_SED` - Sediment model
- `-DNETCDF4_COMPRESSION` - Enable NetCDF4 compression

**Advanced physics**:
- `-DSEMI_IMPLICIT` - Semi-implicit time stepping (requires PETSc)
- `-DICE` - Ice model
- `-DGOTM` - GOTM turbulence model
- `-DNH` - Non-hydrostatic mode (requires PETSc)

See `src/make_PML_ceto.inc:103-627` for complete flag documentation.

## FABM Integration

FABM is the key differentiator of this UK repository from the official FVCOM. The integration:

- Couples FVCOM with biogeochemical models (especially ERSEM)
- Updated to work with FABM v1 (beta status)
- Supports both online and offline forcing (`-DOFFLINE_FABM`)
- Integrates with sediment models
- Supports spectral light model for biogeochemistry

Key FABM files:
- `mod_fabm_3D.F` - 3D FABM coupling, advection, mixing, boundary conditions
- `mod_fabm_data.F` - FABM variable storage and initialization

FABM configuration requires `fabm.yaml` at runtime and setting `STARTUP_FABM_TYPE` in the FVCOM namelist.

## Known Issues and Development Status

From FABM_changelog.txt and README.md:

**Completed**:
- Removed vectorised advection from FABM coupler
- Resolved river_dilution non-conservation issues
- Removed hard-coded domain-specific FABM-sediment links
- Updated nesting to use only variables present in nesting file
- Added spherical and semi-implicit support to FABM coupler

**Outstanding**:
- Enable combined nesting and OBC approach
- Enable interaction between sediments and spectrally resolved light
- Identify and solve offline conservation issues on first time step
- Support for parallel MPI output with FABM
- RK (Runge-Kutta) advection for FABM variables not fully implemented

**Testing Notes** (FABM_changelog.txt:25-68):
- FABM+FVCOM v5 integration tested in Lake Erie setup
- Testing includes: sediments, dye release, FABM passive tracers, carbonate system, ERSEM
- Must test with/without TVD, with/without RK, with/without semi-implicit

## Branch Information

- **Main development branch**: `FVCOM-FABM_v5_dev` (current)
- **Stable branch**: `FVCOM` (use for pull requests)
- Based on FVCOM v5.0.1 from UMASSD

## Coding Conventions

- Fortran 90/2003 free-form format
- Preprocessor directives for conditional compilation (`# if defined(FLAG)`)
- Module names typically match filenames (mod_*.F)
- UPPERCASE for module names and major variables
- Extensive use of preprocessor flags for feature selection

## Related Tools

External Python tools for FVCOM workflows (maintained by PML):
- **PyFVCOM**: Pre/post-processing Python toolbox (github.com/pmlmodelling/pyfvcom)
- **PyLag**: Lagrangian particle model (github.com/pmlmodelling/pylag)
- **ERSEM**: Biogeochemical model for FABM (github.com/pmlmodelling/ersem)

## Running the Model

Typical workflow:
1. Prepare grid (unstructured triangular mesh)
2. Set up boundary conditions (open boundaries, rivers, surface forcing)
3. Configure namelist file with model parameters
4. For FABM: prepare `fabm.yaml` configuration
5. Run: `mpirun -np N ./FVCOM_exe` (for parallel) or `./FVCOM_exe` (serial)

Input files are typically read from paths specified in the namelist, with utilities in `src/input/` for format conversion.

## Module Environment

The system uses environment modules for dependencies:
```bash
module load intel/2025.1.3
module load impi/2021.15
module load netcdf/4.9.2
module load netcdf-fortran/4.6.1
module load hdf5/1.14.4
```
