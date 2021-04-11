export Sca,ScaUnit,ScaNorm,ScaFT,ScaFTEdge
export Ctr,CtrCorner,CtrFFT,CtrFT,CtrMid,CtrEnd, CtrRFFT,CtrRFT  # These do not work, as they need the size information about the real-space array


# define types to specify where the center point is
abstract type Ctr end  # Center of the array
struct CtrCorner <: Ctr end  # corner voxel is zero
struct CtrFFT <: Ctr end # corresponding to FFTs
struct CtrRFFT <: Ctr end # corresponding to RFFTs
struct CtrFT <: Ctr end # corresponding to FTs  (meaning shifted FFTs)
struct CtrRFT <: Ctr end # corresponding to RFTs
struct CtrMid <: Ctr end # middle of the array
struct CtrEnd <: Ctr end # other corner voxel is zero

"""
    Ctr

Abstract type to specify the reference position
from which several other types subtype.

# Possible subtypes
* `CtrCorner`: Set the reference pixel in the corner
* `CtrFFT`: Set the reference pixel to the FFT center.
* `CtrFT`: Set the reference pixel to the FT center. FT means that the zero frequency is at the FFT convention center (`size ÷ 2 + 1`).
* `CtrRFFT`: Set the reference pixel to the RFFT center. Same as `CtrFFT` but the first dimension has center at 1. 
* `CtrRFT`: Set the reference pixel to the RFT center. FT means that the zero frequency is at the FFT convention center (`size ÷ 2 + 1`). 
            Same as `CtrFT` but the first dimension has center at 1.
* `CtrMid`: Set the reference pixel to real mid. For uneven arrays it is the center pixel, for even arrays it is the centered around a half pixel.
* `CtrEnd` Set the reference to the end corner (last pixel)
"""
Ctr

get_offset(size, ::Type{CtrCorner}) = size.*0 .+ 1.0
get_offset(size, ::Type{CtrFT}) = size.÷2 .+ 1.0
get_offset(size, ::Type{CtrRFT}) = Base.setindex(size.÷2,0,1) .+ 1.0
get_offset(size, ::Type{CtrFFT}) = size.*0 .+ 1.0
get_offset(size, ::Type{CtrRFFT}) = size.*0 .+ 1.0
get_offset(size, ::Type{CtrMid}) = (size.+1)./2.0
get_offset(size, ::Type{CtrEnd}) = size.+0.0
get_offset(size, t::Number) = ntuple(i -> t, length(size))
get_offset(size, t::NTuple) = t



abstract type Sca end # scaling of the array
struct ScaUnit <: Sca end # pixel distance is one
struct ScaNorm <: Sca end # total size along each dimension normalized to 1.0
struct ScaFT <: Sca end # reciprocal Fourier coordinates
struct ScaRFT <: Sca end # reciprocal Fourier coordinates for rFTs. 
struct ScaFTEdge <: Sca end # such that the edge of the Fourier space is 1.0
struct ScaRFTEdge <: Sca end # such that the edge of the Fourier space is 1.0

"""
    Sca 

Abstract type to indicate a scaling from which several other types subtype.

# Possible subtypes
* `ScaUnit`: No scaling of the indices 
* `ScaNorm`: Total length along each dimension is normalized to 1
* `ScaFT`: Reciprocal Fourier coordinates
* `ScaFTEdge`: Such that the edge (in FFT sense) of the pixel is 1.0
"""
Sca

get_scale(size, ::Type{ScaUnit}) = ntuple(_ -> one(Int), length(size))
get_scale(size, ::Type{ScaNorm}) = 1 ./ (max.(size .- 1, 1)) 
get_scale(size, ::Type{ScaFT}) = 0.5 ./ (max.(size ./ 2, 1))
# get_scale(size, ::Type{ScaRFT}) = 0.5 ./ (max.(Base.setindex(size./ 2,size[1]-1,1), 1))  # These scales are wrong! They need the information on the real-space size!
get_scale(size, ::Type{ScaFTEdge}) = 1 ./ (max.(size ./ 2, 1))  
# get_scale(size, ::Type{ScaRFTEdge}) = 1 ./ (max.(Base.setindex(size./ 2,size[1]-1,1), 1))
get_scale(size, t::Number) = ntuple(i -> t, length(size)) 
get_scale(size, t::NTuple) = t 

function apply_tuple_list(f, t1,t2)  # applies a two-argument function to tubles and iterables of tuples
    return f(t1,t2)
end

function apply_tuple_list(f, t1,t2::IterType)
    return Tuple([f(t1,a2) for a2 in t2])
end

function apply_tuple_list(f, t1::IterType,t2)
    return Tuple([f(a1,t2) for a1 in t1])
end
