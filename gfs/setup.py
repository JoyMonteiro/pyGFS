from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
# This line only needed if building with NumPy in Cython file.
from numpy import get_include

ext_modules = [Extension("_gfs_dynamics", ["_gfs_dynamics.pyx"],
                  libraries=["gfsDycore","shtns_omp","lapack","fftw3_omp","fftw3","rt","m"],
                  include_dirs = [get_include()])]

setup ( name='_gfs_dynamics',
       cmdclass={'build_ext':build_ext},
       include_dirs = [get_include()],
       ext_modules = ext_modules)
