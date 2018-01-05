

function curlJsonWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams,CU::CurlParams)

    if CU.synthetic
        finalDict = syntheticCommands(TV,UP,SP,CU)
    elseif CU.syntheticBodySize
        finalDict = syntheticCommands(TV,UP,SP,CU)
    else
        println("NR Type not yet defined")
        return
    end

    return finalDict

end

function curlCommands(TV::TimeVars,UP::UrlParams,SP::ShowParams,CU::CurlParams)

    if CU.apiAdminKey != "no id"
    else
        Key = "unknown"
    end

    if CU.syntheticListAllMonitors
        apiKey = "X-Api-Key:" * CU.apiAdminKey
        curlCommand = "https://synthetics.newrelic.com/synthetics/api/v3/monitors"
        curlStr = ["-H","$apiKey","$curlCommand"]
    elseif CU.syntheticListOneMonitor
        apiKey = "X-Api-Key:" * CU.apiAdminKey
        curlCommand = "https://synthetics.newrelic.com/synthetics/api/v3/monitors/" * CU.syntheticCurrentMonitorId
        curlStr = ["-H","$apiKey","$curlCommand"]
    elseif CU.syntheticBodySize
        apiKey = "X-Query-Key:" * CU.apiQueryKey
        curlCommand = "https://insights-api.newrelic.com/v1/accounts/78783/query?nrql=select%20average(totalResponseBodySize)%20FROM%20SyntheticCheck%20WHERE%20%20monitorName%20%3D%27JTP-Gallery-Equinox-M%27%20SINCE%207%20days%20ago%20TIMESERIES%20%20auto"
        curlStr = ["-H","$apiKey","$curlCommand"]
    elseif CU.syntheticBodySizeByRequest
        apiKey = "X-Query-Key:" * CU.apiQueryKey
        curlCommand = "https://insights-api.newrelic.com/v1/accounts/78783/query?nrql=SELECT%20average(responseBodySize)%20FROM%20SyntheticRequest%20WHERE%20monitorId%20%3D%20%2769599173-5b61-41e0-b4e6-ba69e179bc70%27%20since%207%20days%20ago%20%20TIMESERIES"
        curlStr = ["-H","$apiKey","$curlCommand"]
    else
        curlCommand = "unknown command"
    end

    # curl -H "Accept: application/json" -H ""
    #

    # Todo regular expression tests for "unknown" and report failure and return empty

    curlCmd = `curl $curlStr`
    jsonString = readstring(curlCmd)

    # Picked syn monitor "JTP-Gallery-Equinox-M"
    #  curl -v  -H 'X-Api-Key:b2abadd58593d10bb39329981e8b702d'
    #'https://synthetics.newrelic.com/synthetics/api/v3/monitors/69599173-5b61-41e0-b4e6-ba69e179bc70'

    return jsonString

end

function syntheticCommands(TV::TimeVars,UP::UrlParams,SP::ShowParams,CU::CurlParams)

    #  List all syn monitors
    #   curl -v  -H 'X-Api-Key:b2abadd58593d10bb39329981e8b702d' 'https://synthetics.newrelic.com/synthetics/api/v3/monitors'
    if CU.syntheticListAllMonitors
        jsonInput = curlCommands(TV,UP,SP,CU)
        finalDict = curlSyntheticJson(SP,jsonInput)
        return finalDict
    end

    # Picked syn monitor "JTP-Gallery-Equinox-M"
    #  curl -v  -H 'X-Api-Key:b2abadd58593d10bb39329981e8b702d' 'https://synthetics.newrelic.com/synthetics/api/v3/monitors/69599173-5b61-41e0-b4e6-ba69e179bc70'
    if CU.syntheticListOneMonitor
        jsonInput = curlCommands(TV,UP,SP,CU)
        finalDict = curlSyntheticJson(SP,jsonInput)
        return finalDict
    end

    # curl -H "Accept: application/json" -H "X-Query-Key: HFdC9JQE7P3Bkwk9HMl0kgVTH2j5yucx"
    # "https://insights-api.newrelic.com/v1/accounts/78783/query?nrql=SELECT%20average(responseBodySize)%20FROM%20SyntheticRequest%20WHERE%20monitorId%20%3D%20%2769599173-5b61-41e0-b4e6-ba69e179bc70%27%20since%207%20days%20ago%20%20TIMESERIES

    if CU.syntheticBodySize
        jsonInput = curlCommands(TV,UP,SP,CU)
        finalDict = curlSyntheticJson(SP,jsonInput)
    end


end

function curlSyntheticJson(SP::ShowParams,jList::ASCIIString)

    if SP.debugLevel > 8
        println("jList=",jList)
    end

    jParsed = JSON.parse(jList)

    if SP.debugLevel > 4
        println(jParsed)
        println(typeof(jParsed))
    end

    return jParsed
end

function timeSizeRequestsWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams,Nr::NrParams,synChkBodySizeDict::Dict)

    openingTitle(TV,UP,SP)

    investigateSizeProblems(TV,UP,SP,NR,synChkBodySizeDict)

end

function investigateSizeProblems(TV::TimeVars,UP::UrlParams,SP::ShowParams,NR::NrParams,synChkBodySizeDict::Dict)


end

function newRelicConvert(SP::ShowParams,NR::NrParams,synChkBodySizeDict::Dict)

    #newDF = DataFrame(synChkBodySizeDict)
    #beautifyDF(newDF)
    #newDF = DataFrame(; [symbol(k)=>v for (k,v) in synChkBodySizeDict]...)
    #beautifyDF(newDF)

    fillNrTotal(SP,NR,synChkBodySizeDict["total"])
    println()
    println("Total: Inspected=",NR.totals.inspectedCount,
            " Begin Sec=",NR.totals.beginTimeSeconds,
            " End Sec=",NR.totals.endTimeSeconds,
            " Result Average=",NR.totals.resultAverage
            )
    println()

#    println("Dict List ",keys(synChkBodySizeDict))
#    println("Meta  Dict ",keys(synChkBodySizeDict["metadata"]))
#    println("Perf  Dict ",keys(synChkBodySizeDict["performanceStats"]))
    #This is an array println("TimeS Dict ",keys(synChkBodySizeDict["timeSeries"]))

end

# Simple three fields with one tricky field
function fillNrTotal(SP::ShowParams,NR::NrParams,totalDict::Dict)

    if SP.debugLevel > 8
        println("Total Dict ",totalDict)
    end

    NR.totals.inspectedCount = totalDict["inspectedCount"]
    NR.totals.endTimeSeconds = totalDict["endTimeSeconds"]
    NR.totals.beginTimeSeconds = totalDict["beginTimeSeconds"]

    # Assuming only one result for now
    for result in totalDict["results"]
        NR.totals.resultAverage = result["average"]
    end
end
