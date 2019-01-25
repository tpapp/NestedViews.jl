using NestedViews
using Test

@testset "combine" begin
    A = [rand(2, 3) for i in 1:3, j in 1:4, k in 1:5]
    B = @inferred combine(A)
    @test size(B) == (size(A)..., size(A[1])...)
    @test eltype(B) == eltype(A[1])
    for i in eachindex(B)
        ii = Tuple(i)
        @test @inferred(B[i]) == A[ii[1:3]...][ii[4:5]...]
    end
end

@testset "split" begin
    A = rand(2, 3, 4, 5)
    for K in 0:4
        B = @inferred slices(A, Val{K}())
        @test size(B) ≡ size(A)[1:K]
        isfirst = true
        for i in eachindex(B)
            @test @inferred(B[i]) == view(A, Tuple(i)..., fill(Colon(), 4-K)...)
            if isfirst          # only test once
                @test eltype(B) == typeof(B[i])
                isfirst = false
            end
        end
    end
    @test_throws ArgumentError slices(A, -1)
    @test_throws ArgumentError slices(A, 5)
end
