# From Individual-Streamline-Body

function individualStreamlineMain(TV::TimeVars,UP::UrlParams,SP::ShowParams,WellKnownHost::Dict,WellKnownPath::Dict,
  deviceType::ASCIIString,rangeLowerMs::Float64,rangeUpperMs::Float64)
  try

      #customer = "Nat Geo"
      #reportLevel = 10 # 1 for min output, 5 medium output, 10 all output
      UP.deviceType = deviceType
      UP.timeLowerMs = rangeLowerMs
      UP.timeUpperMs = rangeUpperMs

      localTableDF = DataFrame()
      localTableRtDF = DataFrame()
      statsDF = DataFrame()

      localTableDF = estimateBeacons(TV,UP,SP)
      recordsFound = nrow(localTableDF)

      #println("part 1 done with ",recordsFound, " records")
      if recordsFound == 0
          displayTitle(chart_title = "$(UP.urlFull) for $(UP.deviceType) was not found during $(TV.timeString)",showTimeStamp=false)
          #println("$(fullUrl) for $(deviceType) was not found during $(tv.timeString)")
          return
      end

      # Stats on the data
      statsDF = beaconStats(UP,SP;showAdditional=true)
      rangeLowerMs = statsDF[1:1,:median][1] * 0.95
      rangeUpperMs = statsDF[1:1,:median][1] * 1.05

      #println("part 2 done")
      localTableRtDF = getResourcesForBeacon(TV,UP)
      recordsFound = nrow(localTableRtDF)

      #println("part 1 done with ",recordsFound, " records")
      if recordsFound == 0
          displayTitle(chart_title = "$(UP.urlFull) for $(UP.deviceType) has no resource matches during this time",showTimeStamp=false)
          #println("$(fullUrl) for $(deviceType) was not found during $(tv.timeString)")
          return
      end

      #println("part 3 done")
      showAvailableSessionsStreamline(TV,UP,SP,WellKnownHost,WellKnownPath,localTableDF,localTableRtDF)
      #println("part 4 done")


  catch y
      println("Individual Streamline Main Exception ",y)
  end
end

# From Individual-Streamline-Body

function individualStreamlineTableV2(UP::UrlParams,SP::ShowParams;repeat::Int64=1)
  try

      # Get Started

      localTableDF = DataFrame()
      localTableRtDF = DataFrame()
      statsDF = DataFrame()

      localTableDF = estimateFullBeaconsV2(TV,UP,SP)
      recordsFound = nrow(localTableDF)

      if (SP.debugLevel > 0)
          println("part 1 done with ",recordsFound, " records")
          if recordsFound == 0
              displayTitle(chart_title = "$(UP.urlFull) for $(UP.deviceType) was not found during $(TV.timeString)",showTimeStamp=false)
          end
      end

      if recordsFound == 0
          row = DataFrame(url=UP.urlFull,beacon_time=0,request_count=0,encoded_size=0,samples=0)
          return row
      end

      # Stats on the data
      row = beaconStatsRow(UP,SP,localTableDF)

      # record the latest record and save to print outside the final loop
      return row

  catch y
      println("Individual Streamline Table Exception ",y)
  end
end

# From Individual-Streamline-Body

function estimateFullBeaconsV2(TV::TimeVars,UP::UrlParams,SP::ShowParams)

  try
      table = UP.beaconTable
      tableRt = UP.resourceTable

      if (UP.usePageLoad)
          localTableDF = query("""\
          select
              'None' as urlpagegroup,
              avg($tableRt.start_time),
              avg(CASE WHEN ($tableRt.response_last_byte = 0) THEN (0) ELSE ($tableRt.response_last_byte-$tableRt.start_time) END) as total,
              avg($tableRt.redirect_end-$tableRt.redirect_start) as redirect,
              avg(CASE WHEN ($tableRt.dns_start = 0 and $tableRt.request_start = 0) THEN (0) WHEN ($tableRt.dns_start = 0) THEN ($tableRt.request_start-$tableRt.fetch_start) ELSE ($tableRt.dns_start-$tableRt.fetch_start) END) as blocking,
              avg($tableRt.dns_end-$tableRt.dns_start) as dns,
              avg($tableRt.tcp_connection_end-$tableRt.tcp_connection_start) as tcp,
              avg($tableRt.response_first_byte-$tableRt.request_start) as request,
              avg(CASE WHEN ($tableRt.response_first_byte = 0) THEN (0) ELSE ($tableRt.response_last_byte-$tableRt.response_first_byte) END) as response,
              avg(0) as gap,
              avg(0) as critical,
              CASE WHEN (position('?' in $tableRt.url) > 0) then trim('/' from (substring($tableRt.url for position('?' in substring($tableRt.url from 9)) +7))) else trim('/' from $tableRt.url) end as urlgroup,
              count(*) as request_count,
              'Label' as label,
              avg(CASE WHEN ($tableRt.response_last_byte = 0) THEN (0) ELSE (($tableRt.response_last_byte-$tableRt.start_time)/1000.0) END) as load,
              avg($table.timers_t_done) as beacon_time
          FROM $tableRt join $table on $tableRt.session_id = $table.session_id and $tableRt."timestamp" = $table."timestamp"
              where
              $tableRt."timestamp" between $(TV.startTimeMs) and $(TV.endTimeMs)
              and $table.session_id IS NOT NULL
              and $table.page_group ilike '$(UP.pageGroup)'
              and $table.params_u ilike '$(UP.urlRegEx)'
              and $table.user_agent_device_type ilike '$(UP.deviceType)'
              and $table.user_agent_os ilike '$(UP.agentOs)'
              and $table.timers_t_done >= $(UP.timeLowerMs) and $table.timers_t_done <= $(UP.timeUpperMs)
              and $table.params_rt_quit IS NULL
              group by urlgroup,urlpagegroup,label
              """);
      else

          if (SP.debugLevel > 8)
              #debugTableDF = query("""\
              #select
              #    count(*) as Count
              #FROM $tableRt join $table on $tableRt.session_id = $table.session_id and $tableRt."timestamp" = $table."timestamp"
              #    where
              #    $tableRt."timestamp" between $startTimeMs and $endTimeMs
              #    and $table.session_id IS NOT NULL
              #    and $table.page_group ilike '$(UP.pageGroup)'
              #    and $table.params_u ilike '$(UP.urlRegEx)'
              #    and $table.user_agent_device_type ilike '$(UP.deviceType)'
              #    and $table.timers_domready >= $(UP.timeLowerMs) and $table.timers_domready <= $(UP.timeUpperMs)
              #    and $table.params_rt_quit IS NULL
              #group by $table.params_u,$table.session_id,$table."timestamp",errors
              #    """);

              #beautifyDF(debugTableDF[1:min(30,end),:])

              debugTableDF = query("""\
              select
                  *
              FROM $tableRt join $table on $tableRt.session_id = $table.session_id and $tableRt."timestamp" = $table."timestamp"
                  where
                  $tableRt."timestamp" between $(TV.startTimeMs) and $(TV.endTimeMs)
                  and $table.session_id IS NOT NULL
                  and $table.page_group ilike '$(UP.pageGroup)'
                  and $table.params_u ilike '$(UP.urlRegEx)'
                  and $table.user_agent_device_type ilike '$(UP.deviceType)'
                  and $table.user_agent_os ilike '$(UP.agentOs)'
                  and $table.timers_domready >= $(UP.timeLowerMs) and $table.timers_domready <= $(UP.timeUpperMs)
                  and $table.params_rt_quit IS NULL
                  limit 3
                  """);

              beautifyDF(debugTableDF[1:min(30,end),:])
              println("pg=",UP.pageGroup," url=",UP.urlRegEx," dev=",UP.deviceType," dr lower=",UP.timeLowerMs," dr upper=",UP.timeUpperMs);

          end

          localTableDF = query("""\
          select
          CASE WHEN (position('?' in $table.params_u) > 0) then trim('/' from (substring($table.params_u for position('?' in substring($table.params_u from 9)) +7))) else trim('/' from $table.params_u) end as urlgroup,
              count(*) as request_count,
              avg($table.timers_domready) as beacon_time,
              sum($tableRt.encoded_size) as encoded_size,
              $table.errors as errors, $table.session_id,$table."timestamp"

          FROM $tableRt join $table on $tableRt.session_id = $table.session_id and $tableRt."timestamp" = $table."timestamp"
              where
              $tableRt."timestamp" between $(TV.startTimeMs) and $(TV.endTimeMs)
              and $table.session_id IS NOT NULL
              and $table.page_group ilike '$(UP.pageGroup)'
              and $table.params_u ilike '$(UP.urlRegEx)'
              and $table.user_agent_device_type ilike '$(UP.deviceType)'
              and $table.user_agent_os ilike '$(UP.agentOs)'
              and $table.timers_domready >= $(UP.timeLowerMs) and $table.timers_domready <= $(UP.timeUpperMs)
              and $table.params_rt_quit IS NULL
              and $table.errors IS NULL
          group by urlgroup,$table.session_id,$table."timestamp",errors
              """);


          if (nrow(localTableDF) == 0)
              return localTableDF
          end

          # Clean Up Bad Samples
          # Currently request < 10

          iRow = 0
          reqVector = localTableDF[:request_count]

          for reqCount in reqVector
              iRow = iRow + 1
              if (reqCount < 10)
                  if (SP.debugLevel > 8)
                      beautifyDF(localTableDF[iRow:iRow,:])
                  end
                 deleterows!(localTableDF,iRow)
              end
          end

          if (SP.debugLevel > 6)
              beautifyDF(localTableDF[1:min(30,end),:])
          end
      end

      return localTableDF
  catch y
      println("urlDetailTables Exception ",y)
  end
end

# From Individual-Streamline-Body

function finalUrlTableOutput(TV::TimeVars,UP::UrlParams,SP::ShowParams,topUrls::DataArray)
  try

  finalTable = DataFrame()
  finalTable[:url] = [""]
  finalTable[:beacon_time] = [0]
  finalTable[:request_count] = [0]
  finalTable[:encoded_size] = [0]
  finalTable[:samples] = [0]

  for testUrl in topUrls
      #UP.urlRegEx = string("%",ASCIIString(testUrl),"%")
      #UP.urlFull = string("/",ASCIIString(testUrl),"/")
      UP.urlRegEx = string("%",ASCIIString(testUrl))
      UP.urlFull = testUrl
      if (SP.mobile)
          UP.deviceType = "mobile"
          row = individualStreamlineTableV2(UP,SP,repeat=1)

          if (UP.orderBy == "size")
              if (row[:encoded_size][1] < UP.sizeMin)
                   if (SP.debugLevel > 4)
                       println("Case 1: Dropping row", row[:encoded_size][1], " < ", UP.sizeMin);
                   end
                  continue
              end
              if (row[:samples][1] < UP.samplesMin)
                   if (SP.debugLevel > 4)
                      println("Case 2: Dropping row", row[:samples][1], " < ", UP.samplesMin);
                   end
                  continue
              end
          else
              if (row[:beacon_time][1] < UP.timeLowerMs)
                   if (SP.debugLevel > 4)
                      println("Case 3: Dropping row", row[:beacon_time][1], " < ", UP.timeLowerMs);
                   end
                  continue
              end
              if (row[:samples][1] < UP.samplesMin)
                   if (SP.debugLevel > 4)
                      println("Case 4: Dropping row", row[:samples][1], " < ", UP.samplesMin);
                   end
                  continue
              end
          end

          push!(finalTable,[row[:url];row[:beacon_time];row[:request_count];row[:encoded_size];row[:samples]])
      end

      if (SP.desktop)
          UP.deviceType = "desktop"
          row = individualStreamlineTableV2(UP,SP,repeat=1)

          if (UP.orderBy == "size")
              if (row[:encoded_size][1] < UP.sizeMin)
                   if (SP.debugLevel > 4)
                       println("Case 1: Dropping row", row[:encoded_size][1], " < ", UP.sizeMin);
                   end
                  continue
              end
              if (row[:samples][1] < UP.samplesMin)
                   if (SP.debugLevel > 4)
                      println("Case 2: Dropping row", row[:samples][1], " < ", UP.samplesMin);
                   end
                  continue
              end
          else
              if (row[:beacon_time][1] < UP.timeLowerMs)
                   if (SP.debugLevel > 4)
                      println("Case 3: Dropping row", row[:beacon_time][1], " < ", UP.timeLowerMs);
                   end
                  continue
              end
              if (row[:samples][1] < UP.samplesMin)
                   if (SP.debugLevel > 4)
                      println("Case 4: Dropping row", row[:samplese][1], " < ", UP.samplesMin);
                   end
                  continue
              end
          end
          push!(finalTable,[row[:url];row[:beacon_time];row[:request_count];row[:encoded_size];row[:samples]])
      end
  end

  deleterows!(finalTable,1)

  if (UP.orderBy == "size")
      sort!(finalTable,cols=:encoded_size, rev=true)
          additional = join(["(Sorted By Size Descending; Min Samples ";UP.samplesMin;"; Top ";UP.limitRows;" Page Views)"]," ")
  else
      sort!(finalTable,cols=:beacon_time, rev=true)
          additional = join(["(Sorted By Time Descending; Min Samples ";UP.samplesMin;"; Top ";UP.limitRows;" Page Views)"]," ")
  end


  ft = names!(finalTable[:,:],
  [symbol("Recent Urls $(additional)");symbol("Time");symbol("Request Made");symbol("Page Size");symbol("Samples")])
  beautifyDF(ft[1:min(100,end),:])

  catch y
      println("finalUrlTableOutput Exception ",y)
  end
end

# From Individual-Streamline-Body

function beaconStatsRow(UP::UrlParams,SP::ShowParams,localTableDF::DataFrame)

  #Make a para later if anyone want to control
  goal = 3000.0

  row = DataFrame()
  row[:url] = UP.urlFull

  dv = localTableDF[:beacon_time]
  statsBeaconTimeDF = limitedStatsFromDV(dv)
  row[:beacon_time] = statsBeaconTimeDF[:median]
  samples = statsBeaconTimeDF[:count]
  if (SP.debug)
      println("bt=",row[:beacon_time][1]," goal=",goal)
  end

  if (SP.devView)
      if (UP.usePageLoad)
          chartTitle = "Page Load Time Stats: $(UP.urlFull) for $(UP.deviceType)"
      else
          chartTitle = "Page Domain Ready Time Stats: $(UP.urlFull) for $(UP.deviceType)"
      end
      showLimitedStats(statsBeaconTimeDF,chartTitle)
  end

  dv = localTableDF[:request_count]
  statsRequestCountDF = limitedStatsFromDV(dv)
  row[:request_count] = statsRequestCountDF[:median]
  if (SP.devView)
      chartTitle = "Request Count"
      showLimitedStats(statsRequestCountDF,chartTitle)
  end

  dv = localTableDF[:encoded_size]
  statsEncodedSizeDF = limitedStatsFromDV(dv)
  row[:encoded_size] = statsEncodedSizeDF[:median]

  row[:samples] = samples

  if (SP.devView)
      chartTitle = "Encoded Size"
      showLimitedStats(statsEncodedSizeDF,chartTitle)
  end

  if (SP.debug)
      beautifyDF(row[:,:])
  end
  return row
end

# From Individual-Streamline-Body

function showAvailableSessionsStreamline(TV::TimeVars,UP::UrlParams,SP::ShowParams,WellKnownHost::Dict,WellKnownPath::Dict,localTableDF::DataFrame,localTableRtDF::DataFrame)
  try
      full = join(localTableDF,localTableRtDF, on = [:session_id,:timestamp])
      io = 0
      s1String = ASCIIString("")

      for subdf in groupby(full,[:session_id,:timestamp])
          s = size(subdf)
          if(SP.debug)
              println("Size=",s," Timer=",subdf[1,:timers_t_done]," rl=",UP.timeLowerMs," ru=",UP.timeUpperMs)
          end
          if (UP.usePageLoad)
              timeVar = subdf[1,:timers_t_done]
          else
              timeVar = subdf[1,:timers_domready]
          end
          if (timeVar >= UP.timeLowerMs && timeVar <= UP.timeUpperMs)
              io += 1
              #println("Testing $(io) against $(showLines)")
              if io <= showLines
                  s1 = subdf[1,:session_id]
                  #println("Session_id $(s1)")
                  s1String = ASCIIString(s1)
                  timeStampVar = subdf[1,:timestamp]
                  timeVarSec = timeVar / 1000.0
                  # We may be missing requests such that the timers_t_done is a little bigger than the treemap
                  labelString = "$(UP.urlFull) $(timeVarSec) Seconds for $(UP.deviceType)"
                  if (SP.debug)
                      println("$(io) / $(showLines): $(UP.pageGroup),$(labelString),$(UP.urlRegEx),$(s1String),$(timeStampVar),$(timeVar),$(SP.showCriticalPathOnly),$(SP.devView)")
                  end
                  topPageUrl = individualPageData(TV,UP,SP,s1String,timeStampVar)
                  suitable  = individualPageReportV2(TV,UP,SP,WellKnownHost,WellKnownPath,topPageUrl,timeVar,s1String,timeStampVar)
                  if (!suitable)
                      showLines += 1
                  end
              else
                  return
              end
          end
      end
  catch y
      println("showAvailSessions Exception ",y)
  end
end

# From Individual-Streamline-Body

function individualPageData(TV::TimeVars,UP::UrlParams,SP::ShowParams,studySession::ASCIIString,studyTime::Int64)
  try

      toppageurl = DataFrame()

      if studyTime > 0
          toppageurl = sessionUrlTableDF(UP.resourceTable,studySession,studyTime)
          elseif (studySession != "None")
              toppageurl = allSessionUrlTableDF(UP.resourceTable,studySession,TV.startTimeMsUTC,TV.endTimeMsUTC)
          else
              toppageurl = allPageUrlTableDF(TV,UP)
      end;

      return toppageurl

  catch y
      println("individual page report Exception ",y)
  end
end

# From Individual-Streamline-Body

function individualPageReportV2(TV::TimeVars,UP::UrlParams,SP::ShowParams,WellKnownHost::Dict,WellKnownPath::Dict,toppageurl::DataFrame,timerDone::Int64,studySession::ASCIIString,studyTime::Int64)
  try

      #println("Clean Up Data table")
      toppageurl = names!(toppageurl[:,:],
      [symbol("urlpagegroup"),symbol("Start"),symbol("Total"),symbol("Redirect"),symbol("Blocking"),symbol("DNS"),
          symbol("TCP"),symbol("Request"),symbol("Response"),symbol("Gap"),symbol("Critical"),symbol("urlgroup"),
          symbol("request_count"),symbol("label"),symbol("load_time"),symbol("beacon_time")]);

      toppageurlbackup = deepcopy(toppageurl);
      toppageurl = deepcopy(toppageurlbackup)
      #if debug
      #    beautifyDF(toppageurl)
      #end

      removeNegitiveTime(toppageurl,:Total)
      removeNegitiveTime(toppageurl,:Redirect)
      removeNegitiveTime(toppageurl,:Blocking)
      removeNegitiveTime(toppageurl,:DNS)
      removeNegitiveTime(toppageurl,:TCP)
      removeNegitiveTime(toppageurl,:Request)
      removeNegitiveTime(toppageurl,:Response)

      #println("Scrub Data");
      scrubUrlToPrint(toppageurl);
      #println("Classify Data");
      classifyUrl(toppageurl);

      #println("Add Gap and Critical Path")
      toppageurl = gapAndCriticalPathV2(toppageurl,timerDone);
      if (!suitableTest(toppageurl,showDebug=SP.showDebug))
          return false
      end

      if (SP.showAdditionals)
          waterFallFinder(UP.beaconTable,studySession,studyTime,TV)
      end

      if (showDebug)
          beautifyDF(toppageurl)
      end

      labelField = fullUrl
      criticalPathTreemapV2(labelField,toppageurl;showTable=SP.showAdditionals,limit=40)

      if (showAdditionals)
          gapTreemapV2(TV,toppageurl,showTable=true,showPageUrl=true,showTreemap=false,limit=40)
      end

      if (!showCriticalPathOnly)
          #itemCountTreemap(toppageurl,showTable=true)      All entries are 1
          endToEndTreemap(TV,toppageurl,showTable=true)
          blockingTreemap(TV,toppageurl,showTable=true)
          requestTreemap(TV,toppageurl,showTable=true)
          responseTreemap(TV,toppageurl,showTable=true)
          dnsTreemap(TV,toppageurl,showTable=true)
          tcpTreemap(TV,toppageurl,showTable=true)
          redirectTreemap(TV,toppageurl,showTable=true)
      end

      return true

  catch y
      println("individual page report Exception ",y)
  end
end


# From Individual-Streamline-Body

function gapAndCriticalPathV2(toppageurl::DataFrame,timerDone::Int64)
  try
      # Start OF Gap & Critical Path Calculation

      toppageurl = names!(toppageurl[:,:],
      [symbol("urlpagegroup"),symbol("Start"),symbol("Total"),symbol("Redirect"),symbol("Blocking"),symbol("DNS"),
          symbol("TCP"),symbol("Request"),symbol("Response"),symbol("Gap"),symbol("Critical"),symbol("urlgroup"),
          symbol("request_count"),symbol("label"),symbol("load_time"),symbol("beacon_time")]);

      sort!(toppageurl,cols=[order(:Start),order(:Total,rev=true)]);

      #clear times beyond timerDone, set timerDone high if you wish to see all
      toppageurl2 = deepcopy(toppageurl)

      i = 1
      lastRow = 0
      for url in toppageurl[2:end,:urlgroup]
          i += 1
          newStartTime = toppageurl[i,:Start]
          newTotalTime = toppageurl[i,:Total]
          newEndTime = newStartTime + newTotalTime
          if (newStartTime > timerDone)
              if lastRow == 0
                  lastRow = i
              end
              #println("Clearing $(lastRow) for $(url) newStartTime=$(newStartTime), newEndTime=$(newEndTime), target=$(timerDone)")
              deleterows!(toppageurl2,lastRow)
              continue
          end

          #look for requests which cross the end of the timerDone
          if (newEndTime > timerDone && lastRow == 0)
              adjTime = timerDone-newStartTime
              #println("Adjusting $(lastRow) for $(url) newStartTime=$(newStartTime), oldEndTime=$(newEndTime), newEndTime=$(adjTime), target=$(timerDone)")
              toppageurl2[i,:Total] = adjTime
          end

      end

      #println("")
      #println(" Result ")
      #println("")

      #i = 1
      #for url in toppageurl2[2:end,:urlgroup]
      #    i += 1
      #    newStartTime = toppageurl2[i,:Start]
      #    newTotalTime = toppageurl2[i,:Total]
      #    println("XXX ",url," newStartTime=$(newStartTime), newTotalTime=$(newTotalTime), target=$(timerDone)")
      #end

      toppageurl = deepcopy(toppageurl2)

      toppageurl[:Gap] = 0
      toppageurl[:Critical] = 0

      #todo check the size to make sure at least 3 rows of data

      prevStartTime = toppageurl[1,:Start]
      prevTotalTime = toppageurl[1,:Total]
      i = 1
      toppageurl[:Critical] = toppageurl[1,:Total]

      for url in toppageurl[2:end,:urlgroup]
          i += 1
          toppageurl[i,:Gap] = 0
          toppageurl[i,:Critical] = 0

          newStartTime = toppageurl[i,:Start]
          newTotalTime = toppageurl[i,:Total]
          #println("Url ",url," newStartTime=$(newStartTime), newTotalTime=$(newTotalTime), target=$(timerDone)")

          #Sorted by start time ascending and largest total time decending
          #Anyone with same time has the previous is nested inside the current one and has no time

          if (newStartTime == prevStartTime)
              #println("Matched line $i start time $newStartTime")
              toppageurl[i,:Gap] = 0
              toppageurl[i,:Critical] = 0
              continue
          end

          # did we have a gap?
          gapTime = newStartTime - prevStartTime - prevTotalTime

          # Negitive gap means we start inside someone else
          if (gapTime < 0)
              #nested request or overlapping but no gap already done toppageurl[i,:gap] = 0

              prevMarker = prevStartTime + prevTotalTime
              newMarker = newStartTime + newTotalTime

              if (prevMarker >= newMarker)
                  # Still nested inside a larger request already donetoppageurl[i,:critical] = 0
                  continue
              else
                  # Figure how much of new time is beyond end of old time
                  # println("nst=",newStartTime,",ntt=",newTotalTime,",nm=",newMarker,",pst=",prevStartTime,",ptt=",prevTotalTime,",pm=",prevMarker)
                  # When done we will pick up at the end of this newer overlapped request
                  prevTotalTime = newMarker - prevMarker
                  #println("ptt=",prevTotalTime)

                  # it is critical path but only the part which did not overlap with the previous request
                  toppageurl[i,:Critical] = newMarker - prevMarker
                  prevStartTime = prevMarker
              end

          else
              #println("gap time ",gapTime,",",newStartTime,",",newTotalTime,",",prevStartTime,",",prevTotalTime)
              toppageurl[i,:Gap] = gapTime
              # All of its time is critical path since this is start of a new range
              toppageurl[i,:Critical] = newTotalTime
              prevTotalTime = newTotalTime
              prevStartTime = newStartTime
          end
          # move on
          runningTime = sum(toppageurl[:,:Gap]) + sum(toppageurl[:,:Critical])
          #println("rt", runningTime, " at ",prevStartTime)

      end

      # Do not fix last record.  It is the "Not Blocking" Row.  Zero it out
      #i += 1
      #toppageurl[i,:Gap] = 0
      #toppageurl[i,:Critical] = 0

      return toppageurl

   catch y
      println("gapAndCritcalPath Exception ",y)
  end
end

# From Individual-Streamline-Body

function suitableTest(toppageurl::DataFrame;timerLimitMs::Int64=2000,showDebug::Bool=false)
  try
      i = 1
      lastRow = 0
      for url in toppageurl[2:end,:urlgroup]
          i += 1
          newTotalTime = toppageurl[i,:Total]
          if (newTotalTime > timerLimitMs)
              if (showDebug)
                  println("Dropping page $(url) due to total time of $(newTotalTime)")
              end
              return false
          end
      end

      return true

   catch y
      println("suitableTest Exception ",y)
  end
end

# From Individual-Streamline-Body

function newPagesList()
  try

  jList = JSON.parse(theList)

  dataArray = get(jList,"data","none")
  urlListDF = DataFrame()
  urlListDF[:urlgroup] = [""]

  if (dataArray != "none")

      for dataDict in dataArray
          attribDict = get(dataDict,"attributes","none")
          urlValue = get(attribDict,"uri","none")
          #typeof(urlValue)
          #println(urlValue)

          push!(urlListDF,[urlValue])
      end
  end
  deleterows!(urlListDF,1)
  return urlListDF

  catch y
      println("newPagesList Exception",y)
  end
end

# From Page Group Details

function statsPGD(TV::TimeVars,UP::UrlParams)
    try
        localStatsDF = statsTableDF(UP.btView, UP.pageGroup, TV.startTimeMsUTC, TV.endTimeMsUTC);
        statsDF = basicStats(localStatsDF, UP.pageGroup, TV.startTimeMsUTC, TV.endTimeMsUTC)

        displayTitle(chart_title = "Raw Data Stats $(UP.pageGroup) Based On Beacon Page Load Time", chart_info = [TV.timeString],showTimeStamp=false)
        beautifyDF(statsDF[2:2,:])
        return statsDF
    catch y
        println("setupStats Exception ",y)
    end
end

# From Page Group Details

function peakPGD(TV::TimeVars,UP::UrlParams)
    showPeakTable(TV.timeString,UP.pageGroup,TV.startTimeUTC,TV.endTimeUTC;showStartTime30=false,showStartTime90=false,tableRange="Sample Set ")
end

# From Page Group Details

function concurrentSessionsPGD(TV::TimeVars,UP::UrlParams,SP::ShowParams,mobileView::ASCIIString,desktopView::ASCIIString)
    try
        if (!SP.mobile && !SP.desktop)
            chartConcurrentSessionsAndBeaconsOverTime(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
        end

        if (SP.mobile)
            timeString2 = timeString * " - Mobile Only"
            #displayTitle(chart_title = "Concurrent Sessions and Beacons for $(productPageGroup) - MOBILE ONLY", chart_info = [timeString2],showTimeStamp=false)
            setTable(mobileView)
            chartConcurrentSessionsAndBeaconsOverTime(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
            setTable(UP.btView)
        end

        if (SP.desktop)
            timeString2 = timeString * " - Desktop Only"
            #displayTitle(chart_title = "Concurrent Sessions and Beacons for $(productPageGroup) - DESKTOP ONLY", chart_info = [timeString],showTimeStamp=false)
            setTable(desktopView)
            chartConcurrentSessionsAndBeaconsOverTime(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
            setTable(UP.btView)
        end

    catch y
        println("cell concurrentSessionsPGD Exception ",y)
    end
end

# From Page Group Details

function loadTimesPGD(TV::TimeVars,UP::UrlParams,SP::ShowParams,mobileView::ASCIIString,desktopView::ASCIIString)
    try

        #todo turn off title in chartLoadTimes
        #displayTitle(chart_title = "Median Load Times for $(productPageGroup)", chart_info = [timeString],showTimeStamp=false)
        if (!SP.mobile && !SP.desktop)
            chartLoadTimes(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
        end

        #cannot use the other forms without creating the code for the charts.  Titles cannot be overwritten.
        if (SP.mobile)
            displayTitle(chart_title = "Median Load Times for $(UP.pageGroup) - MOBILE ONLY", chart_info = [TV.timeString],showTimeStamp=false)
            setTable(mobileView)
            chartLoadTimes(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
            setTable(UP.btView)
        end

        if (SP.desktop)
            displayTitle(chart_title = "Median Load Times for $(UP.pageGroup) - DESKTOP ONLY", chart_info = [TV.timeString],showTimeStamp=false)
            setTable(desktopView)
            chartLoadTimes(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
            setTable(UP.btView)
        end

    catch y
        println("cell loadTimesPGD Exception ",y)
    end
end

# From Page Group Details

function topUrlPGD(TV::TimeVars,UP::UrlParams)
    topUrlTable(UP.btView,UP.pageGroup,TV.timeString; limit=UP.limitRows)
end

# From Page Group Details

function thresholdChartPGD(medianThreshold::Float64)
    try
        chartPercentageOfBeaconsBelowThresholdStackedBar(tv.startTimeUTC, tv.endTimeUTC, tv.datePart; threshold = medianThreshold)
    catch y
        println("chartPercent exception ",y)
    end
end

# From Page Group Details

function pageLoadPGD()
    sessionLoadPGD()
end

# From Page Group Details

function sessionLoadPGD(TV::TimeVars,UP::UrlParams)
    try
        perfsessionLength = getAggregateSessionLengthAndDurationByLoadTime(TV.startTimeUTC, TV.endTimeUTC);

        c3 = drawC3Viz(perfsessionLength; columnNames=[:load_time,:total,:avg_length], axisLabels=["Session Load Times","Completed Sessions", "Average Session Length"],
             dataNames=["Completed Sessions","Average Session Length", "Average Session Duration"], mPulseWidget=false,
             chart_title="Session Stats for $(UP.pageGroup) Page Group", y2Data=["data2"], vizTypes=["area","line"]);
    catch y
        println("sessionLoadPGD Exception ",y)
    end
end

# From Page Group Details

function loadTimesParamsUPGD(TV::TimeVars,UP::UrlParams)
    try
        chartMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:params_u,minPercentage=0.5)

        df = getTopURLsByLoadTime(TV.startTimeUTC, TV.endTimeUTC, minPercentage=0.5);

        sort!(df, cols=:Requests, rev=true)
        display("text/html", """
        <h2 style="color:#ccc">Top URLs By Load Time for $(UP.pageGroup) (Ordered by Requests)</h2>
            """)
        beautifyDF(df);
        catch y
        println("loadTimesParamsUPGD Exception ",y)
    end
end

# From Page Group Details

function medianTimesPGD(TV::TimeVars)
    try
        chartMedianLoadTimesByDimension(TV.startTimeUTC, TV.endTimeUTC,dimension=:geo_cc,minPercentage=0.6)
        chartMedianLoadTimesByDimension(TV.startTimeUTC, TV.endTimeUTC; dimension=:user_agent_device_type, n=15, orderBy="frontend", minPercentage=0.001)
        printDF = getMedianLoadTimesByDimension(TV.startTimeUTC, TV.endTimeUTC; dimension=:user_agent_device_type, n=15, orderBy="frontend", minPercentage=0.001)
        beautifyDF(printDF)
    catch y
        println("medianTimesPGD Exception ",y)
    end
end

# From Page Group Details

function medLoadHttpPGD(TV::TimeVars)
    try
        chartMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:http_referrer,minPercentage=0.5)
        chartMedianLoadTimesByDimension(TV.startTimeUTC,TV.endTimeUTC,dimension=:params_r,minPercentage=0.5)
        chartTopN(TV.startTimeUTC, TV.endTimeUTC; variable=:landingPages)
    catch y
        println("cell chartSlowestUrls Exception ",y)
    end
end

# From Page Group Details

function dpQuartilesPGD(TV::TimeVars)
    datePartQuartiles(TV.startTimeUTC, TV.endTimeUTC, TV.datePart)
end

# From Page Group Details

function sunburst(TV::TimeVars)
    try
        result10 = getAllPaths(TV.startTimeUTC, TV.endTimeUTC; n=60, f=getAbandonPaths);
        drawSunburst(result10[1]; totalPaths=result10[3])
    catch y
        println("sunburst Exception ",y)
    end
end

# From Page Group Details

function pgTreemap(TV::TimeVars,UP::UrlParams)
    pageGroupTreemap(TV,UP)
end

# From Page Group Details

function bouncesPGD(TV::TimeVars)
    chartLoadTimeMediansAndBounceRatesByPageGroup(TV.startTimeUTC,TV.endTimeUTC)
end

# From Page Group Details

function pgQuartPGD(TV::TimeVars,UP::UrlParams)
    pageGroupQuartiles(UP.beaconTable,UP.pageGroup,TV.startTimeUTC,TV.endTimeUTC,TV.startTimeMsUTC,TV.endTimeMsUTC,TV.timeString;limit=UP.limitRows,showTable=false);
end

# From Page Group Details

function activityImpactPGD(TV::TimeVars,UP::UrlParams)
    chartActivityImpactByPageGroup(TV.startTimeUTC, TV.endTimeUTC;n=UP.limitRows);
end

# From 3rd Party Body TypeALl

function typeAllBodyQuick(TV::TimeVars,UP::UrlParams,SP::ShowParams,qPageGroup::ASCIIString,qUrlRegEx::ASCIIString,qDeviceType::ASCIIString)
    UP.pageGroup = qPageGroup
    UP.urlRegEx = qUrlRegEx
    UP.deviceType = qDeviceType

    if (qDeviceType == "desktop")
      SP.desktop = true
    end
    if (qDeviceType == "mobile")
      SP.mobile = true
    end
    if (qDeviceType == "%")
      SP.desktop = true
      SP.mobile = true
    end

    typeAllBody(TV,UP,SP)
end

function typeAllBody(TV::TimeVars,UP::UrlParams,SP::ShowParams)
    try
        # Is there data?
        localTableDF = estimateBeacons(TV,UP,SP)
        if (SP.debugLevel > 0)
          println("$(UP.beaconTable) count is ",size(localTableDF))
          println("")
        end

        # Stats on the data
        statsDF = DataFrame()
        dv = localTableDF[:timers_t_done]
        statsDF = basicStatsFromDV(dv)

        displayTitle(chart_title = "Beacon Data Stats for $(UP.pageGroup)", chart_info = [TV.timeString],showTimeStamp=false)
        beautifyDF(statsDF[:,:])

        rangeLower = statsDF[1:1,:q25][1]
        rangeUpper = statsDF[1:1,:q75][1]

        studyTime = 0
        studySession = "None"

        toppageurl = DataFrame()
        if studyTime > 0
            toppageurl = sessionUrlTableDF(UP.resourceTable,studySession,studyTime)
            elseif (studySession != "None")
              toppageurl = allSessionUrlTableDF(UP.resourceTable,studySession,TV.startTimeMs,TV.endTimeMs)
            else
                toppageurl = allPageUrlTableDF(TV,UP)
        end

        if (SP.debugLevel > 0)
          println("topPageUrl rows and column counts are ",size(toppageurl))
          println("")
        end

        toppageurl = names!(toppageurl[:,:],
        [symbol("urlpagegroup"),symbol("Start"),symbol("Total"),symbol("Redirect"),symbol("Blocking"),symbol("DNS"),
            symbol("TCP"),symbol("Request"),symbol("Response"),symbol("Gap"),symbol("Critical"),symbol("urlgroup"),
            symbol("request_count"),symbol("label"),symbol("load_time"),symbol("beacon_time")]);


        # Debug
        toppageurlbackup = deepcopy(toppageurl);

        # Debug
        toppageurl = deepcopy(toppageurlbackup)

        removeNegitiveTime(toppageurl,:Total)
        removeNegitiveTime(toppageurl,:Redirect)
        removeNegitiveTime(toppageurl,:Blocking)
        removeNegitiveTime(toppageurl,:DNS)
        removeNegitiveTime(toppageurl,:TCP)
        removeNegitiveTime(toppageurl,:Request)
        removeNegitiveTime(toppageurl,:Response)

        summaryStatsDF = DataFrame()
        dv = toppageurl[:Total]
        summaryStatsDF = basicStatsFromDV(dv)

        displayTitle(chart_title = "RT Data Stats for $(UP.pageGroup)", chart_info = [TV.timeString],showTimeStamp=false)
        beautifyDF(summaryStatsDF[:,:])

        scrubUrlToPrint(toppageurl);
        classifyUrl(toppageurl);

        summaryPageGroup = summarizePageGroups(toppageurl)
        beautifyDF(summaryPageGroup[1:min(end,10),:])

        # This is the non-Url specific report so get the summary table and overwrite toppageurl
        toppageurl = deepcopy(summaryPageGroup);

        itemCountTreemap(toppageurl,showTable=true)
        endToEndTreemap(TV,toppageurl,showTable=true,limit=100)
        blockingTreemap(TV,toppageurl,showTable=true)
        requestTreemap(TV,toppageurl,showTable=true)
        responseTreemap(TV,toppageurl,showTable=true)
        dnsTreemap(TV,toppageurl,showTable=true)
        tcpTreemap(TV,toppageurl,showTable=true)
        redirectTreemap(TV,toppageurl,showTable=true)
    catch y
        println("typeAll Exception ",y)
    end
end

# From 3rd Party Body TypeALl

function summarizePageGroups(toppageurl::DataFrame)
    try
        summaryPageGroup = DataFrame()
        summaryPageGroup[:urlpagegroup] = "Grand Total"
        summaryPageGroup[:Start] = 0
        summaryPageGroup[:Total] = 0
        summaryPageGroup[:Redirect] = 0
        summaryPageGroup[:Blocking] = 0
        summaryPageGroup[:DNS] = 0
        summaryPageGroup[:TCP] = 0
        summaryPageGroup[:Request] = 0
        summaryPageGroup[:Response] = 0
        summaryPageGroup[:Gap] = 0
        summaryPageGroup[:Critical] = 0
        summaryPageGroup[:urlgroup] = ""
        summaryPageGroup[:request_count] = 0
        summaryPageGroup[:label] = ""
        summaryPageGroup[:load_time] = 0.0
        summaryPageGroup[:beacon_time] = 0.0

        for subDf in groupby(toppageurl,:urlpagegroup)
            #println(subDf[1:1,:urlpagegroup]," ",size(subDf,1))
            Total = 0
            Redirect = 0
            Blocking = 0
            DNS = 0
            TCP = 0
            Request = 0
            Response = 0
            Gap = 0
            Critical = 0
            request_count = 0
            load_time = 0.0
            beacon_time = 0.0

            for row in eachrow(subDf)
                #println(row)
                Total += row[:Total]
                Redirect += row[:Redirect]
                Blocking += row[:Blocking]
                DNS += row[:DNS]
                TCP += row[:TCP]
                Request += row[:Request]
                Response += row[:Response]
                Gap += row[:Gap]
                Critical += row[:Critical]
                request_count += row[:request_count]
                load_time += row[:load_time]
                beacon_time += row[:beacon_time]
            end
            #convert to seconds
            load_time = (Total / request_count) / 1000
            push!(summaryPageGroup,[subDf[1:1,:urlpagegroup];0;Total;Redirect;Blocking;DNS;TCP;Request;Response;Gap;Critical;subDf[1:1,:urlpagegroup];request_count;"Label";load_time;beacon_time])
        end

        sort!(summaryPageGroup,cols=[order(:Total,rev=true)])
        return summaryPageGroup
    catch y
        println("summarizePageGroup Exception ",y)
    end
end