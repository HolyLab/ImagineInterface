#TODO: set more constants.  A partial is below.  These should probably be OCPI rig-specific
#   --keys for extracting conversion factor for raw data to volts (first needs to be added to the metadata in the JSON file)
#       *We may want to store the DAQ's raw type, min voltage, and max voltage in the json metadata
#   --other constants that will help with reading .ai or .di files from various rigs

const ANALOG_KEY = "analog waveform"
const DIGITAL_KEY = "digital pulse"
const COMPONENT_KEY = "wave list"
const METADATA_KEY = "metadata"
const VERSION_KEY = "version"
const VERSION_STRING = "v1.0"
const RIGS = String[]

#The keys of all dictionaries below will be rig name strings, and the values will be lists of channels
#Currently we assign these in the files in the "rigs" folder.  Should do something more elegant soon, like abstracting channels, rigs, and cameras
const DEFAULT_DAQCHANS_TO_NAMES = Dict()
const DEFAULT_NAMES_TO_DAQCHANS = Dict()
#Lists of analog output channels
const AO_CHANS= Dict()
#Lists of analog input channels
const AI_CHANS= Dict()
#Lists of digital output channels
const DO_CHANS= Dict()
#Lists of digital input channels
const DI_CHANS= Dict()
#Lists of positioner control daq channels (a subset of AO_CHANS)
const POS_CONTROL_CHANS= Dict()
#Lists of positioner monitor daq channels (a subset of AI_CHANS)
const POS_MONITOR_CHANS= Dict()
#Lists of camera control daq channels
const CAM_CONTROL_CHANS= Dict()
#Lists of camera frame monitor daq chans
const CAM_MONITOR_CHANS= Dict()
#Lists of laser daq channels
const LAS_CONTROL_CHANS= Dict()
#Lists of (digital) stimulus daq channels
const STIM_CHANS= Dict()
#Lists of galvo control daq channels
const GALVO_CONTROL_CHANS= Dict()
#Lists of galvo monitor daq chans
const GALVO_MONITOR_CHANS= Dict()

#These names aren't allowed to be changed by users when writing command files
const FIXED_NAMES = Dict()
const FIXED_DAQ_CHANS = Dict()
#camera chip sizes
const RIG_CHIP_SIZES = Dict()
#functions for calculating frame rate given two arguments: horizontal ROI size and vertical ROI size (in pixels)
const RIG_FRAMERATE_FUNCS = Dict() #calculate max framerate given ROI
const RIG_ROI_FUNCS = Dict() #the inverse of the framerate function
#voltage ranges of analog channels
const AO_RANGE = Dict()
const AI_RANGE = Dict()
#Tuple of intervals describing the distance range and voltage range of the piezo for each rig
const PIEZO_RANGES = Dict()
#Unitful quantities (um / s) describing maximum allowed speed of piezo
const PIEZO_MAX_SPEED = Dict()
#Unitful quantities (s) describing minimum time for laser to switch from off to on
const LASER_ON_TIME = Dict()
#Unitful quantities (s) describing minimum time for laser to switch from on to off
const LASER_OFF_TIME = Dict()
const CAMERA_ON_TIME = Dict()
const CAMERA_OFF_TIME = Dict()
#Utility functions for querying rig channel information
daq_channel_number(ch::AbstractString) = parse(Int, last(split("AO0", ['.', 'I', 'O'])))

isfree(daq_chan::AbstractString, rig::AbstractString) = !in(daq_chan, FIXED_DAQ_CHANS[rig])
isdigital(daq_chan::AbstractString, rig::AbstractString) = in(daq_chan, DI_CHANS[rig]) || in(daq_chan, DO_CHANS[rig])
isoutput(daq_chan::AbstractString, rig::AbstractString) = in(daq_chan, AO_CHANS[rig]) || in(daq_chan, DO_CHANS[rig])
ispos(daq_chan::AbstractString, rig::AbstractString) = in(daq_chan, POS_CONTROL_CHANS[rig])
isposmonitor(daq_chan::AbstractString, rig::AbstractString) = in(daq_chan, POS_MONITOR_CHANS[rig])
iscam(daq_chan::AbstractString, rig::AbstractString) = in(daq_chan, CAM_CONTROL_CHANS[rig])
iscammonitor(daq_chan::AbstractString, rig::AbstractString) = in(daq_chan, CAM_MONITOR_CHANS[rig])
islas(daq_chan::AbstractString, rig::AbstractString) = in(daq_chan, LAS_CONTROL_CHANS[rig])
isstim(daq_chan::AbstractString, rig::AbstractString) = in(daq_chan, STIM_CHANS[rig])
isgalvo(daq_chan::AbstractString, rig::AbstractString) = in(daq_chan, GALVO_CONTROL_CHANS[rig])
isgalvomonitor(daq_chan::AbstractString, rig::AbstractString) = in(daq_chan, GALVO_MONITOR_CHANS[rig])

#For querying rig camera info
function chip_size(rig::AbstractString)
    if !in(rig, RIGS)
        error("Unrecognized rig")
    end
    return RIG_CHIP_SIZES[rig]
end

function max_framerate(rig::AbstractString, hsize::Int, vsize::Int)
    if !in(rig, RIGS)
        error("Unrecognized rig")
    end
    return RIG_FRAMERATE_FUNCS[rig]((hsize,vsize)) * Unitful.s^-1
end

#returns the size of the largest ROI that can be captured at a desired framerate
function max_roi(rig::AbstractString, framerate::HasInverseTimeUnits)
    if !in(rig, RIGS)
        error("Unrecognized rig")
    end
    return RIG_ROI_FUNCS[rig](framerate)
end

#TODO: abstract camera, move the below stuff to separate files.
const PCO_EDGE_5_5_CHIP_SIZE = (2560, 2160)
const PCO_EDGE_4_2_CHIP_SIZE = (2060, 2048) #We use the (older) CameraLink version (without the new sensor)
const PCO_EDGE_5_5_FRAMERATE_FUNC = x::Tuple{Int,Int} -> max(100 * 2^(log(2, PCO_EDGE_5_5_CHIP_SIZE[2]/x[2])), 100.0)
const PCO_EDGE_4_2_FRAMERATE_FUNC = x::Tuple{Int,Int} -> max(100 * 2^(log(2, PCO_EDGE_4_2_CHIP_SIZE[2]/x[2])), 100.0)
const PCO_EDGE_5_5_ROI_FUNC = x::HasInverseTimeUnits -> (PCO_EDGE_5_5_CHIP_SIZE[1], min(PCO_EDGE_5_5_CHIP_SIZE[2], floor(Int, PCO_EDGE_5_5_CHIP_SIZE[2]/upreferred(x/100s^-1))))
const PCO_EDGE_4_2_ROI_FUNC = x::HasInverseTimeUnits -> (PCO_EDGE_4_2_CHIP_SIZE[1], min(PCO_EDGE_4_2_CHIP_SIZE[2], floor(Int, PCO_EDGE_4_2_CHIP_SIZE[2]/upreferred(x/100s^-1))))
#const EXPOSURE_TRIGGER_DELAY = 0.0 * Unitful.ns #This is trivially short.  See measurements posted in ImagineInterface issue #18 

