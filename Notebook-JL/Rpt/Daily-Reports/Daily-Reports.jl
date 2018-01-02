## Tables and Data Source setup

using ODBC
using DataFrames
using DSWB
using Formatting

dsn = "dswb-natgeo" # Redshift endpoint
table = "beacons_4744" # beacon table name
tableRt = "beacons_4744_rt"

# Connect to Beacon Data
setRedshiftEndpoint(dsn)
setTable(table)
# setTable(tableRt, tableType = "RESOURCE_TABLE")

include("../../../Lib/Include-Package.jl")

TV = pickTime()
#TV = timeVariables(2017,11,15,23,59,2017,11,16,23,59)

UP = UrlParamsInit(scriptName)
UrlParamsValidate(UP)

SP = ShowParamsInit()
ShowParamsValidate(SP)

dailyWorkflow(TV,UP,SP)

# Desktop

UP.deviceType = "Desktop"
UrlParamsValidate(UP)

dailyWorkflow(TV,UP,SP)

# Mobile Android OS

UP.deviceType = "Mobile"
UP.agentOs = "Android OS"
UrlParamsValidate(UP)

dailyWorkflow(TV,UP,SP)

# Mobile iOS

UP.deviceType = "Mobile"
UP.agentOs = "iOS"
UrlParamsValidate(UP)

dailyWorkflow(TV,UP,SP)
;