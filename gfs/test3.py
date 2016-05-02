from _gfs_dynamics import _gfs_dynamics

import numpy as np

def test(u, v, vrt, div, temp, press, surf_press, tracer,lats):

    print np.asarray(lats)
    print lats.shape

    print 'in physics'
    vrt_tend = np.zeros(vrt.shape, dtype=np.double, order='F')
    div_tend = np.zeros(div.shape, dtype=np.double, order='F')
    temp_tend = np.zeros(temp.shape, dtype=np.double, order='F')
    lnps_tend = np.zeros(surf_press.shape, dtype=np.double, order='F')
    tracer_tend = np.zeros(tracer.shape, dtype=np.double, order='F')
    u_tend = None
    v_tend = None

    return (u_tend,v_tend,vrt_tend,div_tend,temp_tend,lnps_tend,tracer_tend)

def held_suarez(u, v, temp, press, surf_press, tracer,lats):

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
test = _gfs_dynamics(192,94,physics=held_suarez);

test.initModel();

#test.oneStepForward();

#test.configureModel(192,94);

#test.initModel();
print 'finished init'
for i in range(1000):
    test.oneStepForward();


fields = test.getResult()
test.shutDownModel();
