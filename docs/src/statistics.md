# Graphics of statistics

```@example lite
using BinderPlots
using PlotlyDocumenter # hide

version = BinderPlots.PlotlyLight.plotly.version # hide
PlotlyDocumenter.change_default_plotly_version(version) # hide
nothing # hide
```

Both `Plots.jl` (through `StatsPlots`) and `Plotly` have the ability to easily create some of the basic graphics of statistics. `BinderPlots` does not attempt to provide an interface for these graphics, rather the underlying `Plotly` interface would be used. This section shows some example usage.

The basic graphics of statistics show distributions (what can be and how often that something occurs) and basic relationships (especially between an explanatory and response variable).

In the following the data is either numeric or categorical. The data may be passed along via the positional arguments of `plot` or as named arguments to pass directly to `PlotlyLight`. The `plot` interface allows for a grouping value, to be described later. Series attributes are passed along through keywords. Some of the graphics require adjustments to the underlying layout.


The different grqphics we discuss are defined by the `seriestype`. We have `:histogram`, `:histogram2d`, `:bar`, `:pie`, `:boxplot`, in addition to `:scatter`.

A histogram is a familiar graphic to illustrate the distribution of a single numeric data set. By passing the data in as the `x` argument the graphic is easy to construct:

```@example lite
x = rand(100)
plot(x; seriestype=:histogram)

to_documenter(current())           # hide
```

Later, as an example of translating `plotly`'s JavaScript examples,
many variants of histograms are shown.

Bar charts show the distribution of categorical variables. The `:bar` type expects the `x` value to get the levels and the `y` value to be the counts. In this example, two such bar charts are made:

```@example lite
animals = ["giraffes", "orangutans", "monkeys"]
p = plot(animals, [10,20,30]; seriestype=:bar, label="Zoo 1")
plot!(p, animals, [5,6,8];    seriestype=:bar, label="Zoo 2")
p.layout.barmode="group";

to_documenter(current())           # hide
```

The last command sets the `:barmode` attribute to `"group"` to specify how the two series are presented together.


The pie chart is a lesser used graphic to illustrate a categorical variable, showing the relative proportion of the categories. The underlying percentage will be computed, so raw counts may be used. The bar chart above use  the generic `x` and `y` names for its data; howeverthe `Plotly` [pie chart](https://plotly.com/javascript/pie-charts/) uses named arguments `labels` and `values`:

```@example lite
labels =["a","b", "c"]
values = [19, 26, 55]
plot(; labels, values, seriestype=:pie, hole=0.4)

to_documenter(current())           # hide
```

The graphic above used the `hole` argument to make donut.

The [box plot](https://plotly.com/javascript/box-plots/), like a histogram, is a graphic to show the distribution of a single numeric variable. It uses a style that highlights just the basic descriptions of a distribution (center, spread, symmetry, skew, ...).


```@example lite
x = randn(100)
plot(nothing, x; seriestype=:boxplot)

to_documenter(current())           # hide
```

Passing the data into the first, `x`,  argument position instructs the drawing of vertical box plots, using the second, `y`, argument (by padding the first position with `nothing`) produces  a vertical box plot.

## Relationships, grouping

Statistics graphics are also used to show relationships between variables. In the example of the bar plot, two data sets are shown together. A common format for storing multiple datasets is "long format" where data is structured with each row representing a case and each column recording the value of a variable for each case. For the data in the bar plot example, this would be `[10, 20, 30, 5, 6, 8]`, `["giraffes", "orangutans", "monkeys","giraffes", "orangutans", "monkeys"]`, and `["zoo 1", "zoo 1", "zoo 1", "zoo 2", "zoo 2", "zoo 2"]` to indicate the group. This format lends itself to the "split-apply-combine" data processing style where the data is split into groups, a function is applied to each group, and then the results are then combined. For this application, the apply step is to visually represent the grouped data; the combine step displays each series as a whole.

Splitting the data on the grouping variable can be done in different ways. If this variable is passed to the `group` argument for these graphics, the `SplitApplyCombine.group` function handles the grouping.

For example, were the data given in long format, the following call to `plot` passes the splitting part off:



```@example lite
cnt = [10, 20, 30, 5, 6, 8]
a = ["giraffes", "orangutans", "monkeys","giraffes", "orangutans", "monkeys"]
g = ["zoo 1", "zoo 1", "zoo 1", "zoo 2", "zoo 2", "zoo 2"]

plot(a, cnt, group=g, seriestype=:bar)

to_documenter(current())           # hide
```

The common workflow would store the variable `cnt`, `a`, and `g` in a data frame. No special handling of data frames is provided by `BinderPlots`.


We now use data sampled from the Palmer Penguins data set to illustrate some different graphics.

```@example lite
# Sample from data set available in PalmerPenguins.jl

species = ["Adelie", "Adelie", "Gentoo", "Adelie", "Gentoo", "Chinstrap", "Adelie", "Adelie", "Adelie", "Adelie", "Gentoo", "Chinstrap", "Adelie", "Adelie", "Gentoo", "Adelie", "Gentoo", "Adelie", "Gentoo", "Adelie", "Adelie", "Adelie", "Gentoo", "Adelie", "Adelie", "Gentoo", "Adelie", "Adelie", "Adelie", "Gentoo"]

island = ["Biscoe", "Dream", "Biscoe", "Biscoe", "Biscoe", "Dream", "Biscoe", "Torgersen", "Biscoe", "Torgersen", "Biscoe", "Dream", "Dream", "Torgersen", "Biscoe", "Dream", "Biscoe", "Biscoe", "Biscoe", "Biscoe", "Torgersen", "Dream", "Biscoe", "Dream", "Biscoe", "Biscoe", "Torgersen", "Biscoe", "Dream", "Biscoe"]

bill_length_mm = [37.9, 37.2, 45.5, 38.2, 51.1, 51.5, 38.1, 42.8, 41.1, 36.6, 46.8, 45.7, 41.5, 40.9, 46.2, 39.0, 48.8, 40.6, 45.5, 39.6, 36.2, 37.5, 41.7, 38.9, 42.2, 47.6, 46.0, 41.6, 40.7, 46.9]

bill_depth_mm = [18.6, 18.1, 13.7, 20.0, 16.3, 18.7, 17.0, 18.5, 18.2, 17.8, 15.4, 17.0, 18.5, 16.8, 14.9, 18.7, 16.2, 18.6, 14.5, 20.7, 17.2, 18.5, 14.7, 18.8, 19.5, 14.5, 21.5, 18.0, 17.0, 14.6]

body_mass_g = [3150, 3900, 4650, 3900, 6000, 3250, 3175, 4250, 4050, 3700, 5150, 3650, 4000, 3700, 5300, 3650, 6000, 3550, 4750, 3900, 3150, 4475, 4700, 3600, 4275, 5400, 4200, 3950, 3725, 4875]

sex =["female", "male", "female", "male", "male", "male", "female", "male", "male", "female", "male", "female", "male", "female", "male", "male", "male", "male", "female", "female", "female", "male", "female", "female", "male", "male", "male", "male", "male", "female"]

df = (; species, island, bill_length_mm, bill_depth_mm, body_mass_g, sex)

nothing
```

The boxplot is a very useful graphic to compare basic features of related distributions. In the following, we look at the body mass split by island:


```@example lite
plot(nothing, df.body_mass_g, group=df.island, seriestype=:boxplot)

to_documenter(current())           # hide
```

This shows the same data using a histogram:

```@example lite
p = plot(df.body_mass_g, group=df.island, seriestype=:histogram)
p.layout.barmode = "overlay"
p

to_documenter(current())           # hide
```

The different islands have different species dominate, so the differences are expected. This shows a scatter plot of bill measurements for each species:

```@example lite
plot(df.bill_depth_mm, df.bill_length_mm; group = df.species,
     seriestype = :scatter,
     marker = (10, (:red, :blue, :green), (:star, :circle, :square)))

to_documenter(current())           # hide
```


## Histogram examples

The page [https://plotly.com/javascript/histograms/](https://plotly.com/javascript/histograms/) shows several variants of histograms and the JavaScript code to produce them. This set of examples show how these would be created in `BinderPlots`. The key is that *almost* exclusively, the JavaScript interface is followed for the graphics os statistics, outside of `scatter` plots.

### Basic histogram


```@example lite
x = rand(500)
plot(x, seriestype=:histogram)

to_documenter(current())           # hide
```


### Horizontal

This example uses `marker` to specify a color to the histogram. A `Config` object is needed to avoid the magic processing of the `marker` arguments.

```@example lite
y = rand(500)
plot(nothing, y,seriestype=:histogram,  marker=Config(color=:pink)) # not recycled
to_documenter(current())           # hide
```

### Overlaid Histogram

This example uses two histogram calls. The arrangement of the two graphics is passed to the `barmode` attribute of the `layout`:

```@example lite
x = 1 .+ rand(500)
x1 = 1.1 .+ rand(500)
p = plot(x, seriestype=:histogram, label="trace0",
   marker=Config(color=:green), opacity=0.5)
plot!(p, x1, seriestype=:histogram, label="trace1",
   marker=Config(color=:red), opacity=0.5)
p.layout.barmode=:overlay
p

to_documenter(current())           # hide
```

### Stacked Histograms

The `:stack` style for `barmode` has a different display:

```@example lite
x = rand(500)
x1 = rand(500)
p = plot(x, seriestype=:histogram, label="trace0")
plot!(p, x1, seriestype=:histogram, label="trace1")
p.layout.barmode=:stack
p

to_documenter(current())           # hide
```

### Colored and Styled Histograms

This example passes more style arguments to `marker`. It also has to work around the fact that the `Config` constructor has some issues when a reserved keyword, like `end`, is used.

```@example lite
k = rand(500)
x1 = 5 * k
x2 = 10 * k
y1 = k
y2 = 2k

xbins = Config(start=0.5, size=0.06)
xbins.end=2.8 # <-- why we can't use Config(start=0.5, size=0.06, end=2.8)

p = plot(x1, y1;
seriestype=:histogram,
label="control",
autobinx = false, histnorm="count",
marker = Config(color=rgb(255, 100, 102, 0.7),
                line=Config(color=rgb(255, 100, 102, 1.0), width=1)),
opacity=0.5,
xbins
)

xbins.start, xbins.end = -3.2, 4
plot!(x2, y2;
seriestype=:histogram,
label = "experimental",
autobinx = false,
marker = Config(color=rgb(100, 200, 102, 0.7),
                line = Config(color=rgb(100, 200, 102, 1.0), width=1)),
xbins,
opacity = 0.75
)

for (k,v) ∈ pairs((bargap=0.05, bargroupgap=0.2, barmode="overlay",
  title = "sampled results"))
  p.layout[k] = v
end
xlabel!(p, "Value")
ylabel!(p, "Count")
p

to_documenter(current())           # hide
```

### Cumulative Histogram

```@example lite
x = rand(500)
plot(x; seriestype=:histogram,
        cumulative=Config(enabled=true))

to_documenter(current())           # hide
```

### Normalized Histogram

```@example lite
x = rand(500)
plot(x; seriestype=:histogram,
        histnorm="probability",
        marker = Config(color=rgb(255,255,100)))

to_documenter(current())           # hide
```

### Specify Binning Function

```@example lite
x = ["Apples","Apples","Apples","Oranges", "Bananas"]
y = ["5","10","3","10","5"]
plot(x,y; seriestype=:histogram,
     histfunc="count", label="count")
plot!(x,y; seriestype=:histogram,
     histfunc="sum", label="sum")

to_documenter(current())           # hide
```
