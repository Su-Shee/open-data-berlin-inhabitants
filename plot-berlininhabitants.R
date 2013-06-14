library(sqldf)
library(RPostgreSQL)

# data from csv file, read into sqlite by R, fetch data by sql statements on data frame

options(sqldf.driver = "SQLite")

file <- 'berlininhabitants-2011.csv'
csv  <- read.csv(file, header = TRUE, sep = ';')

colnames(csv) <- c("official_district", "district", "gender", "nationality", "age", "quantity")

# list female percentages for every district:
by_women <- sqldf("SELECT 
                     district, round( cast( 
                       sum(case when gender = 'f' then quantity end) AS real)/sum(quantity)*100, 2) 
                   AS percent, sum(quantity) 
                   FROM 
                     csv 
                   GROUP BY 
                     district 
                  ORDER BY 
                    percent 
                  DESC LIMIT 10")

par( mar = c(5, 5, 5, 5) )
women_plot <- barplot( c(by_women$percent), 
                       main = "district by women", 
                       horiz = TRUE, names.arg = by_women$district, 
                       col = heat.colors(10), 
                       space = 0.1, 
                       cex.axis = 0.6, cex = 0.6, 
                       las = 1, xlim = c(0, 100)
                      )

text(5, women_plot, 
     labels = paste( by_women$percent, '%' ), 
     adj = c(0, 0.6), cex = 0.7)


# fetch data from postgres database

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "berlindata", user = "postgres", host = "10.13.2.55")

# is indeed Prenzlauer Berg the district with the most children implying AS many parents AS well?
res <- dbSendQuery(con, 
  "SELECT 
    district, to_char( cast(
      sum(case when age_high = '5' then quantity end) AS decimal)/sum(quantity)*100, 'FM990D99') 
    AS percent, sum(quantity) 
  FROM 
    inhabitants 
  GROUP BY 
    district 
  ORDER BY 
    percent 
  DESC LIMIT 10;"
)

children_by_district <- fetch(res, n = -1)

par( mar = c(5, 7, 5, 5) )
children_plot <- barplot( c(children_by_district$percent), 
                          main = "district by children", 
                          horiz = TRUE, 
                          names.arg = children_by_district$district, 
                          col = heat.colors(10), 
                          space = 0.1, cex.axis = 0.6, cex = 0.6, 
                          las = 1, xlim = c(0, 100)
                        )

text(10, children_plot, 
     labels = paste( children_by_district$percent, '%' ), 
     adj = c(0, 0.6), cex = 0.7)

dbDisconnect(con)
dbUnloadDriver(drv)
