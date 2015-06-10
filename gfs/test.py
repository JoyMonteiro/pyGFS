from _gfs_dynamics import _gfs_dynamics

#test = _gfs_dynamics(384,190);
test = _gfs_dynamics(192,94);

test.initModel();

#test.oneStepForward();

#test.configureModel(192,94);

#test.initModel();

for i in range(200):
    test.oneStepForward();


fields = test.getResult()
test.shutDownModel();
