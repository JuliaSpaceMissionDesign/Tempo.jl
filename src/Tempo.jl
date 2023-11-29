module Tempo

# TODO: remove this dependency - could be handled by Tempo itself?
using Dates: DateTime as DatesDateTime, datetime2julian, now

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

include("constants.jl")
include("errors.jl")
include("convert.jl")
include("parse.jl")

include("leapseconds.jl")
include("offset.jl")
include("scales.jl")

include("datetime.jl")
include("origin.jl")
include("epoch.jl")

# Package precompilation routines
include("precompile.jl")

end
