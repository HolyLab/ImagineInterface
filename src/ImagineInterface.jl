module ImagineInterface

using JSON, Unitful
using MappedArrays, AxisArrays, IntervalSets
using Compat

import Base: convert, show, length, size, isempty, ==, append!, pop!, empty! #, scale

using Unitful: μm, s, V
@compat const HasVoltageUnits{T,U} = Quantity{T, typeof(0.0V).parameters[2], U}
@compat const HasTimeUnits{T,U} = Quantity{T, typeof(0.0s).parameters[2], U}
@compat const HasInverseTimeUnits{T,U} = Quantity{T, typeof(inv(0.0s)).parameters[2], U}
@compat const HasLengthUnits{T,U} = Quantity{T, typeof(0.0μm).parameters[2], U}

include("samplemapper.jl")
include("imaginecommand.jl")
include("constants.jl")
include("hardware.jl")
include("convenience.jl")
include("parse.jl")
include("write.jl")
include("stack.jl")

#imaginecommand.jl
export ImagineCommand,
        name,
	rawtype,
        worldtype,
        samprate,
        intervals,
        interval_raw,
        interval_volts,
        interval_world,
	isdigital,
        sequences,
	sequence_names,
	sequence_lookup,
        mapper,
        decompress,
        replace!

#constants.jl
export rigtemplate

#convenience.jl
export getname,
        getdigital,
        getanalog,
        getpositioners,
        getcameras,
        getlasers,
        getstimuli

#parse.jl
export parse_command,
        parse_commands

#write.jl
export write_commands

#stack.jl
export gen_sweep,
        gen_sawtooth,
        gen_bidi_pos,
        spaced_intervals,
        gen_pulses,
        scale

end #module
