module Tempo

# TODO: remove this dependency - could be handled by Tempo itself?
using Dates: DateTime as DatesDateTime, datetime2julian, now

using JSMDInterfaces.Errors: AbstractGenericException, @module_error
using JSMDUtils

using Pkg.Artifacts
using PrecompileTools: PrecompileTools

using SMDGraphs:
    MappedNodeGraph,
    MappedDiGraph,
    AbstractGraphNode,
    SimpleDiGraph,
    has_vertex,
    add_edge!,
    get_path,
    get_mappedid,
    get_mappednode

import FunctionWrappers: FunctionWrapper
import SMDGraphs: get_node_id, add_vertex!

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
