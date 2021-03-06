function dailyWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    if isdefined(:gRunArray) && !gRunArray[1]
        wfShowPeakTable = false
    else
        wfShowPeakTable = true
    end

    if isdefined(:gRunArray)  && !gRunArray[2]
        wfShowSessionBeacons = false
    else
        wfShowSessionBeacons = true
    end

    if isdefined(:gRunArray)  && !gRunArray[3]
      wfShowChartLoad = false
    else
      wfShowChartLoad = true
    end

    if isdefined(:gRunArray)  && !gRunArray[4]
      wfShowTopUrls = false
    else
      wfShowTopUrls = true
    end

    if isdefined(:gRunArray)  && !gRunArray[5]
      wfShowBrowserTreemap = false
    else
      wfShowBrowserTreemap = true
    end

    if isdefined(:gRunArray)  && !gRunArray[6]
      wfShowCountryTreemap = false
    else
      wfShowCountryTreemap = true
    end

    if isdefined(:gRunArray)  && !gRunArray[7]
      wfShowDeviceTypeTreemap = false
    else
      wfShowDeviceTypeTreemap = true
    end

    if isdefined(:gRunArray)  && !gRunArray[8]
      wfShowPageGroupTreemp = false
    else
      wfShowPageGroupTreemp = true
    end

    if isdefined(:gRunArray)  && !gRunArray[9]
      wfShowGroupQuartiles = false
    else
      wfShowGroupQuartiles = true
    end

    if isdefined(:gRunArray)  && !gRunArray[10]
      wfShowActvitityImpact = false
    else
      wfShowActvitityImpact = true
    end

    if isdefined(:gRunArray)  && !gRunArray[11]
      wfShowAggSession = false
    else
      wfShowAggSession = true
    end

  wfClearViews = true

# todo SQLFILTER Everywhere and use the view tables where possible

  openingTitle(TV,UP,SP)

  beaconFilter = SQLFilter[
      ilike("pagegroupname",UP.pageGroup),
      ilike("paramsu",UP.urlRegEx),
      ilike("devicetypename",UP.deviceType),
      ilike("operatingsystemname",UP.agentOs)
      ]

  try
    if (wfShowPeakTable)
        showPeakTable(TV,UP,SP;showStartTime30=true,tableRange="Daily ")
    end
  catch y
    println("showPeakTable Exception")
  end

  try
    if (wfShowSessionBeacons)
          chartConcurrentSessionsAndBeaconsOverTime(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
    end
  catch y
      println("chartConcurrentSessionsAndBeaconsOverTime Exception ",y)
  end

  try
      if (wfShowChartLoad)
          chartLoadTimes(TV.startTimeUTC, TV.endTimeUTC, TV.datePart, filters=beaconFilter)
      end
  catch y
      println("chartLoadTimes Exception ",y)
  end

  if (wfShowTopUrls)
      topUrlTableByTime(TV,UP,SP)   # use UP.pageGroup = "%" for no group
  end

  #setTable(UP.bt View)

  try
      if (wfShowBrowserTreemap)
          browserFamilyTreemap(TV,UP,SP)
      end
  catch y
      println("browserFamilyTreemap Exception ",y)
  end

  try
      if (wfShowCountryTreemap)
          countryTreemap(TV,UP,SP)
      end
  catch y
      println("countryTreemap Exception ",y)
  end

  try
      if (wfShowDeviceTypeTreemap) && UP.deviceType == "%"
          deviceTypeTreemap(TV,UP,SP)
      end
  catch y
    println("deviceTypeTreemap Exception ",y)
  end

  if (wfShowPageGroupTreemp) && UP.pageGroup == "%"
      pageGroupTreemap(TV,UP,SP)
  end

  if (wfShowGroupQuartiles) && UP.pageGroup == "%"
      pageGroupQuartiles(TV,UP,SP);
  end

  try
      if (wfShowActvitityImpact) && UP.pageGroup == "%"
          chartActivityImpactByPageGroup(TV.start_time, TV.endTime;n=10);
      end
  catch y
    println("chartActivityImpactByPageGroup Exception ",y)
  end

  try
      if (wfShowAggSession)
          perfsessionLength = getAggregateSessionLengthAndDurationByLoadTime(TV.startTimeUTC, TV.endTimeUTC; filters=beaconFilter);

          c3 = drawC3Viz(perfsessionLength; columnNames=[:load_time,:total,:avg_length], axisLabels=["Session Load Times","Completed Sessions", "Average Session Length"],dataNames=["Completed Sessions",
              "Average Session Length", "Average Session Duration"], mPulseWidget=false, chart_title="Session Load for All Pages", y2Data=["data2"], vizTypes=["area","line"]);
      end
  catch y
      println("getAggregateSessionLengthAndDurationByLoadTime Exception ",y)
  end

end

function dumpDataFieldsWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    urlCountPrintTable(TV,UP,SP)

    agentCountPrintTable(TV,UP,SP)

end

function studyRangeOfStatsWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    if isdefined(:gRunArray) && !gRunArray[1]
        wfPageGroupGraph = false
    else
        wfPageGroupGraph = true
    end

    if isdefined(:gRunArray) && !gRunArray[2]
        wfStatsGraphMedian = false
    else
        wfStatsGraphMedian = true
    end

    if isdefined(:gRunArray) && !gRunArray[3]
        wfStatsGraphQ = false
    else
        wfStatsGraphQ = true
    end

    if isdefined(:gRunArray) && !gRunArray[4]
        wfStatsGraphKurt = false
    else
        wfStatsGraphKurt = true
    end

    if isdefined(:gRunArray) && !gRunArray[5]
        wfStatsGraphSkew = false
    else
        wfStatsGraphSkew = true
    end

    if isdefined(:gRunArray) && !gRunArray[6]
        wfStatsGraphEntropy = false
    else
        wfStatsGraphEntropy = true
    end

    if isdefined(:gRunArray) && !gRunArray[7]
        wfStatsGraphModes = false
    else
        wfStatsGraphModes = true
    end

    wfClearViews = true

    if isdefined(:explain) && explain
        explainStudyRangeOfStats()
        return
    end

    openingTitle(TV,UP,SP)

    if wfPageGroupGraph
        rawTimeDF = fetchGraph7Stats(TV,UP,SP)
        #beautifyDF(rawTimeDF[1:min(3,end),:])
        drawC3VizConverter(UP,rawTimeDF;graphType=7)
    end

    if (wfStatsGraphQ ||
        wfStatsGraphKurt ||
        wfStatsGraphSkew ||
        wfStatsGraphModes ||
        wfStatsGraphMedian ||
        wfStatsGraphEntropy
       )
        AllStatsDF = createAllStatsDF(TV,UP,SP)
    end

    if wfStatsGraphMedian
        drawC3VizConverter(UP,AllStatsDF;graphType=1)
    end

    if wfStatsGraphQ
        drawC3VizConverter(UP,AllStatsDF;graphType=2)
    end

    if wfStatsGraphKurt
        drawC3VizConverter(UP,AllStatsDF;graphType=3)
    end

    if wfStatsGraphSkew
        drawC3VizConverter(UP,AllStatsDF;graphType=4)
    end

    if wfStatsGraphEntropy
        drawC3VizConverter(UP,AllStatsDF;graphType=5)
    end

    if wfStatsGraphModes
        drawC3VizConverter(UP,AllStatsDF;graphType=6)
    end

end

function dumpDataFieldsV2Workflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    openingTitle(TV,UP,SP)

    urlCountPrintTable(TV,UP,SP)

    urlParamsUCountPrintTable(TV,UP,SP)

    paramsUCountPrintTable(TV,UP,SP)

end

function findAPageViewSpikeWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    openingTitle(TV,UP,SP)

    beaconFilter = SQLFilter[
        ilike("pagegroupname",UP.pageGroup),
        ilike("paramsu",UP.urlRegEx),
        ilike("devicetypename",UP.deviceType),
        ilike("operatingsystemname",UP.agentOs)
        ]

    try
        chartConcurrentSessionsAndBeaconsOverTime(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
    catch y
        println("chartconcurrentsessionsBeacons Exception ",y)
    end

    try
        chartLoadTimes(TV.startTimeUTC, TV.endTimeUTC, TV.datePart, filters=beaconFilter)
    catch y
        println("chartloadTime Exception ",y)
    end

    #setTable(UP.bt View)

    topUrlTable(TV,UP,SP)

    showPeakTable(TV,UP,SP)

    beaconViewStats(TV,UP,SP)

end

function pageGroupDetailsWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams,mobileView::ASCIIString,desktopView::ASCIIString)

    openingTitle(TV,UP,SP)

    #pageGroupDetailsCreateView(TV,UP,SP,mobileView,desktopView)

    statsDF = beaconViewStats(TV,UP,SP)
    if !isdefined(:statsDF)
        println("No data returned from beaconViewStats")
        return
    end

    medianThreshold = statsDF[1:1,:median][1]

    showPeakTable(TV,UP,SP;showStartTime30=false,tableRange="Sample Set ")

    concurrentSessionsPGD(TV,UP,SP,mobileView,desktopView)

    loadTimesPGD(TV,UP,SP,mobileView,desktopView)

    topUrlTable(TV,UP,SP)

    try
        chartPercentageOfBeaconsBelowThresholdStackedBar(TV.startTimeUTC, TV.endTimeUTC, TV.datePart; threshold = medianThreshold)
    catch y
        println("chartPercentageOfBeaconsBelowThresholdStackedBar exception ",y)
    end

    try
        perfsessionLength = getAggregateSessionLengthAndDurationByLoadTime(TV.startTimeUTC, TV.endTimeUTC);

        c3 = drawC3Viz(perfsessionLength; columnNames=[:load_time,:total,:avg_length], axisLabels=["Session Load Times","Completed Sessions", "Average Session Length"],
             dataNames=["Completed Sessions","Average Session Length", "Average Session Duration"], mPulseWidget=false,
             chart_title="Session Stats for $(UP.pageGroup) Page Group", y2Data=["data2"], vizTypes=["area","line"]);
    catch y
        println("sessionLoadPGD Exception ",y)
    end

    loadTimesParamsUPGD(TV,UP)

    try
        chartMedianLoadTimesByDimension(TV.startTimeUTC, TV.endTimeUTC,dimension=:countrycode,minPercentage=0.6)
        chartMedianLoadTimesByDimension(TV.startTimeUTC, TV.endTimeUTC; dimension=:devicetypename, n=15, orderBy="frontend", minPercentage=0.001)
        printDF = getMedianLoadTimesByDimension(TV.startTimeUTC, TV.endTimeUTC; dimension=:devicetypename, n=15, orderBy="frontend", minPercentage=0.001)
        beautifyDF(printDF)
    catch y
        println("medianTimesPGD Exception ",y)
    end


    customRefPGD(TV,UP,SP)

    standardReferrals(TV,UP,SP)

    try
        chartMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:http_referrer,minPercentage=0.5)
        chartMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:params_r,minPercentage=0.5)
        chartTopN(TV.startTimeUTC, TV.endTimeUTC; variable=:landingPages)
    catch y
        println("cell chartSlowestUrls Exception ",y)
    end

    treemapsPGD(TV,UP,SP)

    datePartQuartiles(TV)

    try
        result10 = getAllPaths(TV.startTimeUTC, TV.endTimeUTC; n=60, f=getAbandonPaths);
        drawSunburst(result10[1]; totalPaths=result10[3])
    catch y
        println("sunburst Exception ",y)
    end

    # General Context for All

    setTable(UP.beaconTable)

    pageGroupTreemap(TV,UP,SP)

    chartLoadTimeMediansAndBounceRatesByPageGroup(TV.startTimeUTC,TV.endTimeUTC)

    pageGroupQuartiles(TV,UP,SP)

    chartActivityImpactByPageGroup(TV.startTimeUTC, TV.endTimeUTC;n=UP.limitRows)

    ;
end

function individualStreamlineWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

  openingTitle(TV,UP,SP)

  if UP.useJson
      urlListDF = newPagesList(UP,SP)
      listToUseDV = urlListDF[:urlgroup] * "%"
      finalListToUseDV = cleanupTopUrlTable(listToUseDV)
  else
      urlListDF = returnMatchingUrlTableV2(TV,UP)
  end

  if (SP.debugLevel > 8)
      beautifyDF(urlListDF[1:min(10,end),:])
  end

  if !UP.useJson
      # Clean up the list before using
      newListDF = urlListDF[Bool[x > UP.samplesMin for x in urlListDF[:cnt]],:]
      topUrlListDV = newListDF[:urlgroup]
      finalListToUseDV = cleanupTopUrlTable(topUrlListDV)

      if (SP.debugLevel > 4)
          println("Started with ",size(urlListDF,1), " Trimmed down to ",size(newListDF,1), " due to $(UP.samplesMin) limit")
          println("Final DV size is ",size(finalListToUseDV,1))
      end

  end

  if (SP.debugLevel > 4)
      for item in finalListToUseDV
          println(item)
      end
  end

  finalUrlTableOutput(TV,UP,SP,finalListToUseDV)

end

function aemLargeImagesWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    joinTables = DataFrame()
    joinTables = gatherSizeDataToDF(UP,SP)
    ;

    joinTableSummary = DataFrame()
    joinTableSummary = createJoinTableSummary(SP,joinTableSummary,joinTables)
    ;

    i = 0
    for row in eachrow(joinTableSummary)
        i += 1
        joinTablesDetailsPrintTable(TV,UP,SP,joinTableSummary,i)
        statsDetailsPrint(TV,UP,SP,joinTableSummary,i)
        if (i >= SP.showLines)
            break;
        end
    end
    ;

end

function urlDetailsWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

  #Turn sections on / off to debug
  wfShowSessions = true
  wfShowMedLoadTimes = true # broken by me
  wfShowTopPages = true
  wfShowTopUrlPages = true
  wfShowChartTopPage = true # was false # broken - need ticket
  wfShowMedLoadUrl = true
  wfShowChartCacheHitRatio = true # was false # broken - need ticket
  wfShowChartTopPageResources = true
  wfShowChartResResponse = true # was false # broken - need ticket
  wfShowChartResUrlResponse = true # was false # broken like the one above
  wfShowPercentBelow = true # was false # broken - need ticket
  wfShowBounceByUrl = true
  wfShowResResponseTime = true # was false # broken - need ticket
  wfShowAggSessionLength = true
  wfShowMedLoadByDevice = true
  wfShowMedLoadByGeo = true
  wfShowCustomReferrers = true
  wfShowReferrers = true
  wfShowMedLoadByReferrers = true
  wfShowTreemaps = true
  wfShowSunburst = true

  wfClearViews = true

  openingTitle(TV,UP,SP)

  beaconFilter = SQLFilter[
      ilike("pagegroupname",UP.pageGroup),
      ilike("paramsu",UP.urlRegEx),
      ilike("devicetypename",UP.deviceType),
      ilike("operatingsystemname",UP.agentOs)
      ]


  if (wfShowSessions)
    #displayTitle(chart_title = "Concurrent Sessions and Beacons for $(UP.pageGroup)", chart_info = [TV.timeString])
    try
        #Function title includes UTC in label
        chartConcurrentSessionsAndBeaconsOverTime(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
    catch y
        println("urlDetailsWorkflow-wfShowSessions Excpt: ",y)
    end
  end

  if (wfShowMedLoadTimes)
      try
          beaconFilter = SQLFilter[
              ilike("pagegroupname",UP.pageGroup)
              ]
          println("beaconFilter ",beaconFilter)
          chartLoadTimes(TV.startTimeUTC, TV.endTimeUTC, TV.datePart, filters=beaconFilter)
      catch y
          println("urlDetailsWorkflow-wfShowMedLoadTimes Excpt: ",y)
      end
  end

  if (wfShowTopPages)
      try
          countUrlgroupPrintTable(TV,UP,SP)
      catch y
          println("urlDetailsWorkflow-wfShowTopPages Excpt: ",y)
      end
  end

  if (wfShowTopUrlPages)
    try
        countParamUBtViewPrintTable(TV,UP,SP)
    catch y
        println("urlDetailsWorkflow-wfShowTopUrlPages Excpt: ",y)
    end
  end

  # Currently broken - need ticket to Soasta
  if (wfShowChartTopPage)
    #fail thresholdValues = [1000, 10000, 100000]
    #fail chartRes = chartResponseTimesVsTargets(start_time, endTime, datePart, thresholdValues)
    try
        chartRes = chartTopPageResourcesSummary(TV.startTimeUTC, TV.endTimeUTC)
        display(chartRes[1:20,:])
    catch y
        println("chartTop LocalTable Exception ",y)
    end

  end

  if (wfShowMedLoadUrl)
    try
        chartMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:url,minPercentage=0.1)
        chartMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:paramsu,minPercentage=0.1)
    catch y
        println("urlDetailsWorkflow-wfShowMedLoadUrl Excpt: ",y)
    end
  end

  # Known bad - need ticket
  if (wfShowChartCacheHitRatio)
    try
        chartRes = chartCacheHitRatioByUrl(TV.startTimeUTC, TV.endTimeUTC)
        display(chartRes)
    catch y
        println("urlDetailsWorkflow-wfShowChartCacheHitRatio Excpt: ",y)
    end
  end

  # Need to test
  if (wfShowChartTopPageResources)
    try
        #chartTopPageResourcesSummary(start_time, endTime)
        #chartTopPageResourcesSummary(start_time, endTime, datepart = datePart)
        #display(chartRes)
    catch y
        println("urlDetailsWorkflow-wfShowChartTopPageResources Excpt: ",y)
    end
  end

  # known bad - need ticket
  if (wfShowChartResResponse)
    try
        chartRes = chartResourceResponseTimeDistribution(TV.startTimeUTC, TV.endTimeUTC,url=UP.urlFull)
        display(chartRes)
    catch y
        println("urlDetailsWorkflow-wfShowChartResResponse Excpt: ",y)
    end
  end

  if (wfShowChartResUrlResponse)
    try
        chartRes = chartResourceResponseTimeDistribution(TV.startTimeUTC, TV.endTimeUTC)
        display(chartRes)
    catch y
        println("urlDetailsWorkflow-wfShowChartResUrlResponse Excpt: ",y)
    end
  end

  # known bad - need ticket
  if (wfShowPercentBelow)
    try
        chartPercentageOfBeaconsBelowThresholdStackedBar(TV.startTimeUTC, TV.endTimeUTC, :hour)
    catch y
        println("urlDetailsWorkflow-wfShowPercentBelow Excpt: ",y)
    end
  end

  if (wfShowBounceByUrl)
    try
        #chartBouncesVsLoadTimes(TV.startTimeUTC, TV.endTimeUTC, url=UP.urlFull)
        chartBouncesVsLoadTimes(TV.startTimeUTC, TV.endTimeUTC)
        #chartBouncesVsLoadTimes(start_time, endTime)
    catch y
        println("urlDetailsWorkflow-wfShowBounceByUrl Excpt: ",y)
    end
  end

  # known bad - need ticket
  if (wfShowResResponseTime)
    try
        responseDist = getResourceResponseTimeDistribution(TV.startTimeUTC,TV.endTimeUTC, n=15, url=UP.urlFull)
        display(responseDist)
    catch y
        println("urlDetailsWorkflow-wfShowResResponseTime Excpt: ",y)
    end
  end

  if (wfShowAggSessionLength)
        try
            perfsessionLength = getAggregateSessionLengthAndDurationByLoadTime(TV.startTimeUTC, TV.endTimeUTC; filters=beaconFilter)
            c3 = drawC3Viz(perfsessionLength; columnNames=[:load_time,:total,:avg_length], axisLabels=["Page Load Times","Completed Sessions", "Average Session Length"],dataNames=["Completed Sessions",
                "Average Session Length", "Average Session Duration"], mPulseWidget=false, chart_title="Top URL Page Load for $(UP.pageGroup) Page Group", y2Data=["data2"], vizTypes=["area","line"])
        catch y
            println("urlDetailsWorkflow-wfShowAggSessionLength Excpt: ",y)
        end
  end

  if (wfShowMedLoadByDevice)
    try
        chartMedianLoadTimesByDimension(TV.startTimeUTC, TV.endTimeUTC; dimension=:devicetypename, n=15, orderBy="frontend", minPercentage=0.001)
    catch y
        println("urlDetailsWorkflow-wfShowMedLoadByDevice Excpt: ",y)
    end
  end

  if (wfShowMedLoadByGeo)
    try
        chartMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:countrycode,minPercentage=2.5,n=10)
    catch y
        println("urlDetailsWorkflow-wfShowMedLoadByGeo Excpt: ",y)
    end
  end

  if (wfShowCustomReferrers)
    try
        customRefPGD(TV,UP,SP)
    catch y
        println("urlDetailsWorkflow-wfShowCustomReferrers Excpt: ",y)
    end
  end

  if (wfShowReferrers)
      try
          standardReferrals(TV,UP,SP)
      catch y
          println("urlDetailsWorkflow-wfShowReferrers Excpt: ",y)
      end
  end

  if (wfShowMedLoadByReferrers)
    try
        chartMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:http_referrer,minPercentage=0.5)
        t1 = getMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:http_referrer,minPercentage=0.5)
        display(t1)

        chartMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:params_r,minPercentage=0.5)
        t2 = getMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:params_r,minPercentage=0.5)
        display(t2)
    catch y
        println("urlDetailsWorkflow-wfShowMedLoadByReferrers Excpt: ",y)
    end
  end

  if (wfShowTreemaps)
    try
        treemapsPGD(TV,UP,SP)
    catch y
        println("urlDetailsWorkflow-wfShowTreemaps Excpt: ",y)
    end
  end

  if (wfShowSunburst)
    try
        result10 = getAllPaths(TV.startTimeUTC, TV.endTimeUTC; n=30, f=getAbandonPaths,useurls=true);
        drawSunburst(result10[1]; totalPaths=result10[3])
    catch y
        println("urlDetailsWorkflow-wfShowSunburst Excpt: ",y)
    end
  end

end

function findATimeSpikeWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

  #Turn sections on / off to debug
  wfShowLongTimes = true
  wfShowBelowThreshold = false # bad output - need ticket
  wfShowLoadTimes = true
  wfShowDurationByDate = true
  wfShowTopUrls = true
  wfShowSessionsAndBeacons = true
  wfShowLongTimes = true

  wfClearViews = true

  openingTitle(TV,UP,SP)

  statsDF = DataFrame()
  localStats2 = DataFrame()

  statsDF = beaconViewStats(TV,UP,SP)
  localStats2 = localStatsFATS(TV,UP,statsDF)

  if (wfShowLongTimes)
    longTimesFATS(TV,UP,localStats2)
  end

  beaconFilter = SQLFilter[
      ilike("pagegroupname",UP.pageGroup),
      ilike("paramsu",UP.urlRegEx),
      ilike("devicetypename",UP.deviceType),
      ilike("operatingsystemname",UP.agentOs)
      ]


  if (wfShowBelowThreshold)
    chartPercentageOfBeaconsBelowThresholdStackedBar(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
  end

  if (wfShowLoadTimes)
    #displayTitle(chart_title = "Median Load Times for $(UP.pageGroup)", chart_info = [TV.timeString])
    chartLoadTimes(TV.startTimeUTC, TV.endTimeUTC, TV.datePart, filters=beaconFilter)
  end

  if (wfShowDurationByDate)
      datePartQuartiles(TV)
  end

  if (wfShowTopUrls)
    chartTopURLsByLoadTime(TV.startTimeUTC, TV.endTimeUTC)
  end

  if (wfShowSessionsAndBeacons)
    #displayTitle(chart_title = "Concurrent Sessions and Beacons for $(UP.pageGroup)", chart_info = [TV.timeString])
    chartConcurrentSessionsAndBeaconsOverTime(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
  end

  if (wfShowLongTimes)
    graphLongTimesFATS(localStats2)
  end

end

function aemLargeResourcesWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams,minimumEncoded::Int64)

    openingTitle(TV,UP,SP)

    #Turn sections on / off to debug
    wfShowBigPagesByFileType = true
    wfShowLeftOvers = true
    wfShowLeftOversDetails = true
    wfClearViews = true

    if (wfShowBigPagesByFileType)
        bigPagesSizePrintTable(TV,UP,SP,"%jpg";minEncoded=minimumEncoded)
        bigPagesSizePrintTable(TV,UP,SP,"%png";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%svg";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%mp3";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%mp4";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%gif";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%wav";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%jog";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%js";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%js?%";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%css";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%ttf";minEncoded=minimumEncoded);
        bigPagesSizePrintTable(TV,UP,SP,"%woff";minEncoded=minimumEncoded);
    end

    if (wfShowLeftOvers)
        try
            lookForLeftOversPrintTable(UP,SP)
        catch y
            println("lookForLeftOversPrintTable Exception ",y)
        end
    end

    if (wfShowLeftOversDetails)
        try
            lookForLeftOversDetailsPrintTable(UP,SP)
        catch y
            println("lookForLeftOversPrintTable Exception ",y)
        end
    end

end

function findAnyResourceWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

  #Turn sections on / off to debug
  wfShowResourcesByParamsU = true
  wfShowResourcesByUrl = true
  wfShowResourcesByUrls = true
  wfShowResourcesStats = true
  wfShowResourcesAllFields = false

  wfClearViews = true

  openingTitle(TV,UP,SP)

  if (wfShowResourcesByUrl)
      displayMatchingResourcesByUrlRtPrintTable(TV,UP,SP)
  end

  if (wfShowResourcesByParamsU)
      displayMatchingResourcesByParentUrlPrintTable(TV,UP,SP)
  end

  if (wfShowResourcesByUrls)
      displayMatchingResourcesByUrlBtvRtPrintTables(TV,UP,SP)
  end

  if (wfShowResourcesStats)
      displayMatchingResourcesStatsPrintTable(TV,UP,SP)
  end

  if (wfShowResourcesAllFields)
      displayMatchingResourcesAllFieldsPrintTable(TV,UP,SP)
  end

end

function findSingleResourceWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

  #Turn sections on / off to debug
  wfShowResourcesByParamsU = true
  wfShowResourcesByUrl = true
  wfShowResourcesByUrls = true
  wfShowResourcesStats = true
  wfShowResourcesAllFields = false

  wfClearViews = true

  openingTitle(TV,UP,SP)

  if (wfShowResourcesByUrls)
      displayMatchingResourcesByUrlBtvRtPrintTables(TV,UP,SP)
  end

end

function showRequestsForLargePagesWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

  #Turn sections on / off to debug
  wfShowBigPage2 = true
  wfShowBigPage3 = true
  wfShowBigPage4 = true
  wfShowBigPage5 = true
  wfShowBigPage6 = true

  wfClearViews = true

  minSizeBytes = bigPages1SRFLP(TV,UP,SP)

  if (wfShowBigPage2)
      bigPages2PrintTable(TV,UP,SP,minSizeBytes)
  end

  if (wfShowBigPage3)
      bigPages3PrintTable(TV,UP,SP,minSizeBytes)
  end

  if (wfShowBigPage4)
      bigPages4PrintTable(TV,UP,SP,minSizeBytes)
  end

  if (wfShowBigPage5)
      bigPages5PrintTable(TV,UP,SP,minSizeBytes)
  end

  if (wfShowBigPage6)
      bigPages6PrintTable(TV,UP,SP,minSizeBytes)
  end

end

function determineBeaconsGroupingWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    openingTitle(TV,UP,SP)

    short_results = getLatestResults(hours=0, minutes=5, table_name=UP.beaconTable)
    size(short_results)

    groups, group_summary = groupResults(short_results, dims=2, showProgress=true)
    beautifyDF(group_summary)

    gbg = getBestGrouping(short_results, group_summary)
    beautifyDF(gbg)

    soasta_results = getLatestResults(table_name=UP.beaconTable, hours=4);
    size(soasta_results)

    groups, group_summary = groupResults(soasta_results, dims=2, showProgress=true);
    beautifyDF(group_summary)

    gbg = getBestGrouping(soasta_results, group_summary)
    beautifyDF(gbg)
end

function beaconAndRtCountsWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    bt = UP.beaconTable
    rt = UP.resourceTable

    if (SP.reportLevel > 9)
        bc = getBeaconCount();
        allBeacons = getBeaconsFirstAndLast();
        #bcType = getBeaconCountByType();
        beautifyDF(names!(bc[:,:],[Symbol("Beacon Count")]))
        beautifyDF(allBeacons)
        #beautifyDF(names!(bcType[:,:],[Symbol("Beacon Type"),Symbol("Beacon Count")]))
    end

    UP.pageGroup = "News Article"
    UP.limitRows = 10
    t1DF = defaultLimitedBeaconsToDF(TV,UP,SP)
    standardChartTitle(TV,UP,SP,"$(UP.pageGroup) Page View Dump")
    beautifyDF(t1DF)

    t2DF = errorBeaconsToDF(TV,UP,SP)
    if (size(t2DF,1) > 0)
        standardChartTitle(TV,UP,SP,"Error Beacon Dump")
        beautifyDF(t2DF)
    end

    rtcnt = select("""select count(*) from $rt""");
    maxRt = select("""select max(timestamp) from $rt""");
    minRt = select("""select min(timestamp) from $rt""");

    minStr = msToDateTime(minRt[1,:min]);
    maxStr = msToDateTime(maxRt[1,:max]);

    printDf = DataFrame();
    printDf[:minStr] = minStr;
    printDf[:maxStr] = maxStr;

    standardChartTitle(TV,UP,SP,"Resource Information")
    beautifyDF(names!(rtcnt[:,:],[Symbol("Resource Timing Count")]))
    beautifyDF(names!(printDf[:,:],[Symbol("First RT"),Symbol("Last RT")]))
    ;

end

function weeklyCTOReportWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    openingTitle(TV,UP,SP)

    try
        chartConcurrentSessionsAndBeaconsOverTime(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
    catch y
        println("chartConcurrentSessionsAndBeaconsOverTime Exception ",y)
    end

    try
        chartLoadTimes(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
    catch y
        println("chartLoadTimes Exception ",y)
    end

    showPeakTable(TV,UP,SP;showStartTime30=true)

    topUrlTableByTime(TV,UP,SP)

    pageGroupQuartiles(TV,UP,SP);

    chartActivityImpactByPageGroup(TV.startTimeUTC, TV.endTimeUTC;n=10);

    try
        pageGroupTreemap(TV,UP,SP)
    catch y
        println("pageGroupTreemap Exception ",y)
    end

    try
        deviceTypeTreemap(TV,UP,SP)
    catch y
        println("deviceTypeTreemap Exception ",y)
    end

    try
        browserFamilyTreemap(TV,UP,SP)
    catch y
        println("browserFamilyTreemap Exception ",y)
    end

    try
        countryTreemap(TV,UP,SP)
    catch y
        println("chartConcurSessions Exception ",y)
    end
end

function pageGroupAnimationWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    openingTitle(TV,UP,SP)

    # Some routines use the unload events, some do not.  First count is all beacons such as page view and unload
    # where beacontypename = 'page view'
    # t1DF = select("""SELECT count(*) FROM $bt v""")

    retailer_results = getLatestResults(hours=10, minutes=0, table_name="$(UP.beaconTable)")
    size(retailer_results)

    # drop some of the fields to make the output easier to read

    #delete!(retailer_results,[:regioncode,:geo_city,:geo_org,:useragentversion,:operatingsystemversion,:operatingsystemname,:user_agent_model,:referrer])
    delete!(retailer_results,[:regioncode,:geo_city,:geo_org,:useragentversion,:operatingsystemversion,:operatingsystemname,:user_agent_model])

    doit(retailer_results, showDimensionViz=true, showProgress=true);

end

function largeResourcesForImageMgrWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    largeResourceFileTypePrint(TV,UP,SP,"%jpg")
    largeResourceFileTypePrint(TV,UP,SP,"%png")
    largeResourceFileTypePrint(TV,UP,SP,"%jpeg")
    largeResourceFileTypePrint(TV,UP,SP,"%gif")
    largeResourceFileTypePrint(TV,UP,SP,"%imviewer")
    largeResourceFileTypePrint(TV,UP,SP,"%svg")
    largeResourceFileTypePrint(TV,UP,SP,"%jpeg")

    ;

end

function resourcesDetailsWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    saveSpShowLines = SP.showLines
    SP.showLines = 3
    resourceMatched(TV,UP,SP)
    resourceSummaryAllFields(TV,UP,SP)

    SP.showLines = saveSpShowLines
    resourceSummary(TV,UP,SP)

    minimumEncoded = 0
    resourceSize(TV,UP,SP;minEncoded=minimumEncoded)

    resourceScreenPrintTable(TV,UP,SP)

    resourceSummaryDomainUrl(TV,UP,SP)

    resourceTime1(TV,UP,SP)

    resourceTime2(TV,UP,SP)

    resourceTime3(TV,UP,SP)

end

function findAnyAggResourcesWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    UP.resRegEx = "%www.nationalgeographic.com%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%news.nationalgeographic.com%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%adservice.google%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%googlesyndication.com%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%yahoo.com%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%innovid.com%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%moatads.com%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%fls.doubleclick%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%unrulymedia.com%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%googleapis.com%"   # Google Doubleclick related
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%2mdn.net%"   # Google Doubleclick related
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%doubleclick.net%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%monetate_off%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%monetate.net%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%MonetateTests%"
    findAnyResourceWorkflow(TV,UP,SP)
    ;

end

function findAdsResourcesWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    UP.resRegEx = "%v1.9.3%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%v1.9.5%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%cdn1.spotible.com%"
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%fng-ads.fox.com/fw_ads%" # Oct 19 freewheel ads
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%player.foxdcg.com/ngp-freewheel%" # Oct 19 freewheel ads
    findAnyResourceWorkflow(TV,UP,SP)

    UP.resRegEx = "%pr-bh.ybp.yahoo.com%"
    findAnyResourceWorkflow(TV,UP,SP)
    ;

end

function statsAndTreemapsWorkflow(TV::TimeVars,UP::UrlParams,SP::ShowParams)

    localTableDF = statsAndTreemapsData(TV,UP,SP)

    if nrow(localTableDF) == 0
        displayTitle(chart_title = "$(UP.urlFull) for $(UP.deviceType) was not found during $(TV.timeString)",showTimeStamp=false)
        return
    end

    if (SP.debugLevel > 8)
        println("Individual part 1 done with ", nrow(localTableDF), " records")
    end

    statsDF = timeBeaconStats(TV,UP,SP,localTableDF;showAdditional=true,showShort=false,useQuartile=true)

    topPageUrlDF = statsAndTreemapsFinalData(TV,UP,SP,statsDF)

    statsAndTreemapsOutput(TV,UP,SP,topPageUrlDF)

end
