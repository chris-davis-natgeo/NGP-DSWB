## Connecting to Redshift via ODBC

To connect to redshift, first use `ODBC` and then connect to your predefined `DSN`

using ODBC
ODBC.connect("vfdsn")


Remember during the `ODBC` setup when we created `vfdsn`? It's in the [Setup Wiki](http://design-gitlab.soasta.com/data-science-workbench/ipython/wikis/developer-setup-mac-os-x#odbc)

You can now go ahead and execute SQL against the database that this `DSN` points to.  For example, the following query gets a count of rows in the `soasta_beacons` table.

results = query("SELECT COUNT(*) FROM soasta_beacons")

Or get a list of all tables:

tables=query("
    SELECT DISTINCT tablename
      FROM pg_table_def
     WHERE schemaname = 'public'
     ORDER BY tablename
")

size(tables)

Or describe a single table

defn = query("
    SELECT *
      FROM pg_table_def
     WHERE tablename = 'quickenloans_beacons'
       AND schemaname = 'public'
")


### DataFrames

Notice that the rows above terminate after `30` with an ellipses following. This is so because the result of the `query` function is a `DataFrame`, which gives you a window into the returned data.  You can confirm this using the `typeof` function:

typeof(defn)

You can query the `DataFrame` with several methods...

For example, to find out how many rows and columns it has:

size(defn)

To look at rows 30-50:

defn[30:50, :]

Notice that numbering starts with 1 unlike other languages you may be used to where numbering starts with 0

#### Filtering DataFrames

You can also look at rows that match certain criteria:

defn[defn[:_type] .== "bigint", :]

#### Regex match on DataFrames

To run a regular expression match on the elements of a `DataFrame`, we need to use the `ismatch` method with an iterator since `ismatch` is not Vectorized.  The section `for x in ...` is the iteration.

defn[Bool[ismatch(r"^param", x) for x in defn[:column]], :]

#### More DataFrame methods

If you import the `DataFrames` package, you'll also get other functions to use, like `head`, `tail`, `describe`, `mean`, `median`, etc.  See [the docs](http://dataframesjl.readthedocs.org/en/latest/getting_started.html#the-dataframe-type) for more information.

using DataFrames
head(defn)

tail(defn)

tables[Bool[ismatch(r"beacon", x) && !ismatch(r"rbeacon", x) for x in tables[:tablename]], :]

describe(defn)

### Variable Interpolation

Let's declare a variable and use that in a query:

table = "soasta_beacons"

We can now use this variable in a string using `$()` to dereference it.

# Get the date range of the table and format it using strftime
timestamp_range = query("SELECT min(timestamp) as min, max(timestamp) as max FROM $(table)");
println(timestamp_range, "\n\n",
strftime("%Y-%m-%dT%H:%M:%S", div(timestamp_range[1, 1], 1000)),
    " - ",
strftime("%Y-%m-%dT%H:%M:%S", div(timestamp_range[1, 2], 1000))
)

The first index to the dataframe is the row, and the second is the column.  Notice that we used the `div` function to perform integer division.  We could have also used `fld` to divide and get the floor or `cld` to divide and get the ceiling.

Now let's select a bunch of beacons that match certain criteria.  We can reference the variable we just defined in our query.

**Security Alert:** Do not do this with untrusted data as this could result in `SQL Injection` attacks

# This will take a few (<20) seconds to run, so be patient
results = query("
SELECT
    page_group,
    geo_cc, geo_rg, geo_city, geo_org, geo_netspeed,
    user_agent_family, user_agent_major, user_agent_os, user_agent_osversion, user_agent_model,
    params_dom_sz, params_dom_ln, params_dom_script, params_dom_img,
    timers_t_done
  FROM $(table)
 WHERE page_group IS NOT NULL
   AND (params_rt_quit IS NULL OR params_rt_quit = FALSE)
   AND timers_t_done IS NOT NULL
   AND timers_t_done BETWEEN 0 AND 600000
   AND timestamp > ($(timestamp_range[1, 2])-(1*24*60*60*1000))
")

# The size function tells us the number of rows and columns in the DataFrame
size(results)

# The second argument to size specifies which dimension's size we want.  1 is rows, 2 is columns, and so on for multi-dimensional arrays
size(results, 1)

# median, mean, and a bunch of other DataFrame functions are vectorized, so they operate on a given column across all rows
median(results[:timers_t_done])

median(results[:params_dom_sz])

mean(results[:params_dom_sz])

### More Stats with StatsBase

The `StatsBase` package has some more interesting functions, like `iqr`, `var`, `kurtosis`, etc.  These are all Vectorized, so can run on an entire column.  See [the StatsBase docs](http://statsbasejl.readthedocs.org/en/latest/index.html) for more information.

using StatsBase

(iqr(results[:timers_t_done]), var(results[:timers_t_done]), kurtosis(results[:timers_t_done]))

### Grouping a DataFrame by a column

`DataFrames` use the [Split-Apply-Combine Strategy](http://dataframesjl.readthedocs.org/en/latest/split_apply_combine.html) to summarise and aggregate a `DataFrame` by one or more columns.

by(results, :page_group) do df
    DataFrame(iqr = iqr(df[:timers_t_done]), summary = summarystats(df[:timers_t_done]))
end

#### Using more than one column

We can group by more than one column.  In this case we use `page_group` and `geo_cc`.  We also use the `head` function to limit the results to the top 15 (the second parameter to `head` is 15)

head(by(results, [:geo_cc, :page_group]) do df
    DataFrame(m=median(df[:timers_t_done]), iqr = iqr(df[:timers_t_done]), s² = var(df[:timers_t_done]))
end, 15)

### Unicode Variable Names

Notice that we used a variable name of `s²` above.

To type this out, we use `s\^2<Tab>`

In general, you can use any LaTeX shortcuts to create Unicode identifiers, so `\alpha` will get you a `α` and so on.  Type `\al<Tab>` to get an autocomplete list.

See the [Unicode operators and symbols notebook](How%20To%20Unicode%20operators%20and%20symbols.ipynb) for a more detailed tutorial about using Unicode in an IJulia notebook

### More DataFrames methods

The `names` function returns a list of column names.  Since DataFrames are column first indexed, it is always more efficient to iterate through a DataFrame in column major order.

names(results)

### JSON

Now let's put a bunch of this together and generate a JSON document for our resultset

We cannot just use JSON.json on a DataFrame since that converts it in column major order with a some Julia scaffolding
and that isn't suitable for most consumers of the data.  Instead we need to write code that converts our DataFrame to
an array of Dicts with the right keys, and then convert them to JSON

function toJSON(rows::DataFrame)
    n = size(rows, 1)
    cols = names(rows)
    colmap = Dict([
        (:page_group, "page_group"),
        (:geo_cc, "geo.cc"),
        (:geo_rg, "geo.rg"),
        (:geo_city, "geo.city"),
        (:geo_org, "org"),
        (:geo_netspeed, "netspeed"),
        (:user_agent_family, "ua.family"),
        (:user_agent_major, "ua.major"),
        (:user_agent_os, "ua.os"),
        (:user_agent_osversion, "ua.osversion"),
        (:user_agent_model, "ua.model"),
        (:params_dom_sz, "dom.sz"),
        (:params_dom_ln, "dom.ln"),
        (:params_dom_script, "dom.script"),
        (:params_dom_img, "dom.img"),
        (:timers_t_done, "timers.t_done")
    ])

    out = Array(Dict, n)

    for colname in cols
        for rindex in 1:n
            if !isdefined(out, rindex)
                out[rindex] = Dict()
            end

            out[rindex][colmap[colname]] = isna(rows[rindex, colname]) ? "Unknown" : rows[rindex, colname]
        end
    end

    JSON.json(out)
end

toJSON(results)

This is in a format suitable to pass on to various JavaScript visualization libraries like D3 or Google Charts.

### Wrapping Up

We'll end this tutorial here.  At this point it would be useful to explore some charting libraries and use them to visualize and interact with the data we've pulled out.