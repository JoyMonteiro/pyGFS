
CYTHON = _gfs_dynamics.pyx

CYTHONOBJS= _gfs_dynamics.c\
            _gfs_dynamics.so

cython_wrapper: $(CYTHON) 
	cd src; make python_lib
	LDFLAGS="-L"$(PWD)\/src python setup.py build_ext --inplace
	if [ -d build ]; then rm -R build/; fi

all: $(cython_wrapper)

clean: 
	cd src; make clean
	rm $(CYTHONOBJS)

