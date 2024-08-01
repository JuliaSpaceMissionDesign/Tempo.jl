module Tempo

using FunctionWrappersWrappers: FunctionWrappersWrapper, 
                                FunctionWrappers.FunctionWrapper

using JSMDInterfaces.Errors: AbstractGenericException, @custom_error

using JSMDInterfaces.Graph: 
    AbstractJSMDGraphNode, 
    add_edge!,
    add_vertex!, 
    get_path,
    has_vertex

using JSMDUtils
using JSMDUtils.Autodiff

using Pkg.Artifacts
using PrecompileTools: PrecompileTools

using SMDGraphs:
    MappedNodeGraph,
    MappedDiGraph,
    SimpleDiGraph,
    get_mappedid,
    get_mappednode

import SMDGraphs: get_node_id

export DJ2000, DMJD, DJM0

include("constants.jl")
include("errors.jl")
include("convert.jl")
include("parse.jl")
include("leapseconds.jl")
include("offset.jl")

export TIMESCALES, @timescale, add_timescale!, 
       TimeSystem, timescale_alias, timescale_name, timescale_id

include("scales.jl")

export Date, Time,
       year, month, day, find_dayinyear,
       j2000, j2000s,j2000c, hour, minute, second, DateTime

include("datetime.jl")
include("origin.jl")

export Duration, value

include("duration.jl")

export Epoch, j2000, j2000s, j2000c, doy, timescale, value

include("epoch.jl")

# Package precompilation routines
include("precompile.jl")

end
