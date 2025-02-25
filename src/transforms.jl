# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    GeometricTransform

A method to transform the geometry (e.g. coordinates) of objects.
See [https://en.wikipedia.org/wiki/Geometric_transformation]
(https://en.wikipedia.org/wiki/Geometric_transformation).
"""
abstract type GeometricTransform <: Transform end

"""
    isaffine(transform)

Tells whether or not the geometric `transform` is Affine,
i.e. it can be defined as a muladd operation (`Ax + b`).
"""
isaffine(t::GeometricTransform) = isaffine(typeof(t))
isaffine(::Type{<:GeometricTransform}) = false

# fallback with raw vector of geometries for convenience
function apply(t::GeometricTransform, g::AbstractVector{<:Geometry})
  n, c = apply(t, GeometrySet(g))
  parent(n), c
end

# fallback with raw vector of geometries for convenience
function revert(t::GeometricTransform, g::AbstractVector{<:Geometry}, c)
  o = revert(t, GeometrySet(g), c)
  parent(o)
end

"""
    CoordinateTransform

A method to transform the coordinates of objects.
See [https://en.wikipedia.org/wiki/List_of_common_coordinate_transformations]
(https://en.wikipedia.org/wiki/List_of_common_coordinate_transformations).
"""
abstract type CoordinateTransform <: GeometricTransform end

"""
    applycoord(transform, object)

Recursively apply coordinate `transform` on `object`.
This function is intended for developers of new
[`CoordinateTransform`](@ref).
"""
function applycoord end

# --------------------
# TRANSFORM FALLBACKS
# --------------------

apply(t::CoordinateTransform, v::Vec) = applycoord(t, v), nothing

revert(t::CoordinateTransform, v::Vec, c) = applycoord(inverse(t), v)

apply(t::CoordinateTransform, g::GeometryOrDomain) = applycoord(t, g), nothing

revert(t::CoordinateTransform, g::GeometryOrDomain, c) = applycoord(inverse(t), g)

# apply transform recursively
applycoord(t::CoordinateTransform, g::G) where {G<:GeometryOrDomain} =
  G((applycoord(t, getfield(g, n)) for n in fieldnames(G))...)

# stop recursion at non-geometric types
applycoord(::CoordinateTransform, x) = x

# special treatment for TransformedMesh
applycoord(t::CoordinateTransform, m::TransformedMesh) = TransformedMesh(m, t)

# special treatment for lists of geometries
applycoord(t::CoordinateTransform, g::NTuple{<:Any,<:Geometry}) = map(gᵢ -> applycoord(t, gᵢ), g)
applycoord(t::CoordinateTransform, g::AbstractVector{<:Geometry}) = map(gᵢ -> applycoord(t, gᵢ), g)

# ----------------
# IMPLEMENTATIONS
# ----------------

include("transforms/scale.jl")
include("transforms/rotate.jl")
include("transforms/translate.jl")
include("transforms/affine.jl")
include("transforms/stretch.jl")
include("transforms/stdcoords.jl")
include("transforms/repair.jl")
include("transforms/bridge.jl")
include("transforms/smoothing.jl")
