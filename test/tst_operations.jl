# test not exported
@test_throws UndefVarError Operation
@test_throws UndefVarError AffineOperation

@test Augmentor.AffineOperation <: Augmentor.Operation

@testset "prepare" begin
    @test @inferred(Augmentor.prepareview(rect)) === rect
    @test @inferred(Augmentor.preparestepview(rect)) === rect
    @test @inferred(Augmentor.preparepermute(rect)) === rect
    @test @inferred(Augmentor.preparelazy(rect)) === rect
    wv = @inferred Augmentor.prepareaffine(rect)
    @test typeof(wv) <: InvWarpedView
    @test typeof(parent(wv)) <: Interpolations.Extrapolation
    @test parent(wv).itp.coefs === rect
    @test @inferred(Augmentor.prepareaffine(wv)) === wv
    @test @inferred(Augmentor.prepareaffine(parent(wv))) === wv
    v = view(wv, 1:2, 2:3)
    @test @inferred(Augmentor.prepareaffine(v)) === v
end

ops = (Rotate90(), Rotate270())
@testset "$(str_showcompact(ops))" begin
    wv = @inferred Augmentor.applyaffine(ops, rect)
    @test typeof(wv) === typeof(invwarpedview(rect, Augmentor.toaffine(NoOp(),rect), Flat()))
    @test wv == rect
    wv = @inferred Augmentor.applylazy(ops, Augmentor.prepareaffine(rect))
    @test typeof(wv) === typeof(invwarpedview(rect, Augmentor.toaffine(NoOp(),rect), Flat()))
    @test wv == rect
    v = @inferred Augmentor.applylazy(ops, rect)
    @test v === view(rect, 1:1:2, 1:1:3)
    @test wv == rect
end

ops = (Rotate90(), Rotate270(), Rotate180())
@testset "$(str_showcompact(ops))" begin
    wv = @inferred Augmentor.applyaffine(ops, rect)
    @test typeof(wv) === typeof(invwarpedview(rect, Augmentor.toaffine(NoOp(),rect), Flat()))
    @test wv[1:2,1:3] == rot180(rect)
    wv2 = @inferred Augmentor.applylazy(ops, Augmentor.prepareaffine(rect))
    @test typeof(wv2) === typeof(invwarpedview(rect, Augmentor.toaffine(NoOp(),rect), Flat()))
    @test wv2 == wv
    v = @inferred Augmentor.applylazy(ops, rect)
    @test v === view(rect, 2:-1:1, 3:-1:1)
    @test v == rot180(rect)
end

ops = (Rotate180(), Either((Rotate90(), Rotate270()), (1,0)))
@testset "$(str_showcompact(ops))" begin
    wv = @inferred Augmentor.applyaffine(ops, square)
    @test typeof(wv) === typeof(invwarpedview(rect, Augmentor.toaffine(NoOp(),square), Flat()))
    r1 = invwarpedview(square, Augmentor.toaffine(Rotate180(),square), Flat())
    @test wv == invwarpedview(r1, Augmentor.toaffine(Rotate90(), r1))
    wv2 = @inferred Augmentor.applylazy(ops, Augmentor.prepareaffine(square))
    @test wv2 == wv
    v = @inferred Augmentor.applylazy(ops, rect)
    @test v === view(permuteddimsview(rect, (2,1)), 1:1:3, 2:-1:1)
    @test v == rotl90(rot180(rect))
end

ops = (Crop(1:2,2:3), Either((Rotate90(), Rotate270()), (1,0)))
@testset "$(str_showcompact(ops))" begin
    wv = @inferred Augmentor.applyaffine(ops, square)
    @test typeof(wv) <: SubArray
    @test typeof(wv.indexes) <: Tuple{Vararg{IdentityRange}}
    @test typeof(parent(wv)) <: InvWarpedView
    @test parent(parent(wv)).itp.coefs === square
    @test parent(copy(wv)) == rotl90(view(square, 1:2, 2:3))
    wv2 = @inferred Augmentor.applylazy(ops, Augmentor.prepareaffine(square))
    @test wv2 == wv
    @test typeof(wv2) == typeof(wv)
    v = @inferred Augmentor.applylazy(ops, square)
    @test v === view(permuteddimsview(square,(2,1)), 3:-1:2, 1:1:2)
    @test v == rotl90(view(square, 1:2, 2:3))
end

ops = (Rotate180(), Crop(1:2,2:3))
@testset "$(str_showcompact(ops))" begin
    wv = @inferred Augmentor.applyaffine(ops, square)
    @test typeof(wv) <: SubArray
    @test typeof(wv.indexes) <: Tuple{Vararg{IdentityRange}}
    @test typeof(parent(wv)) <: InvWarpedView
    @test parent(parent(wv)).itp.coefs === square
    @test wv == view(rot180(square), IdentityRange(1:2), IdentityRange(2:3))
    wv2 = @inferred Augmentor.applylazy(ops, Augmentor.prepareaffine(square))
    @test wv2 == wv
    @test typeof(wv2) == typeof(wv)
    v = @inferred Augmentor.applylazy(ops, square)
    @test v === view(square, 3:-1:2, 2:-1:1)
    @test v == view(rot180(square), 1:2, 2:3)
end

ops = (Either((Rotate90(),Rotate270()),(1,0)), Crop(20:30,100:150), Either((Rotate90(),Rotate270()),(0,1)))
@testset "$(str_showcompact(ops))" begin
    wv = @inferred Augmentor.applyaffine(ops, camera)
    @test typeof(wv) <: SubArray
    @test typeof(wv.indexes) <: Tuple{Vararg{IdentityRange}}
    @test typeof(parent(wv)) <: InvWarpedView
    @test parent(parent(wv)).itp.coefs === camera
    @test parent(copy(wv)) == rotr90(view(rotl90(camera), 20:30, 100:150))
    v = @inferred Augmentor.applylazy(ops, camera)
    @test v === view(camera, 100:1:150, 483:1:493)
    @test v == parent(copy(wv))
    @test v == rotr90(view(rotl90(camera), 20:30, 100:150))
end