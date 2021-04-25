export idx, cpx, exp_ikx, propagator
export gaussian, normal
export ramp

function ramp(::Type{T}, dim::Int, dim_size::Int;
    offset=CtrFT, scale=ScaUnit) where {T}
    size = single_dim_size(dim,dim_size)
    offset = get_offset(size, offset)
    scale_n = get_scale(size, scale)
    f = ((x) -> T.(scale_n[dim] .* (x[dim] .- offset[dim])))
    IndexFunArray(T, f, size) 
end

function ramp(dim::Int, dim_size::Int; offset=CtrFT, scale=ScaUnit)
    ramp(DEFAULT_T, dim, dim_size; offset=offset, scale=scale)
end


# values in the complex plane
function cpx(::Type{T}, size::NTuple{N, Int}; offset=CtrFT, scale=ScaUnit, dims=ntuple(+, N)) where {N,T}
    ig = idx(T, size, offset=offset, scale=scale, dims=dims).generator
    f(x) = complex(ig(x)...)
    return IndexFunArray(Complex{T}, f, size)
end
# values in the complex plane
function cpx(size::NTuple{N, Int}; offset=CtrFT, scale=ScaUnit, dims=ntuple(+, N)) where {N,T}
    cpx(DEFAULT_T, size, offset=offset, scale=scale, dims=dims)
end
function cpx(arr::AbstractArray{T, N}; offset=CtrFT, scale=ScaUnit, dims=ntuple(+, N)) where {N,T}
    cpx(T, size(arr), offset=offset, scale=scale, dims=dims)
end

function exp_ikx(::Type{T}, size::NTuple{N, Int}; shift_by=size.÷2, offset=CtrFT, scale=ScaFT, dims=ntuple(+, N),
                accumulator=sum, weight=1) where {N,T}
    myscale = apply_tuple_list((x,y)-> T.(-2pi .* x .* y), get_scale(size, scale), optional_mat_to_iter(shift_by))
    return exp_is(T, size, scale = myscale, offset=offset, dims = dims, accumulator=accumulator, weight=weight)
end

function exp_ikx(size::NTuple{N, Int}; shift_by=size.÷2, offset=CtrFT, scale=ScaFT, dims=ntuple(+, N), accumulator=sum, weight=1) where {N,T}
    myscale = apply_tuple_list((x,y)-> DEFAULT_T.(-2pi .* x .* y), get_scale(size, scale), optional_mat_to_iter(shift_by))
    return exp_is(complex(DEFAULT_T), size, scale = myscale, offset=offset, dims = dims, accumulator=accumulator, weight=weight)
end

function exp_ikx(arr::AbstractArray{T, N}; shift_by=size(arr).÷2, offset=CtrFT, scale=ScaFT, dims=ntuple(+, N), accumulator=sum, weight=1) where {N,T}
    myscale = apply_tuple_list((x,y)-> T.(-2pi .* x .* y), get_scale(size(arr), scale), optional_mat_to_iter(shift_by))
    return exp_is(complex(eltype(arr)),size(arr), scale = myscale,  offset=offset, dims = dims, accumulator=accumulator)
end

function propagator(::Type{T}, size::NTuple{N, Int}; Δz=1.0, shift_by=0, k_max=0.5, offset=CtrFT, scale=ScaFT, dims=ntuple(+, N),
    accumulator=sum, weight=1) where {N,T}
myscale = apply_tuple_list((x,y)-> T.(x ./ y), get_scale(size, scale), optional_mat_to_iter(k_max))
myscale2 = apply_tuple_list((x,y)-> T.(-2pi .* x .* y), get_scale(size(arr), scale), optional_mat_to_iter(shift_by))
return cispi.((2 .*Δz) .* 
    phase_kz(T, size, scale = myscale, offset=offset, dims = dims, accumulator=accumulator, weight=weight) .+
    2 .* phase_kxy(T, size, scale = myscale2, offset=offset, dims = dims, accumulator=accumulator, weight=weight))
end

function propagator(size::NTuple{N, Int}; Δz=1.0,  k_max=0.5, shift_by=0, offset=CtrFT, scale=ScaFT, dims=ntuple(+, N), accumulator=sum, weight=1) where {N,T}
myscale = apply_tuple_list((x,y)-> DEFAULT_T.(x ./ y), get_scale(size, scale), optional_mat_to_iter(k_max))
myscale2 = apply_tuple_list((x,y)-> DEFAULT_T.(-2pi .* x .* y), get_scale(size, scale), optional_mat_to_iter(shift_by))
return cispi.((2 .*Δz) .* 
        phase_kz(DEFAULT_T, size, scale = myscale, offset=offset, dims = dims, accumulator=accumulator, weight=weight) .+
        2 .* phase_kxy(DEFAULT_T, size, scale = myscale2, offset=offset, dims = dims, accumulator=accumulator, weight=weight))
    end

function propagator(arr::AbstractArray{T, N}; Δz=1.0, k_max=0.5, shift_by=0, offset=CtrFT, scale=ScaFT, dims=ntuple(+, N), accumulator=sum, weight=1) where {N,T}
myscale = apply_tuple_list((x,y)-> T.(x ./ y), get_scale(size(arr), scale), optional_mat_to_iter(k_max))
myscale2 = apply_tuple_list((x,y)-> T.(-2pi .* x .* y), get_scale(size(arr), scale), optional_mat_to_iter(shift_by))
return cispi.((2 .*Δz) .* 
        phase_kz(eltype(arr),size(arr), scale = myscale,  offset=offset, dims = dims, accumulator=accumulator) .+
        2 .* phase_kxy(eltype(arr), size, scale = myscale2, offset=offset, dims = dims, accumulator=accumulator, weight=weight))
end

# These versions of Gaussians interpret sigma as the standard-deviation along each axis separately
function gaussian(::Type{T}, size::NTuple{N, Int}; sigma=1.0, offset=CtrFT, scale=ScaUnit, dims=ntuple(+, N), accumulator=sum, weight=1) where {N,T}
    myscale = apply_tuple_list((x,y)-> T.(x ./( 2 .* y .*y)), get_scale(size, scale), optional_mat_to_iter(sigma))
    return exp_sqr(T, size, scale = myscale, offset=offset, dims = dims, accumulator=accumulator, weight=weight)
end

function gaussian(size::NTuple{N, Int}; sigma=1.0, offset=CtrFT, scale=ScaUnit, dims=ntuple(+, N), accumulator=sum, weight=1) where {N,T}
    myscale = apply_tuple_list((x,y)-> DEFAULT_T.(x ./( 2 .* y .*y)), get_scale(size, scale), optional_mat_to_iter(sigma))
    return exp_sqr(DEFAULT_T, size, scale = myscale, offset=offset, dims = dims, accumulator=accumulator, weight=weight)
end

function gaussian(arr::AbstractArray{T, N}; sigma=1.0, offset=CtrFT, scale=ScaUnit, dims=ntuple(+, N), accumulator=sum, weight=1) where {N,T}
    myscale = apply_tuple_list((x,y)-> T.(x ./( 2 .*y.*y)), get_scale(size(arr), scale), optional_mat_to_iter(sigma))
    return exp_sqr(arr, scale = myscale,  offset=offset, dims = dims, accumulator=accumulator, weight=weight)
end

function normal(::Type{T}, size::NTuple{N, Int}; sigma=1.0, offset=CtrFT, scale=ScaUnit, dims=ntuple(+, N), accumulator=sum, weight=1) where {N,T}
    myscale = apply_tuple_list((x,y)-> T.(x ./( 2 .*y.*y)), get_scale(size, scale), optional_mat_to_iter(sigma))
    return exp_sqr_norm(T, size, scale = myscale, offset=offset, dims = dims, accumulator=accumulator, weight=weight)
end

function normal(size::NTuple{N, Int}; sigma=1.0, offset=CtrFT, scale=ScaUnit, dims=ntuple(+, N), accumulator=sum, weight=1) where {N,T}
    myscale = apply_tuple_list((x,y)-> DEFAULT_T.(x ./( 2 .*y.*y)), get_scale(size, scale), optional_mat_to_iter(sigma))
    return exp_sqr_norm(DEFAULT_T, size, scale = myscale, offset=offset, dims = dims, accumulator=accumulator, weight=weight)
end

function normal(arr::AbstractArray{T, N}; sigma=1.0, offset=CtrFT, scale=ScaUnit, dims=ntuple(+, N), accumulator=sum, weight=1) where {N,T}
    myscale = apply_tuple_list((x,y)-> T.(x ./( 2 .*y.*y)), get_scale(size(arr), scale), optional_mat_to_iter(sigma))
    return exp_sqr_norm(arr, scale = myscale,  offset=offset, dims = dims, accumulator=accumulator, weight=weight)
end
