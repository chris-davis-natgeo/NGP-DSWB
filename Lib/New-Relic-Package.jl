function curlJsonWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams,CU::CurlParams)

    if CU.synthetic
        finalDF = syntheticCommands(TV,UP,SP,CU)
    else
        println("NR Type not yet defined")
        return
    end

    if (SP.debugLevel > 8)
        beautifyDF(finalDF[1:min(10,end),:])
    end

    return finalDF

end

function curlCommands(TV::TimeVars,UP::UrlParams,SP::ShowParams,CU::CurlParams)

    if CU.apiAdminKey != "no id"
        Key = CU.apiAdminKey
    else
        Key = "unknown"
    end

    if CU.syntheticListAllMonitors
        curlCommand = "https://synthetics.newrelic.com/synthetics/api/v3/monitors"
    elseif CU.syntheticListOneMonitor
        curlCommand = "https://synthetics.newrelic.com/synthetics/api/v3/monitors/" * CU.syntheticCurrentMonitorId
    else
        curlCommand = "unknown command"
    end

    # Todo regular expression tests for "unknown" and report failure and return empty
    if SP.debugLevel > 0
        println("To run: ", curlStr)
        println("Into  : ", CU.jsonFilename)
    end

    curlStr1 = ["-v","-H","X-Api-Key:$Key","$curlCommand"]
    #curlStr2 = ["-v","-H","X-Api-Key:b2abadd58593d10bb39329981e8b702d","https://synthetics.newrelic.com/synthetics/api/v3/monitors/69599173-5b61-41e0-b4e6-ba69e179bc70"]
    curlCmd = `curl $curlStr1`
    #println(typeof(curlCmd))
    #println(curlCmd)
    jsonString = readstring(curlCmd)
    #println("a is ",a)
    #println(typeof(a))

    # Picked syn monitor "JTP-Gallery-Equinox-M"
    #  curl -v  -H 'X-Api-Key:b2abadd58593d10bb39329981e8b702d'
    #'https://synthetics.newrelic.com/synthetics/api/v3/monitors/69599173-5b61-41e0-b4e6-ba69e179bc70'

end

function syntheticCommands(TV::TimeVars,UP::UrlParams,SP::ShowParams,CU::CurlParams)

    #  List all syn monitors
    #   curl -v  -H 'X-Api-Key:b2abadd58593d10bb39329981e8b702d' 'https://synthetics.newrelic.com/synthetics/api/v3/monitors'
    if CU.syntheticListAllMonitors
        curlCommands(TV,UP,SP,CU)
        finalDF = curlSyntheticListAllMonitorJson(TV,UP,SP,CU)
        return finalDF
    end

    # Picked syn monitor "JTP-Gallery-Equinox-M"
    #  curl -v  -H 'X-Api-Key:b2abadd58593d10bb39329981e8b702d' 'https://synthetics.newrelic.com/synthetics/api/v3/monitors/69599173-5b61-41e0-b4e6-ba69e179bc70'
    if CU.syntheticListOneMonitor
        curlCommands(TV,UP,SP,CU)
        finalDF = curlSyntheticListOneMonitorJson(TV,UP,SP,CU)
        return finalDF
    end

end

function curlSyntheticListOneMonitorJson(TV::TimeVars,UP::UrlParams,SP::ShowParams,CU::CurlParams)

    #urlListDF = newPagesList(UP,SP)
    #listToUseDV = urlListDF[:urlgroup] * "%"
    #finalListToUseDV = cleanupTopUrlTable(listToUseDV)
    jList = JSON.parsefile(CU.jsonFilename)
    if SP.debugLevel > 0
        println("jList=",jList)
    end


end


function curlSyntheticListAllMonitorJson(TV::TimeVars,UP::UrlParams,SP::ShowParams,CU::CurlParams)

    #urlListDF = newPagesList(UP,SP)
    #listToUseDV = urlListDF[:urlgroup] * "%"
    #finalListToUseDV = cleanupTopUrlTable(listToUseDV)

end


function timeSizeRequestsWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)
    openingTitle(TV,UP,SP)

end
