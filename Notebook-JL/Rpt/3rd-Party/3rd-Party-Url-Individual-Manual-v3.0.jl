## Tables and Data Source setup

using ODBC
using DataFrames
using DSWB
using Formatting
using URIParser

dsn = "dswb-natgeo" # Redshift esetTable(tableRt, tableType = "RESOURCE_TABLE")ndpoint
table = "beacons_4744" # beacon table name
tableRt = "beacons_4744_rt"

# Connect to Beacon Data
setRedshiftEndpoint(dsn)
setTable(table)
setTable(tableRt, tableType = "RESOURCE_TABLE")

include("../../../Lib/Include-Package-v2.1.jl")
include("../../../Lib/URL-Classification-Package-v2.0.jl")

TV = pickTime()
#TV = timeVariables(2017,11,28,13,59,2017,11,28,14,59)

UP = UrlParamsInit(scriptName)
UrlParamsValidate(UP)

SP = ShowParamsInit()
SP.reportLevel=2
ShowParamsValidate(SP)

WellKnownHostDirectory = wellKnownHostEncyclopedia(SP.debug);
WellKnownPath = wellKnownPathDictionary(SP.debug);

localTableDF = defaultBeaconsToDF(TV,UP,SP)
println("Local Beacon Table count is ",size(localTableDF)[1])

# Stats on the data
statsDF = DataFrame()
statsDF = beaconStats(TV,UP,SP,localTableDF)
UP.timeLowerMs = round(statsDF[1:1,:median][1] * 0.90)
UP.timeUpperMs = round(statsDF[1:1,:median][1] * 1.10)

# medium
#UP.timeLowerMs = 4.0 * 1000
#UP.timeeUpperMs = 5.5 * 1000
localTableRtDF = getResourcesForBeaconToDF(TV,UP)
println("Matching Resource Table count is ",size(localTableRtDF)[1])

showAvailableSessions(UP,SP,localTableDF,localTableRtDF)

try

    if isdefined(:Session1)
        Session1
    end


    catch y
    println("studySession Exception ",y)
end
;
