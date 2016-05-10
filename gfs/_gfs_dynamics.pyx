cimport numpy as cnp
import numpy as np
from numpy import empty

#ctypedef cnp.ndarray[complex, ndim=3] Cplx3d
#ctypedef cnp.ndarray[complex, ndim=2] Cplx2d
#ctypedef cnp.ndarray[complex, ndim=1] Cplx1d

#ctypedef cnp.ndarray[double, ndim=4] Real4d
#ctypedef cnp.ndarray[double, ndim=3] Real3d
#ctypedef cnp.ndarray[double, ndim=2] Real2d
'''
cdef extern: 
    void initialiseSpectralArrays(\
        cnp.ndarray[complex, ndim=2] *pyVrtSpec, \
        cnp.ndarray[complex, ndim=2] *pyDivSpec,\
        cnp.ndarray[complex, ndim=3] *pyTracerSpec,\
        cnp.ndarray[complex, ndim=2] *pyVirtTempSpec,\
        cnp.ndarray[complex, ndim=1] *pyTopoSpec,\
        cnp.ndarray[complex, ndim=1] *pyLnPsSpec,\
        cnp.ndarray[complex, ndim=1] *pyDissSpec,\
        cnp.ndarray[complex, ndim=1] *pyDmpProf,\
        cnp.ndarray[complex, ndim=1] *pyDiffProf)

cdef extern: 
    void initialiseGridArrays(\
        cnp.ndarray[double, ndim=3] pyUg,\
        cnp.ndarray[double, ndim=3] pyVg,\
        cnp.ndarray[double, ndim=3] pyVrtg,\
        cnp.ndarray[double, ndim=3] pyDivg,\
        cnp.ndarray[double, ndim=3] pyVirtTempg,\
        cnp.ndarray[double, ndim=4] pyTracerg,\
        cnp.ndarray[double, ndim=3] pyDlnpdtg,\
        cnp.ndarray[double, ndim=3] pyEtaDotg,\
        cnp.ndarray[double, ndim=2] pyLnPsg,\
        cnp.ndarray[double, ndim=2] pyPhis,\
        cnp.ndarray[double, ndim=2] pyDPhisdx,\
        cnp.ndarray[double, ndim=2] pyDPhisdy,\
        cnp.ndarray[double, ndim=2] pyDlnpsdt)
'''

# Typedef for function pointer returning void and taking no arguments (for now)

ctypedef void (*pyPhysicsCallback)(double *, double *, double *, double *,\
                                   double *, double *, double *,\
                              double *, double *, double *, double *,\
                                   double *, double *, double *)

# Variables for grid sizes from the library
cdef extern:
    int nlats, nlons, nlevs, ntrunc, ndimspec, ntrac

# Variables for simulation time control
cdef extern:
    int fhmax, fhout

# time step and full time from library
cdef extern:
    double dt, deltim, t

# Variables that control the behaviour of the model
# bint is Cython's boolean type
cdef extern:
    bint dry, adiabatic, heldsuarez

#Variable for initial pressure
cdef extern:
    double pdryini


# Function definitions to do our work
cdef extern:
    void gfsReadNamelist()

#Function to get latitude map from shtns
cdef extern:
    void get_latitudes(double *latitudes)
# Function to init dynamics
cdef extern:
    void gfsInitDynamics()

# Function to init physics
cdef extern:
    void gfsInitPhysics()

#Function to calculate pressure fields after other fields have been updated
cdef extern:
    void gfsCalcPressure()

# Function to step fields by one dt
cdef extern:
    void gfsTakeOneStep()

#Function to register an external callback
cdef extern:
    void gfsRegisterPhysicsCallback(pyPhysicsCallback callback)

#Function to add u,v tendency to vrt,div tendency
cdef extern:
    void gfs_uv_to_vrtdiv(\
                          double *pyUg,\
                          double *pyVg,\
                          double *pyVrtg,\
                          double *pyDivg)

#Function to calculate tendencies within the fortran code (For testing)
cdef extern:
    void calculate_tendencies(\
                              double *pyVrtg,\
                              double *pyDivg,\
                              double *pyVirtTempg,\
                              double *pyPressGrid,\
                              double *pySurfPressure,\
                              double *pyTracerg,\
                              double t,\
                              double dt)

#Function to set tendencies within the fortran code, which will be called by the 
# dynamical core after the semi-implicit step
cdef extern:
    void set_tendencies(\
                              double *pyVrtTend,\
                              double *pyDivTend,\
                              double *pyVirtTempTend,\
                              double *pyTracerTend,\
                              double *pyLnpsTend,\
                              double t,\
                              double dt)



#Function to deallocate arrays in physics, etc.,

cdef extern:
    void gfsFinalise()

#Function to convert the input grid arrays to spectral arrays
# The data must be available in py{Ug,Vg,VirtTempg,Tracerg,Lnpsg}
cdef extern:
    void gfsConvertToSpec()

#Function to convert the spectral arrays to grid arrays
# The result will be available in py{Ug,Vg,VirtTempg,Tracerg,Lnpsg}
cdef extern:
    void gfsConvertToGrid()

#Function to initialise the arrays for computation
# These are allocated in Python and passed in
cdef extern: 
    void initialiseSpectralArrays(\
        complex *pyVrtSpec, \
        complex *pyDivSpec,\
        complex *pyVirtTempSpec,\
        complex *pyTracerSpec,\
        complex *pyTopoSpec,\
        complex *pyLnPsSpec,\
        complex *pyDissSpec,\
        complex *pyDmpProf,\
        complex *pyDiffProf)

cdef extern: 
    void initialiseGridArrays(\
        double *pyUg,\
        double *pyVg,\
        double *pyVrtg,\
        double *pyDivg,\
        double *pyVirtTempg,\
        double *pyTracerg,\
        double *pyDlnpdtg,\
        double *pyEtaDotg,\
        double *pyLnPsg,\
        double *pyPhis,\
        double *pyDPhisdx,\
        double *pyDPhisdy,\
        double *pyDlnpsdt)

cdef extern:
    void initialisePressureArrays(\
        double *pySurfPressure,\
        double *pyPressGrid)

cdef void testFunc():
    print 'a'


cdef class _gfs_dynamics:

# Grid space arrays, cython for initialisation
    cdef public cnp.double_t[::1,:,:,:] pyTracerg
    cdef public cnp.double_t[::1,:,:] pyUg, pyVg, pyVrtg, pyDivg,\
               pyVirtTempg, pyDlnpdtg, pyEtaDotg
    cdef public cnp.double_t[::1,:] pyLnPsg, pyPhis, pyDPhisdx,\
               pyDPhisdy, pyDlnpsdt
    
# Pressure arrays, in grid space
    cdef public cnp.double_t[::1,:] pySurfPressure
    cdef public cnp.double_t[::1,:,:] pyPressGrid


# Spectral arrays, using cython for declaration
    cdef public cnp.complex_t[::1,:,:] pyTracerSpec

    cdef public cnp.complex_t[::1,:] pyVrtSpec, pyDivSpec, pyVirtTempSpec
    
    cdef public cnp.complex_t[:] pyTopoSpec, pyLnPsSpec, \
                pyDissSpec, pyDmpProf, pyDiffProf

# Temporary arrays for setting tendency terms
    cdef public cnp.double_t[::1,:,:] \
        tempVrtTend, tempDivTend, tempVirtTempTend, tempUTend,tempVTend
    cdef public cnp.double_t[::1,:,:,:] tempTracerTend
    cdef public cnp.double_t[::1,:] tempLnpsTend, latitudes

# Grid size
    cdef public int numLats, numLons, numTrunc, numLevs, spectralDim, numTracers

# Model state
    cdef int modelIsInitialised, physicsEnabled

# Physics subroutine pointer
    cdef object physicsCallback

# Are we running inside CliMT?
    cdef int climt_mode

    def __init__(self, numLons=192, numLats=94, \
                    simTimeHours=24, timestep=1200.0,\
                    useHeldSuarez=True, dryPressure=1e5,\
                    numTracers=1,physics=None,climt_mode=False):

        global adiabatic, dry, nlats, nlons, nlevs,\
            ntrunc, ndimspec, ntrac, fhmax, deltim,\
            heldsuarez, dt, pdryini, fhout, lats
# Read in the namelist
#        gfsReadNamelist()


# Read in the grid sizes (mainly to improve readability)
        if(numLats):
            nlats = <int>numLats
        
        if(numLons):
            nlons = <int>numLons
            ntrunc = <int>numLons/3 - 2
            ndimspec = (ntrunc+1)*(ntrunc+2)/2

        if(timestep):
            deltim = <double>timestep
            dt = <double>timestep

        if(physics):
            self.physicsCallback = physics
            self.physicsEnabled = True

        self.climt_mode = climt_mode


        nlevs = 28
        pdryini = <double> dryPressure
        ntrac = <int>numTracers
        heldsuarez = useHeldSuarez
        fhmax = 9600
        fhout = 24
        adiabatic = False
        dry = True

        self.numLats = nlats
        self.numLons = nlons
        self.numLevs = nlevs
        self.numTrunc = ntrunc
        self.spectralDim = ndimspec
        self.numTracers = ntrac

        print 'Lats, lons, levs, trunc, dims, tracers', nlats, nlons, nlevs,\
            ntrunc, ndimspec, ntrac


# method to reconfigure model after instantiation. HAVE to call init model
# afterwards            
    def configureModel(self, numLons=None, numLats=None):
        
        global adiabatic, dry, nlats, nlons, nlevs, ntrunc, ndimspec, ntrac

        if(numLats):
            self.numLats = <int>numLats
            nlats = self.numLats

        if(numLons):
            print self.numLons
            self.numLons = <int>numLons
            nlons = self.numLons
            self.numTrunc = self.numLons/3
            self.spectralDim = (self.numTrunc+1)*(self.numTrunc+2)/2
            
            ntrunc = self.numTrunc
            ndimspec = self.spectralDim

        print 'Current Lats, lons, trunc, dims', nlats, nlons, ntrunc, ndimspec
        print 'Current Lats, lons, trunc, dims', self.numLats, self.numLons,\
        self.numTrunc, self.spectralDim

# Initialise arrays and dynamics and physics
    def initModel(self):

        if(self.modelIsInitialised):
            self.shutDownModel()

        self.initSpectralArrays()
        self.initGridArrays()
        self.initPressureArrays()

# Now that the arrays are initialised, call dynamics and physics init

        gfsInitDynamics()
        gfsInitPhysics()
        print 'getting latitudes'
        get_latitudes(<double *>&self.latitudes[0,0])
        print 'got latitudes'

        self.modelIsInitialised = 1

# Create the spectral arrays (defined in spectral_data.f90)

    def initSpectralArrays(self):
        global adiabatic, dry, nlats, nlons, nlevs, ntrunc, ndimspec, ntrac

        self.pyTracerSpec = np.zeros((ndimspec, nlevs, ntrac),dtype=complex, order='F')

#self.pyVrtSpec = np.zeros((ndimspec, nlevs),dtype=complex, order='F')
        self.pyVrtSpec = np.array(np.arange(ndimspec*nlevs).reshape(ndimspec, nlevs),dtype=complex, order='F')
        self.pyVirtTempSpec = np.zeros((ndimspec, nlevs),dtype=complex, order='F')
        self.pyDivSpec = np.zeros((ndimspec, nlevs),dtype=complex,order='F')

        
        self.pyTopoSpec = np.zeros(ndimspec,dtype=complex)
        self.pyLnPsSpec = np.zeros(ndimspec,dtype=complex)
        self.pyDissSpec = np.zeros(ndimspec,dtype=complex)
        
        self.pyDmpProf = np.zeros(nlevs,dtype=complex)
        self.pyDiffProf = np.zeros(nlevs,dtype=complex)

        if(ntrac > 0):
            initialiseSpectralArrays(\
                 <double complex *>&self.pyVrtSpec[0,0], \
                 <double complex *>&self.pyDivSpec[0,0],\
                 <double complex *>&self.pyVirtTempSpec[0,0],\
                 <double complex *>&self.pyTracerSpec[0,0,0],\
                 <double complex *>&self.pyTopoSpec[0],\
                 <double complex *>&self.pyLnPsSpec[0],\
                 <double complex *>&self.pyDissSpec[0],\
                 <double complex *>&self.pyDmpProf[0],\
                 <double complex *>&self.pyDiffProf[0])
        else:
            initialiseSpectralArrays(\
                 <double complex *>&self.pyVrtSpec[0,0], \
                 <double complex *>&self.pyDivSpec[0,0],\
                 <double complex *>0,\
                 <double complex *>&self.pyVirtTempSpec[0,0],\
                 <double complex *>&self.pyTopoSpec[0],\
                 <double complex *>&self.pyLnPsSpec[0],\
                 <double complex *>&self.pyDissSpec[0],\
                 <double complex *>&self.pyDmpProf[0],\
                 <double complex *>&self.pyDiffProf[0])


# Create the grid arrays (defined in grid_data.f90)

    def initGridArrays(self):
        global adiabatic, dry, nlats, nlons, nlevs, ntrunc, ndimspec, ntrac


        self.pyTracerg = np.zeros((nlons, nlats, nlevs, ntrac),\
                dtype=np.double, order='F')

        self.pyUg = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        self.pyVg = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        self.pyVrtg = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        self.pyDivg = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        self.pyVirtTempg = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        self.pyDlnpdtg = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        self.pyEtaDotg = np.zeros((nlons, nlats, nlevs+1), dtype=np.double, order='F')


        self.pyLnPsg = np.zeros((nlons, nlats), dtype=np.double, order='F')
        self.pyPhis = np.zeros((nlons, nlats), dtype=np.double, order='F')
        self.pyDPhisdx = np.zeros((nlons, nlats), dtype=np.double, order='F')
        self.pyDPhisdy = np.zeros((nlons, nlats), dtype=np.double, order='F')
        self.pyDlnpsdt = np.zeros((nlons, nlats), dtype=np.double, order='F')


        self.tempTracerTend = np.zeros((nlons, nlats, nlevs, ntrac),\
                dtype=np.double, order='F')

        self.tempUTend = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        self.tempVTend = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        self.tempVrtTend = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')

        self.tempDivTend = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        self.tempVirtTempTend = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')

        self.tempLnpsTend = np.zeros((nlons, nlats), dtype=np.double, order='F')

        self.latitudes = np.zeros((nlons, nlats), dtype=np.double, order='F')


        if(ntrac > 0):
            initialiseGridArrays(\
                 <double *>&self.pyUg[0,0,0],\
                 <double *>&self.pyVg[0,0,0],\
                 <double *>&self.pyVrtg[0,0,0],\
                 <double *>&self.pyDivg[0,0,0],\
                 <double *>&self.pyVirtTempg[0,0,0],\
                 <double *>&self.pyTracerg[0,0,0,0],\
                 <double *>&self.pyDlnpdtg[0,0,0],\
                 <double *>&self.pyEtaDotg[0,0,0],\
                 <double *>&self.pyLnPsg[0,0],\
                 <double *>&self.pyPhis[0,0],\
                 <double *>&self.pyDPhisdx[0,0],\
                 <double *>&self.pyDPhisdy[0,0],\
                 <double *>&self.pyDlnpsdt[0,0])
        else:
            initialiseGridArrays(\
                 <double *>&self.pyUg[0,0,0],\
                 <double *>&self.pyVg[0,0,0],\
                 <double *>&self.pyVrtg[0,0,0],\
                 <double *>&self.pyDivg[0,0,0],\
                 <double *>&self.pyVirtTempg[0,0,0],\
                 <double *>0,\
                 <double *>&self.pyDlnpdtg[0,0,0],\
                 <double *>&self.pyEtaDotg[0,0,0],\
                 <double *>&self.pyLnPsg[0,0],\
                 <double *>&self.pyPhis[0,0],\
                 <double *>&self.pyDPhisdx[0,0],\
                 <double *>&self.pyDPhisdy[0,0],\
                 <double *>&self.pyDlnpsdt[0,0])

#Intialise pressure arrays
    def initPressureArrays(self):
        global adiabatic, dry, nlats, nlons, nlevs, ntrunc, ndimspec, ntrac

        self.pySurfPressure = np.zeros((nlons, nlats), dtype=np.double, order='F')
        self.pyPressGrid = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')

        initialisePressureArrays(\
                <double *>&self.pySurfPressure[0,0],\
                <double *>&self.pyPressGrid[0,0,0])

# Set tendencies for dynamical core to use in physics
    def setTendencies(self,tendency_list):

        global nlons,nlats,nlevs,ntrac

        cdef cnp.double_t[::1,:,:] tempvrt,tempdiv,tempvt,tempu,tempv
        cdef cnp.double_t[::1,:,:,:] temptracer
        cdef cnp.double_t[::1,:] templnps

        uTend,vTend,virtTempTend,lnpsTend,tracerTend = tendency_list

        if virtTempTend is None:
            tempvt = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        else:
            tempvt = np.asfortranarray(virtTempTend)

        if lnpsTend is None:
            tempvt = np.zeros((nlons, nlats), dtype=np.double, order='F')
        else:
            templnps = np.asfortranarray(lnpsTend)

        if tracerTend is None:
            temptracer = np.zeros((nlons, nlats, nlevs, ntrac), dtype=np.double, order='F')
        else:
            temptracer = np.asfortranarray(tracerTend)

        if uTend is None:
            tempu = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        else:
            tempu = np.asfortranarray(uTend)

        if vTend is None:
            tempv = np.zeros((nlons, nlats, nlevs), dtype=np.double, order='F')
        else:
            tempv = np.asfortranarray(vTend)


        #if (uTend.any() and vTend.any()):

        #print
        #print 'adding wind tendencies'
        #print

        tempu = np.asfortranarray(uTend)
        tempv = np.asfortranarray(vTend)
        self.tempUTend[:] = tempu
        self.tempVTend[:] = tempv

        gfs_uv_to_vrtdiv(\
                         <double *>&self.tempUTend[0,0,0],\
                         <double *>&self.tempVTend[0,0,0],\
                         <double *>&self.tempVrtTend[0,0,0],\
                         <double *>&self.tempDivTend[0,0,0],\
                         )

            #tempvrt = np.asfortranarray(self.tempVrtTend) + np.asfortranarray(tempvrt) 
            #tempdiv = np.asfortranarray(self.tempDivTend) + np.asfortranarray(tempdiv)


            #self.tempVrtTend[:] = tempvrt
            #self.tempDivTend[:] = tempdiv
        self.tempVirtTempTend[:] = tempvt
        self.tempLnpsTend[:] = templnps
        self.tempTracerTend[:] = temptracer

        set_tendencies(\
                       <double *>&self.tempVrtTend[0,0,0],\
                       <double *>&self.tempDivTend[0,0,0],\
                       <double *>&self.tempVirtTempTend[0,0,0],\
                       <double *>&self.tempLnpsTend[0,0],\
                       <double *>&self.tempTracerTend[0,0,0,0],\
                       t,dt)

# Take one step
    def oneStepForward(self):

        gfsConvertToGrid()
        gfsCalcPressure()


        if self.physicsEnabled:
            #TODO don't call physics callback directly. use a helper function which will remove
            #TODO individual fields from tracerg and assign them to q, ozone, etc., and then
            #TODO call physics routines
            tendList = \
                self.physicsCallback(self.pyUg,\
                                     self.pyVg,\
                                     self.pyVirtTempg,\
                                     self.pyPressGrid,\
                                     self.pySurfPressure,\
                                     self.pyTracerg,\
                                     self.latitudes)

            self.setTendencies(tendList)

        else:
            calculate_tendencies(\
                                 <double *>&self.pyVrtg[0,0,0],\
                                 <double *>&self.pyDivg[0,0,0],\
                                 <double *>&self.pyVirtTempg[0,0,0],\
                                 <double *>&self.pyPressGrid[0,0,0],\
                                 <double *>&self.pySurfPressure[0,0],\
                                 <double *>0,\
                                 t,\
                                 dt)
        gfsTakeOneStep()

# Register a callback which calculates the physics (to be used in stand-alone
# mode only)

    cdef setPhysicsCallback(self, physicsFnPtr):

        self.physicsCallback = physicsFnPtr
        self.physicsEnabled = True
#        gfsRegisterPhysicsCallback(testFunc)
    '''
    Does not work!
    def setInitialConditions(self, inputList):
    
    myug,myvg,myvirtempg,mytracerg,mylnpsg = inputList
    
    self.pyUg[:] = myug[:]
    self.pyVg[:] = myvg[:]
    self.pyVirtTempg[:] = myvirtempg[:]
    self.pyTracerg[:] = mytracerg[:]
    self.pyLnPsg[:] = mylnpsg[:]
    
    gfsConvertToSpec()
    '''
    def getResult(self):
    
        gfsConvertToGrid()
        gfsCalcPressure()

        outputList = []

        outputList.append(np.asarray(self.pyUg).copy(order='F'))
        outputList.append(np.asarray(self.pyVg).copy(order='F'))
        outputList.append(np.asarray(self.pyVirtTempg).copy(order='F'))
        outputList.append(np.asarray(self.pyTracerg[:,:,:,0]).copy(order='F'))
        outputList.append(np.asarray(self.pyLnPsg).copy(order='F'))
        outputList.append(np.asarray(self.pyPressGrid).copy(order='F'))

        return(outputList)

    # method to override the parent class (Component) method (to be used in CliMT
    # mode only)
    def driver(self, myug, myvg, myvirtempg, myqg, mylnpsg, mypress, double simTime=-1.):


        cdef cnp.double_t[::1,:,:] tempug,tempvg,tempvtg
        cdef cnp.double_t[::1,:,:] tempqg
        cdef cnp.double_t[::1,:] templnpsg
    
    
        if(simTime >= 0):
            global t
            t = simTime
    
        #myug,myvg,myvirtempg,myqg,mylnpsg,mypress = inputArgs
    
        myug = np.asfortranarray(myug)
        myvg = np.asfortranarray(myvg)
        myvirtempg = np.asfortranarray(myvirtempg)
        myqg = np.asfortranarray(myqg)
        mylnpsg = np.asfortranarray(mylnpsg)
    
        #Convert to memory view so that assignment can be made to arrays
        tempug = myug
        tempvg = myvg
        tempvtg = myvirtempg
    
        tempqg = myqg
        templnpsg = mylnpsg
    
        print np.amax(self.pyVirtTempg - myvirtempg)
        #Assign to model arrays
        self.pyUg[:] = tempug
        self.pyVg[:] = tempvg
        self.pyVirtTempg[:] = tempvtg
        self.pyTracerg[:,:,:,0] = tempqg
        self.pyLnPsg[:] = templnpsg
    
    #Convert to spectral space
        gfsConvertToSpec()
    
    #Step forward in time
        self.oneStepForward()
    
    #Convert back to grid space
        gfsConvertToGrid()
    
    # only ln(Ps) is calculated in the dynamics. This calculates
    # the values on the full grid
        gfsCalcPressure()
    
        '''
        ug = np.asfortranarray(self.pyUg.copy())
        vg = np.asfortranarray(self.pyVg.copy())
        virtempg = np.asfortranarray(self.pyVirtTempg.copy())
        tracerg = np.asfortranarray(self.pyTracerg[:,:,:,0].copy())
        lnpsg = np.asfortranarray(mylnpsg.copy())
        press = np.asfortranarray(mypress.copy())
    
        return(ug,vg,virtempg,tracerg,lnpsg,press)
        '''
    
        ugInc = np.ascontiguousarray(self.pyUg - myug)
        vgInc = np.ascontiguousarray(self.pyVg - myvg)
        virtempgInc = np.ascontiguousarray(self.pyVirtTempg - myvirtempg)
        tracergInc = np.ascontiguousarray(self.pyTracerg[:,:,:,0] - myqg)
        lnpsgInc = np.ascontiguousarray(self.pyLnPsg - mylnpsg)
        pressInc = np.ascontiguousarray(self.pyPressGrid - mypress)
    
    
        return(ugInc,vgInc,virtempgInc,tracergInc,lnpsgInc,pressInc)
        #return(ugInc,vgInc,virtempgInc,tracergInc,lnpsgInc,pressInc\
               #,ug,vg,virtempg,tracerg,lnpsg,press)
    
    def printTimes(self):
        global dt,t
        print 'Timestep: ',dt, 'Total Time:', t
    
    def get_nlat(self):
        return self.numLats
    
    def get_nlon(self):
        return self.numLons
    
    def get_nlev(self):
        return self.numLevs
    
    def integrateFields(self,field_list,increment_list):
        #Only to be used in CLIMT mode
        global ntrac,nlons,nlats,nlevs,dt
     
        cdef cnp.double_t[::1,:,:] tempug,tempvg,tempvtg
        cdef cnp.double_t[::1,:,:] tempqg
        cdef cnp.double_t[::1,:] templnpsg
       
        if self.climt_mode:
            
            temptrac = np.zeros((nlons,nlats,nlevs,ntrac),dtype=np.double,order='F')
            uTend,vTend,virtTempTend,lnpsTend,qTend = increment_list
    
    
            u,v,virtemp,q,lnps = field_list
    
            #CliMT gives increments; convert to tendencies
            uTend /= dt
            vTend /= dt
            virtTempTend /= dt
            qTend /= dt
            lnpsTend /= dt
    
            temptrac[:,:,:,0] = qTend
    
            increment_list = uTend,vTend,virtTempTend,lnpsTend,temptrac
            self.setTendencies(increment_list)
    
            myug = np.asfortranarray(u)
            myvg = np.asfortranarray(v)
            myvirtempg = np.asfortranarray(virtemp)
            myqg = np.asfortranarray(q)
            mylnpsg = np.asfortranarray(lnps)
    
            #Convert to memory view so that assignment can be made to arrays
            tempug = myug
            tempvg = myvg
            tempvtg = myvirtempg
    
            tempqg = myqg
            templnpsg = mylnpsg
    
            #Assign to model arrays
            self.pyUg[:] = tempug
            self.pyVg[:] = tempvg
            self.pyVirtTempg[:] = tempvtg
            self.pyTracerg[:,:,:,0] = tempqg
            self.pyLnPsg[:] = templnpsg
    
            #Convert to spectral space
            gfsConvertToSpec()
    
            #Step forward in time
            gfsTakeOneStep()
    
            #Convert back to grid space
            gfsConvertToGrid()
    
            # only ln(Ps) is calculated in the dynamics. This calculates
            # the values on the full grid
            gfsCalcPressure()
    
            ug = np.asfortranarray(self.pyUg.copy())
            vg = np.asfortranarray(self.pyVg.copy())
            virtempg = np.asfortranarray(self.pyVirtTempg.copy())
            qg = np.asfortranarray(self.pyTracerg[:,:,:,0].copy())
            lnpsg = np.asfortranarray(self.pyLnPsg.copy())
            press = np.asfortranarray(self.pyPressGrid.copy())
    
            return(ug,vg,virtempg,qg,lnpsg,press)
            
    
    def shutDownModel(self):

        global t
    
        if self.modelIsInitialised:
            t = 0
            gfsFinalise()
            self.modelIsInitialised = False
