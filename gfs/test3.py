from _gfs_dynamics import _gfs_dynamics

import numpy as np

def test_phys(u, v, temp, press, surf_press, tracer,lats):

    #print np.asarray(lats)
    #print lats.shape

    print 'in physics'
    u_tend = np.zeros(u.shape, dtype=np.double, order='F')
    v_tend = np.zeros(v.shape, dtype=np.double, order='F')
    temp_tend = np.zeros(temp.shape, dtype=np.double, order='F')
    lnps_tend = np.zeros(surf_press.shape, dtype=np.double, order='F')
    tracer_tend = np.zeros(tracer.shape, dtype=np.double, order='F')

    return (u_tend,v_tend,temp_tend,lnps_tend,tracer_tend)

blprof = 0
rad_equil_temp = 0
temp_tend = 0
u_tend = 0
v_tend = 0

def held_suarez(u, v, temp, press, surf_press, tracer,lats):

    global blprof, rad_equil_temp, temp_tend, u_tend, v_tend

    sigbot = 0.7
    delthz = 10.
    tempstrat = 200.
    kdrag = 1./(1.*86400.)
    krada = 1./(40.*86400.)
    kradb = 1./(4.*86400. )
    p0 = 1.e5
    deltmp = 60.

    temp = np.asfortranarray(temp)
    tracer = np.asfortranarray(tracer)
    press = np.asfortranarray(press)
    surf_press = np.asfortranarray(surf_press)
    lats = np.asfortranarray(lats)[:,:,np.newaxis]



    blprof = press/surf_press[:,:,np.newaxis]

    rad_equil_temp = (press/p0)**(2./7.)*\
        (315.-deltmp*np.sin(lats)**2 - delthz*np.log(press/p0)*np.cos(lats)**2)

    blprof = (blprof - sigbot)/(1-sigbot)
    blprof[blprof<0] = 0

    rad_equil_temp[rad_equil_temp < tempstrat] = tempstrat

    temp_tend = (krada+(kradb-krada)*blprof*np.cos(lats)**4)*(rad_equil_temp - temp)

    #vrt_tend = -blprof*kdrag*vrt
    #div_tend = -blprof*kdrag*div
    v_tend = -blprof*kdrag*v
    u_tend = -blprof*kdrag*u

    lnps_tend = np.zeros(surf_press.shape, dtype=np.double, order='F')

    tracer_tend = np.zeros(tracer.shape, dtype=np.double, order='F')

    #u_tend = np.zeros(u.shape,dtype=np.double, order='F')
    #v_tend = np.zeros(v.shape,dtype=np.double, order='F')

    return (u_tend,v_tend,temp_tend,lnps_tend,tracer_tend)



#test = _gfs_dynamics(384,190);
#dycore = _gfs_dynamics(192,94,physics=held_suarez)
#dycore = _gfs_dynamics(64,30)
dycore = _gfs_dynamics(64,30,physics=held_suarez)

dycore.initModel();

#test.oneStepForward();

#test.configureModel(192,94);

#test.initModel();
print 'finished init'
for i in range(3000):
    dycore.oneStepForward()


fields = dycore.getResult()
dycore.shutDownModel();
