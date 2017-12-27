
# Display 10 rows of DataFrame
function display10Rows(df::DataFrame, nameArr::Array)
    beautifyDF(names!(df[1:min(10, end),[1:3;]],nameArr))
end

function displayManyRows(df::DataFrame, nameArr::Array, limit::Int64)
    beautifyDF(names!(df[1:min(limit, end),[1:3;]],nameArr))
end

function deviceTypeTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    try
        fieldNames = [:user_agent_device_type]
        treeData = getTreemapData(TV.startTimeUTC, TV.endTimeUTC, fieldNames = fieldNames)
        treeData[:x1] = "Natgeo - All"
        displayTitle(chart_title = "Device Type for Page Group: $(UP.pageGroup)", chart_info = [TV.timeString],showTimeStamp=false)
        drawTree(treeData; titleCol = :x1, fieldNames = fieldNames)

        if (SP.devView)
            # Format beacon output
            sort!(treeData, cols=:beacons, rev=true)
            displayTitle(chart_title = "Device Type for Page Group: $(UP.pageGroup)", chart_info = ["Highest Beacon Counts and Load Time"],showTimeStamp=false)
            # Keep rows with beacon count > 500
            # treeData = treeData[treeData[:beacons].>499,:]
            displayManyRows(treeData[:,1:3], [Symbol("User Agent Family"), Symbol("Load Time"), Symbol("Beacons")],SP.treemapTableLines)
        end

    catch y
        println("deviceTypeTreemap Exception ",y)
    end
end

function pageGroupTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    try
        treeData = getTreemapData(TV.startTimeUTC, TV.endTimeUTC, fieldNames = [:page_group])
        treeData[:x1] = "Natgeo - All"
        chartTile = "$(UP.pageGroup) Page Group"
        if UP.pageGroup == "%"
            chartTile = "All Page Groups"
        end
        displayTitle(chart_title = chartTile, chart_info = [TV.timeString],showTimeStamp=false)
        drawTree(treeData; titleCol = :x1, fieldNames = [:page_group])

        if (SP.devView)
            sort!(treeData, cols=:beacons, rev=true)
            displayTitle(chart_title = chartTile, chart_info = ["Highest Beacon Counts and Load Times"],showTimeStamp=false)
            # Keep rows with beacon count > 500
            treeData = treeData[treeData[:beacons].>499,:]
            displayManyRows(treeData[:,1:3], [Symbol("Page Group"), Symbol("Load Time"), Symbol("Beacons")],SP.treemapTableLines)
        end

        treeData = getTreemapData(TV.startTimeUTC, TV.endTimeUTC, fieldNames = [:user_agent_device_type,:page_group])

        if (UP.deviceType == "Desktop" || UP.deviceType == "%")
            subTreeData = treeData[treeData[:, :user_agent_device_type] .== "Desktop", :]
            subTreeData[:x1] = "Natgeo - Desktop"
            displayTitle(chart_title = "Page Group - Desktop", chart_info = [TV.timeString],showTimeStamp=false)
            drawTree(subTreeData; titleCol = :x1, fieldNames = [:page_group])
            if (SP.devView)
                sort!(subTreeData, cols=:beacons, rev=true)
                displayTitle(chart_title = "Desktop", chart_info = ["Highest Beacon Counts and Load Times"],showTimeStamp=false)
                # Keep rows with beacon count > 499
                subTreeData = subTreeData[subTreeData[:beacons].>499,:]
                displayManyRows(subTreeData[:,2:4], [Symbol("Page Group");Symbol("Load Time");Symbol("Page Views")],SP.treemapTableLines)
            end
        end

        if (UP.deviceType == "Mobile" || UP.deviceType == "%")
            subTreeData = treeData[treeData[:, :user_agent_device_type] .== "Mobile", :]
            subTreeData[:x1] = "Natgeo - Mobile"
            displayTitle(chart_title = "Mobile", chart_info = [TV.timeString],showTimeStamp=false)
            drawTree(subTreeData; titleCol = :x1, fieldNames = [:page_group])
            if (SP.devView)
                sort!(subTreeData, cols=:beacons, rev=true)
                displayTitle(chart_title = "Mobile", chart_info = ["Highest Beacon Counts and Load Times"],showTimeStamp=false)
                # Keep rows with beacon count > 499
                subTreeData = subTreeData[subTreeData[:beacons].>499,:]
                displayManyRows(subTreeData[:,2:4], [Symbol("Page Group");Symbol("Load Time");Symbol("Page Views")],SP.treemapTableLines)
            end
        end
    catch y
        println("pageGroupTreemap Exception ",y)
    end
end

function browserFamilyTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    try
        treeData = getTreemapData(TV.startTimeUTC, TV.endTimeUTC, fieldNames = [:user_agent_family])
        treeData[:x1] = "Natgeo - All"
        displayTitle(chart_title = "Browser Family for Page Group: $(UP.pageGroup)", chart_info = [TV.timeString],showTimeStamp=false)
        drawTree(treeData; titleCol = :x1, fieldNames = [:user_agent_family])

        # Format beacon output
        sort!(treeData, cols=:beacons, rev=true)
        displayTitle(chart_title = "Browser Family for Page Group: $(UP.pageGroup)", chart_info = ["Highest Beacon Counts and Load Time"],showTimeStamp=false)

        # Keep rows with beacon count > 500
        # treeData = treeData[treeData[:beacons].>499,:]
        displayManyRows(treeData[:,[1:3;]], [Symbol("User Agent Family"), Symbol("Load Time"), Symbol("Beacons")],SP.treemapTableLines)
    catch y
        println("browserFamilyTreemap Exception ",y)
    end
end

function countryTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    try
        treeData = getTreemapData(TV.startTimeUTC, TV.endTimeUTC, fieldNames = [:geo_cc])
        treeData[:x1] = "Natgeo - All"
        displayTitle(chart_title = "Countries for Page Group: $(UP.pageGroup)", chart_info = [TV.timeString],showTimeStamp=false)
        drawTree(treeData; titleCol = :x1, fieldNames = [:geo_cc])

        # Format beacon output
        sort!(treeData, cols=:beacons, rev=true)
        displayTitle(chart_title = "Countries for Page Group: $(UP.pageGroup)", chart_info = ["Highest Beacon Counts and Load Time"],showTimeStamp=false)

        # Translate region abbreviations to names
        cc = getMapCountryNames()
        countries = DataArray([])
        for x in eachrow(treeData)
            countries = vcat(countries,cc[x[:geo_cc]])
        end

        treeData[:geo_cc] = countries
        displayManyRows(treeData[:,[1:3;]], [Symbol("Countries"), Symbol("Load Time"), Symbol("Beacons")],SP.treemapTableLines)
    catch y
        println("countryTreemap Exception ",y)
    end
end

function removeNotBlocking(localDF::DataFrame)
    try
        #watch for non-deep copies such as the functions below
        i = 1
        for x in localDF[:,:urlgroup]
            if x == "Not Blocking"
                deleterows!(localDF,i)
            end
            i += 1
        end
    catch y
        println("notBlocking Exception ",y)
    end
end

function notBlocking(localDF::DataFrame)
    try
        #watch for non-deep copies such as the functions below
        #i = 1
        #for x in localDF[:,:urlgroup]
        #    if x == "Not Blocking"
        #        deleterows!(localDF,i)
        #    end
        #    i += 1
        #end
        removeNotBlocking(localDF);

        push!(localDF,["Not Blocking",999999999,0,0,0,0,0,0,0,0,0,"Not Blocking",1,"Label",0,0])
    catch y
        println("notBlocking Exception ",y)
    end
end

function bodyTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams,toppageurl::DataFrame,beaconString::ASCIIString;showPageUrl::Bool=false,showTreemap::Bool=true)
    try
        totalTime = sum(toppageurl[:,:Total])
        currentTime = sum(toppageurl[:,:beacons])
        if currentTime > 0
            titlestring = "This includes time which is overlapped but does not include the gaps."
            title2string = "Note: beacons field is used for load time"
            displayTitle(chart_title = "$(beaconString) Times (K ms) For Page", chart_info = [titlestring,title2string,TV.timeString],showTimeStamp=false)

            notBlocking(toppageurl);
            toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:urlpagegroup] = "Not $(beaconString)"
            toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:Critical] = 0
            toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:beacons] = totalTime - currentTime

            treeDF = DataFrame()
            treeDF[:,:urlpagegroup] = toppageurl[:,:urlpagegroup]
            treeDF[:,:beacons] = toppageurl[:,:beacons]
            treeDF[:,:label] = toppageurl[:,:label]
            treeDF[:,:load_time] = toppageurl[:,:load_time]

            fieldNames = [:urlpagegroup]
            treeDF[:label] = "$(beaconString) Time"
            if (showTreemap)
                drawTree(treeDF; titleCol=:label, fieldNames=fieldNames,resourceColors=true)
            end
            removeNotBlocking(toppageurl)

            if (SP.devView)
                list = DataFrame()
                list[:,:urlpagegroup] = deepcopy(toppageurl[:,:urlpagegroup])
                list[:,:Total] = deepcopy(toppageurl[:,:Total])
                list[:,:beacons] = deepcopy(toppageurl[:,:beacons])
                if (showPageUrl)
                    list[:,:urlgroup] = deepcopy(toppageurl[:,:urlgroup])
                end

                totalPercentTime = sum(list[:,:beacons]) * 0.010
                sort!(list,cols=[order(:beacons,rev=true),order(:Total,rev=true)])

                totalPercentTime = list[1:1,:beacons] * 0.1
                list = list[Bool[x > totalPercentTime[1] for x in list[:beacons]],:]
                if (showPageUrl)
                    map!(x->replace(x,"%","\%"),list[:,:urlgroup])
                    beautifyDF(names!(list[1:min(SP.treemapTableLines,end),:],
                    [Symbol("URL Page Group"),Symbol("Total Time"),Symbol(beaconString),Symbol("Url Without Params")]))
                else
                    beautifyDF(names!(list[1:min(SP.treemapTableLines,end),:],
                    [Symbol("URL Page Group"),Symbol("Total Time"),Symbol(beaconString)]))
                end
            end
        else
            println("No $(beaconString) time.  Output nothing in report")
        end
    catch y
        println("bodyTreemap Exception ",y)
    end
end

function gapTreemapV2(TV::TimeVars,UP::UrlParams,SP::ShowParams,toppageurl::DataFrame;showPageUrl::Bool=false,showTreemap::Bool=true)
    try
        #beacons on Blocking
        beaconString = "Gap"
        toppageurl = names!(toppageurl[:,:],
        [Symbol("urlpagegroup"),Symbol("Start"),Symbol("Total"),Symbol("Redirect"),Symbol("Blocking"),Symbol("DNS"),
            Symbol("TCP"),Symbol("Request"),Symbol("Response"),Symbol("beacons"),Symbol("Critical"),Symbol("urlgroup"),
            Symbol("request_count"),Symbol("label"),Symbol("load_time"),Symbol("beacon_time")])

        bodyTreemap(TV,UP,SP,toppageurl,beaconString;showPageUrl=showPageUrl,showTreemap=showTreemap)

    catch y
        println("gapTreemapV2 Exception ",y)
    end
end

function blockingTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams,toppageurl::DataFrame;showPageUrl::Bool=false,showTreemap::Bool=true)
    try
        #beacons on Blocking
        beaconString = "Blocking"
        toppageurl = names!(toppageurl[:,:],
        [Symbol("urlpagegroup"),Symbol("Start"),Symbol("Total"),Symbol("Redirect"),Symbol("beacons"),Symbol("DNS"),
            Symbol("TCP"),Symbol("Request"),Symbol("Response"),Symbol("Gap"),Symbol("Critical"),Symbol("urlgroup"),
            Symbol("request_count"),Symbol("label"),Symbol("load_time"),Symbol("beacon_time")])

        bodyTreemap(TV,UP,SP,toppageurl,beaconString;showPageUrl=showPageUrl,showTreemap=showTreemap)

    catch y
        println("blockingTreemap Exception ",y)
    end
end

function dnsTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams,toppageurl::DataFrame;showPageUrl::Bool=false)
    try
        #beacons on DNS
        beaconString = "DNS"
        toppageurl = names!(toppageurl[:,:],
        [Symbol("urlpagegroup"),Symbol("Start"),Symbol("Total"),Symbol("Redirect"),Symbol("Blocking"),Symbol("beacons"),
            Symbol("TCP"),Symbol("Request"),Symbol("Response"),Symbol("Gap"),Symbol("Critical"),Symbol("urlgroup"),
            Symbol("request_count"),Symbol("label"),Symbol("load_time"),Symbol("beacon_time")])

        bodyTreemap(TV,UP,SP,toppageurl,beaconString;showPageUrl=showPageUrl)

    catch y
        println("dnsTreemap Exception ",y)
    end
end

function redirectTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams,toppageurl::DataFrame;showPageUrl::Bool=false)
    try
        #beacons on Redirect
        beaconString = "Redirect"
        toppageurl = names!(toppageurl[:,:],
        [Symbol("urlpagegroup"),Symbol("Start"),Symbol("Total"),Symbol("beacons"),Symbol("Blocking"),Symbol("DNS"),
            Symbol("TCP"),Symbol("Request"),Symbol("Response"),Symbol("Gap"),Symbol("Critical"),Symbol("urlgroup"),
            Symbol("request_count"),Symbol("label"),Symbol("load_time"),Symbol("beacon_time")])

        bodyTreemap(TV,UP,SP,toppageurl,beaconString;showPageUrl=showPageUrl)

    catch y
        println("redirectTreemap Exception ",y)
    end
end

function requestTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams,toppageurl::DataFrame;showPageUrl::Bool=false)
    try
        #beacons on Request
        beaconString = "Request"
        toppageurl = names!(toppageurl[:,:],
        [Symbol("urlpagegroup"),Symbol("Start"),Symbol("Total"),Symbol("Redirect"),Symbol("Blocking"),Symbol("DNS"),
            Symbol("TCP"),Symbol("beacons"),Symbol("Response"),Symbol("Gap"),Symbol("Critical"),Symbol("urlgroup"),
            Symbol("request_count"),Symbol("label"),Symbol("load_time"),Symbol("beacon_time")])

        bodyTreemap(TV,UP,SP,toppageurl,beaconString;showPageUrl=showPageUrl)

    catch y
        println("requestTreemap Exception ",y)
    end
end

function responseTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams,toppageurl::DataFrame;showPageUrl::Bool=false)
    try
        #beacons on Response
        beaconString = "Response"
        toppageurl = names!(toppageurl[:,:],
        [Symbol("urlpagegroup"),Symbol("Start"),Symbol("Total"),Symbol("Redirect"),Symbol("Blocking"),Symbol("DNS"),
            Symbol("TCP"),Symbol("Request"),Symbol("beacons"),Symbol("Gap"),Symbol("Critical"),Symbol("urlgroup"),
            Symbol("request_count"),Symbol("label"),Symbol("load_time"),Symbol("beacon_time")])

        bodyTreemap(TV,UP,SP,toppageurl,beaconString;showPageUrl=showPageUrl)

    catch y
        println("responseTreemap Exception ",y)
    end
end

function tcpTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams,toppageurl::DataFrame;showPageUrl::Bool=false)
    try
        #beacons on TCP
        beaconString = "TCP"
        toppageurl = names!(toppageurl[:,:],
        [Symbol("urlpagegroup"),Symbol("Start"),Symbol("Total"),Symbol("Redirect"),Symbol("Blocking"),Symbol("DNS"),
            Symbol("beacons"),Symbol("Request"),Symbol("Response"),Symbol("Gap"),Symbol("Critical"),Symbol("urlgroup"),
            Symbol("request_count"),Symbol("label"),Symbol("load_time"),Symbol("beacon_time")])

        bodyTreemap(TV,UP,SP,toppageurl,beaconString;showPageUrl=showPageUrl)

    catch y
        println("tcpTreemap Exception ",y)
    end
end

# Critical Path Display
function criticalPathTreemapV2(TV::TimeVars,UP::UrlParams,SP::ShowParams,labelField::ASCIIString,toppageurl::DataFrame)
    try
        #beacons on Critical
        toppageurl = names!(toppageurl[:,:],
            [Symbol("urlpagegroup"),Symbol("Start"),Symbol("Total"),Symbol("Redirect"),Symbol("Blocking"),Symbol("DNS"),
            Symbol("TCP"),Symbol("Request"),Symbol("Response"),Symbol("Gap"),Symbol("beacons"),Symbol("urlgroup"),
            Symbol("request_count"),Symbol("label"),Symbol("load_time"),Symbol("beacon_time")])

        notBlocking(toppageurl);
        toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:urlpagegroup] = "Time Waiting And/Or Executing Browser Side Code"
        toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:Gap] = 0  # Nice shade of red for waiting time
        toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:beacons] = sum(toppageurl[:,:Gap])

        treeDF = DataFrame()
        treeDF[:,:urlpagegroup] = toppageurl[:,:urlpagegroup]
        treeDF[:,:beacons] = toppageurl[:,:beacons]                      # Sum of all critical path numbers
        treeDF[:,:label] = toppageurl[:,:label]                          # Median of all load times in MS
        treeDF[:,:load_time] = toppageurl[:,:load_time]

        #display(treeDF[1:3,:])
        displayTitle(chart_title = "$labelField",showTimeStamp=false)
        fieldNames = [:urlpagegroup]
        treeDF[:label] = "Critical Path"
        drawTree(treeDF; titleCol=:label, fieldNames=fieldNames,resourceColors=true)
        removeNotBlocking(toppageurl)

        if (SP.devView)
            currentTime = sum(toppageurl[:,:beacons])
            if currentTime > 0
                list = DataFrame()
                list[:,:urlpagegroup] = deepcopy(toppageurl[:,:urlpagegroup])
                list[:,:Total] = deepcopy(toppageurl[:,:Total])
                list[:,:Critical] = deepcopy(toppageurl[:,:beacons])
                list[:,:urlgroup] = deepcopy(toppageurl[:,:urlgroup])

                totalPercentTime = sum(list[:,:Critical]) * 0.010
                sort!(list,cols=[order(:Critical,rev=true),order(:Total,rev=true)])
                displayTitle(chart_title = "Top Times By Critical Path Time (ms)",showTimeStamp=false)
                totalPercentTime = list[1:1,:Critical] * 0.1
                #Skip percent check
                #list = list[Bool[x > totalPercentTime[1] for x in list[:Critical]],:]
                beautifyDF(names!(list[1:min(SP.treemapTableLines,end),:],
                    [Symbol("URL Page Group"),Symbol("Total Time"),Symbol("Critical Path"),Symbol("Url Without Params")]))
            end
        end
    catch y
        println("criticalPathTreemapV2 Exception ",y)
    end
end

function endToEndTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams,toppageurl::DataFrame;showPageUrl::Bool=false)
    try
        #beacons on Total
        toppageurl = names!(toppageurl[:,:],
        [Symbol("urlpagegroup"),Symbol("Start"),Symbol("beacons"),Symbol("Redirect"),Symbol("Blocking"),Symbol("DNS"),
            Symbol("TCP"),Symbol("Request"),Symbol("Response"),Symbol("Gap"),Symbol("Critical"),Symbol("urlgroup"),
            Symbol("request_count"),Symbol("label"),Symbol("load_time"),Symbol("beacon_time")])

        #totalTime = sum(toppageurl[:,:Total])
        currentTime = sum(toppageurl[:,:beacons])
        totalTime = currentTime
        if currentTime > 0
            notBlocking(toppageurl);
            toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:urlpagegroup] = "Not End To End Time"
            toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:Critical] = 0
            toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:beacons] = totalTime - currentTime

            treeDF = DataFrame()
            treeDF[:,:urlpagegroup] = toppageurl[:,:urlpagegroup]
            treeDF[:,:beacons] = toppageurl[:,:beacons]
            treeDF[:,:label] = toppageurl[:,:label]
            treeDF[:,:load_time] = toppageurl[:,:load_time]

            fieldNames = [:urlpagegroup]
            treeDF[:label] = "End to End Time"
            drawTree(treeDF; titleCol=:label, fieldNames=fieldNames,resourceColors=true)
            removeNotBlocking(toppageurl)

            if (SP.devView)
                list = DataFrame()
                list[:,:urlpagegroup] = deepcopy(toppageurl[:,:urlpagegroup])
                #list[:,:Total] = deepcopy(toppageurl[:,:Total])
                list[:,:beacons] = deepcopy(toppageurl[:,:beacons])
                if (showPageUrl)
                    list[:,:urlgroup] = deepcopy(toppageurl[:,:urlgroup])
                end

                totalPercentTime = sum(list[:,:beacons]) * 0.010
                sort!(list,cols=[order(:beacons,rev=true)])

                titlestring = "This includes time which is overlapped."
                title2string = "Note: beacons field is used for load time and load_time field is used fractional load time"
                displayTitle(chart_title = "Total Time (K ms) For All Pages In Sample", chart_info = [titlestring,title2string,TV.timeString],showTimeStamp=false)

                #totalPercentTime = list[1:1,:beacons] * 0.001
                totalPercentTime = 1
                list = list[Bool[x > totalPercentTime[1] for x in list[:beacons]],:]
                if (showPageUrl)
                    #beautifyDF(names!(list[1:min(SP.treemapTableLines,end),:],
                    #    [Symbol("URL Page Group"),Symbol("Total Time"),Symbol("Redirect"),Symbol("Url Without Params")]))
                    beautifyDF(names!(list[1:min(SP.treemapTableLines,end),:],
                        [Symbol("URL Page Group"),Symbol("End to End Time"),Symbol("Url Without Params")]))
                else
                    #beautifyDF(names!(list[1:min(SP.treemapTableLines,end),:],
                    #    [Symbol("URL Page Group"),Symbol("Total Time"),Symbol("Redirect"),Symbol("Url Without Params")]))
                    beautifyDF(names!(list[1:min(SP.treemapTableLines,end),:],
                        [Symbol("URL Page Group"),Symbol("End to End Time")]))
                end
            end
        end
    catch y
        println("endToEndTreemap Exception ",y)
    end
end

function itemCountTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams,toppageurl::DataFrame;showPageUrl::Bool=false)
    try
        #Note: This one is not time based.  Do not use this one as a template for others

        #beacons on request_count
        toppageurl = names!(toppageurl[:,:],
        [Symbol("urlpagegroup"),Symbol("Start"),Symbol("Total"),Symbol("Redirect"),Symbol("Blocking"),Symbol("DNS"),
            Symbol("TCP"),Symbol("Request"),Symbol("Response"),Symbol("Gap"),Symbol("Critical"),Symbol("urlgroup"),
            Symbol("beacons"),Symbol("label"),Symbol("load_time"),Symbol("beacon_time")])

        currentTime = sum(toppageurl[:,:beacons])
        if currentTime > 0
            notBlocking(toppageurl);
            toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:urlpagegroup] = "Not Request Count"
            toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:Critical] = 0
            toppageurl[toppageurl[:,:urlgroup] .== "Not Blocking",:beacons] = 0

            treeDF = DataFrame()
            treeDF[:,:urlpagegroup] = toppageurl[:,:urlpagegroup]
            treeDF[:,:beacons] = toppageurl[:,:beacons]
            treeDF[:,:label] = toppageurl[:,:label]
            treeDF[:,:load_time] = toppageurl[:,:load_time]

            #display(treeDF[1:3,:])
            fieldNames = [:urlpagegroup]
            treeDF[:label] = "Request Count"
            drawTree(treeDF; titleCol=:label, fieldNames=fieldNames,resourceColors=true)
            removeNotBlocking(toppageurl)

            if (SP.devView)
                list = DataFrame()
                list[:,:urlpagegroup] = deepcopy(toppageurl[:,:urlpagegroup])
                list[:,:request_count] = deepcopy(toppageurl[:,:beacons])
                if (showPageUrl)
                    list[:,:urlgroup] = deepcopy(toppageurl[:,:urlgroup])
                end

                totalPercentTime = sum(list[:,:request_count]) * 0.010
                sort!(list,cols=[order(:request_count,rev=true)])
                displayTitle(chart_title = "Top Counts By Request Count",showTimeStamp=false)
                totalPercentTime = list[1:1,:request_count] * 0.1
                list = list[Bool[x > totalPercentTime[1] for x in list[:request_count]],:]
                if (showPageUrl)
                    beautifyDF(names!(list[1:min(SP.treemapTableLines,end),:],
                        [Symbol("URL Page Group"),Symbol("Request Count"),Symbol("Url Without Params")]))
                else
                    beautifyDF(names!(list[1:min(SP.treemapTableLines,end),:],
                        [Symbol("URL Page Group"),Symbol("Request Count")]))
                end
            end
        end
    catch y
        println("itemCountTreemap Exception ",y)
    end
end

function criticalPathFinalTreemap(TV::TimeVars,UP::UrlParams,SP::ShowParams,criticalPathDF::DataFrame)
    try

        if (SP.debugLevel > 8)
            standardChartTitle(TV,UP,SP,"Debug8: Critical Path DF")
            beautifyDF(criticalPathDF)
        end

        #beacons on Total
        cpDF = names!(criticalPathDF[:,:],
        [Symbol("urlgroup"),Symbol("average"),Symbol("maximum"),Symbol("counter"),Symbol("label")])

        #totalTime = sum(toppageurl[:,:Total])
        treeDF = DataFrame()
        treeDF[:,:urlgroup] = cpDF[:,:urlgroup]
        treeDF[:,:beacons] = cpDF[:,:average]
        treeDF[:,:label] = cpDF[:,:label]
        treeDF[:,:load_time] = cpDF[:,:counter]/100.0

        fieldNames = [:urlgroup]
        treeDF[:label] = "Critical Path Summary"
        drawTree(treeDF; titleCol=:label, fieldNames=fieldNames,resourceColors=true)
        #drawTreev2(treeDF,treeDF[:label],10)

        if (SP.devView)
            list = DataFrame()
            list[:,:urlgroup] = deepcopy(cpDF[:,:urlgroup])
            list[:,:beacons] = deepcopy(cpDF[:,:average])
            list[:,:maximum] = deepcopy(cpDF[:,:maximum])
            list[:,:counter] = deepcopy(cpDF[:,:counter])

            totalPercentTime = sum(list[:,:beacons]) * 0.010
            sort!(list,cols=[order(:beacons,rev=true)])

            standardChartTitle(TV,UP,SP,"Average Time (ms) For All Pages In Sample")

            totalPercentTime = 1
            list = list[Bool[x > totalPercentTime[1] for x in list[:beacons]],:]
            beautifyDF(names!(list[:,:],
                [Symbol("URL Page Group");Symbol("Average Time (ms)");Symbol("Maximum");Symbol("Occurances")]))
        end

    catch y
        println("criticalPathFinalTreemap Exception ",y)
    end
end
