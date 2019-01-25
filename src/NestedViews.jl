module NestedViews

export combine, slices

using ArgCheck: @argcheck
using Base: @propagate_inbounds
using DocStringExtensions: SIGNATURES

"""
T, innersize = $(SIGNATURES)

Use the element type and size from the first array.
"""
function use_first(A)
    f = first(A)
    eltype(f), size(f)
end

struct CombinedView{T,N,S,P} <: AbstractArray{T,N}
    innersize::S
    parent::P
    function CombinedView{T,N}(innersize::S, parent::P
                               ) where {T,N,S<:Tuple{Vararg{Int}},P<:AbstractArray}
        @argcheck N isa Int && N ≥ 0
        @argcheck all(innersize .> 0)
        new{T,N,S,P}(innersize, parent)
    end
end

"""
$(SIGNATURES)

Return an `AbstractArray` which is a view that combines the elements of `A`, in the sense
that `combine(A)[i..., j...] ≡ A[i...][j...]` for indices that are compatible.

`common` is a function of `A` that is used to determine the common element type and size.
"""
function combine(A::AbstractArray; common = use_first)
    T, innersize = common(A)
    CombinedView{T, ndims(A) + length(innersize)}(innersize, A)
end

Base.parent(c::CombinedView) = c.parent

Base.IndexStyle(::Type{<:CombinedView}) = Base.IndexCartesian()

Base.size(c::CombinedView) = (size(parent(c))..., c.innersize...)

@propagate_inbounds function Base.getindex(c::CombinedView{T,N,S},
                                           I::Vararg{Int,N}) where {T,N,S}
    K = length(c.innersize)
    M = N - K
    outer_ix = ntuple(i -> I[i], Val{M}())
    inner_ix = ntuple(i -> I[M + i], Val{K}())
    (parent(c)[outer_ix...]::AbstractArray{T,K})[inner_ix...]
end

struct SlicedView{T,N,P<:AbstractArray} <: AbstractArray{T,N}
    parent::P
end

@propagate_inbounds @inline function _slices_view(A, I, ::Val{N}) where N
    view(A, I..., ntuple(_ -> Colon(), Val{ndims(A) - N}())...)
end

"""
$(SIGNATURES)

Return an `AbstractArray` which is a view that contains slices of `A` following the index
`N`, ie `slices(A, Val(K))[i...][j...] ≡ A[i..., j...]` for indices that are compatible,
particularly `length(i) ≡ N`.
"""
function slices(A::AbstractArray{T,M}, ::Val{N}) where {T,M,N}
    @argcheck 0 ≤ N ≤ M
    # only the type is neeed, let's hope the compiler optimizes this out
    elt = _slices_view(A, ntuple(i -> firstindex(A, i), Val{N}()), Val{N}())
    SlicedView{typeof(elt),N,typeof(A)}(A)
end

slices(A::AbstractArray, N::Integer) = slices(A, Val{N}())

Base.parent(s::SlicedView) = s.parent

Base.IndexStyle(::Type{<:SlicedView}) = Base.IndexCartesian()

Base.size(s::SlicedView{T,N}) where {T,N} = size(parent(s))[1:N]

@propagate_inbounds function Base.getindex(s::SlicedView{T,N},
                                                I::Vararg{Int,N}) where {T,N}
    _slices_view(parent(s), I, Val{N}())
end

end # module
