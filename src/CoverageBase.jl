__precompile__(true)
module CoverageBase
using Coverage
export testnames, runtests

const need_inlining = []

function julia_top()
    dir = joinpath(JULIA_HOME, "..", "share", "julia")
    if isdir(joinpath(dir,"base")) && isdir(joinpath(dir,"test"))
        return dir
    end
    dir = JULIA_HOME
    while !isdir(joinpath(dir,"base"))
        dir, _ = splitdir(dir)
        if dir == "/"
            error("Error parsing top dir; JULIA_HOME = $JULIA_HOME")
        end
    end
    dir
end

module BaseTestRunner
import ..julia_top
let topdir = julia_top(),
    testdir = joinpath(topdir, "test")
include(joinpath(testdir, "choosetests.jl"))
include(joinpath(testdir, "testdefs.jl"))
end
end

function testnames()
    names, _ = BaseTestRunner.choosetests()
    if Base.JLOptions().can_inline == 0
        filter!(x -> !in(x, need_inlining), names)
    end

    # Manually add in `pkg`, which is disabled so that `make testall` passes on machines without internet access
    push!(names, "pkg")
    names
end

function runtests(names)
    topdir = julia_top()
    testdir = joinpath(topdir, "test")
    cd(testdir) do
        for tst in names
            @time BaseTestRunner.runtests(tst)
        end
    end
end

end # module
