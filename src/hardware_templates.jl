function default_samplemapper(rig_name::String, daq_chan_name::String; sample_rate = 10000s^-1)
    #is_digi_funcs = [iscam, islas, isstim, iscammonitor]
    #any(map(f->f(daq_chan_name, rig_name)), is_digi_funcs)
    if isdigital(daq_chan_name, rig_name)
        return ttl_samplemapper(; sample_rate = sample_rate)
    elseif ispos(daq_chan_name, rig_name) || isposmonitor(daq_chan_name, rig_name)
        return piezo_samplemapper(default_piezo_ranges[rig_name]...; rawtype = Int16, sample_rate = sample_rate)
    elseif isanalog(daq_chan_name, rig_name)
        if isoutput(daq_chan_name, rig_name)
            return generic_ao_samplemapper(-10.0V..10.0V; rawtype = Int16, sample_rate = sample_rate)
        else
            return generic_ai_samplemapper(-10.0V..10.0V; rawtype = Int16, sample_rate = sample_rate)
        end
    else
        error("Unrecognized channel name")
    end
end

function generic_ao_samplemapper{TV<:HasVoltageUnits, TU}(v::AbstractInterval{TV}; rawtype=Int16, sample_rate::HasInverseTimeUnits{Int, TU}=10000s^-1)
    return SampleMapper(typemin(rawtype), typemax(rawtype), minimum(v), maximum(v), minimum(v), maximum(v), sample_rate)
end

generic_ai_samplemapper = generic_ao_samplemapper

function piezo_samplemapper{TL<:HasLengthUnits,TV<:HasVoltageUnits, TU}(p::AbstractInterval{TL}, v::AbstractInterval{TV}; rawtype=Int16, sample_rate::HasInverseTimeUnits{Int, TU}=10000s^-1)
    return SampleMapper(zero(rawtype), typemax(rawtype), minimum(v), maximum(v), minimum(p), maximum(p), sample_rate)
end

#Shortcut for creating a generic digital TTL SampleMapper, assumes TTL level of 3.3V (though this doesn't matter to Imagine, only for visualizing in Julia)
function ttl_samplemapper{U}(; sample_rate::HasInverseTimeUnits{Int, U}=10000s^-1)
    return SampleMapper(UInt8(false), UInt8(true), 0.0*Unitful.V, 3.3*Unitful.V, false, true, sample_rate)
end

const default_piezo_ranges = Dict("ocpi-1"=>(0.0μm .. 400.0μm, 0.0V .. 10.0V),
                                  "ocpi-2"=>(0.0μm .. 800.0μm, 0.0V .. 10.0V))
const generic_ao_range = Dict("ocpi-1"=>0.0V .. 10.0V,
                                  "ocpi-2"=>0.0V .. 10.0V)
const generic_ai_range = generic_ao_range #TODO: make sure this is true.  (true if we are recording -10..10V on analog inputs)


#returns an array of empty ImagineCommands, one for each channel accessible to OCPI2 users
function rigtemplate{U}(rig::String; sample_rate::HasInverseTimeUnits{Int,U} = 10000s^-1)
    if !in(rig, RIGS)
        error("Unsupported rig")
    end
    coms = ImagineCommand[]
    shared_dict = Dict()
    name_lookup = DEFAULT_DAQCHANS_TO_NAMES[rig]
    #analog outputs
    for c in AO_CHANS[rig]
        if ispos(c, rig)
            push!(coms, ImagineCommand(name_lookup[c], c, rig, [], String[], shared_dict, Int[], piezo_samplemapper(default_piezo_ranges[rig]...; rawtype = Int16, sample_rate = sample_rate)))
        else
            push!(coms, ImagineCommand(name_lookup[c], c, rig, [], String[], shared_dict, Int[], generic_ao_samplemapper(generic_ao_range[rig]; rawtype = Int16, sample_rate = sample_rate)))
        end
    end
    #camera outputs
    for c in CAM_CONTROL_CHANS[rig]
        push!(coms, ImagineCommand(name_lookup[c], c, rig, [], String[], shared_dict, Int[], ttl_samplemapper(;sample_rate = sample_rate)))
    end
    #laser outputs
    for c in LAS_CONTROL_CHANS[rig]
        push!(coms, ImagineCommand(name_lookup[c], c, rig, [], String[], shared_dict, Int[], ttl_samplemapper(;sample_rate = sample_rate)))
    end
    #stimuli
    for c in STIM_CHANS[rig]
        push!(coms, ImagineCommand(name_lookup[c], c, rig, [], String[], shared_dict, Int[], ttl_samplemapper(;sample_rate = sample_rate)))
    end
    #analog inputs
    for c in AI_CHANS[rig]
        if ispos(c, rig)
            push!(coms, ImagineCommand(name_lookup[c], c, rig, [], String[], shared_dict, Int[], piezo_samplemapper(default_piezo_ranges[rig]...; rawtype = Int16, sample_rate = sample_rate)))
        else
            push!(coms, ImagineCommand(name_lookup[c], c, rig, [], String[], shared_dict, Int[], generic_ai_samplemapper(generic_ai_range[rig]; rawtype = Int16, sample_rate = sample_rate)))
        end
    end
    #digital inputs (including cameras)
    for c in DI_CHANS[rig]
        push!(coms, ImagineCommand(name_lookup[c], c, rig, [], String[], shared_dict, Int[], ttl_samplemapper(;sample_rate = sample_rate))) #TODO: handle bit-packing (.di file convention)
    end

    return coms
end
