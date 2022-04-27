# Check if need to install rvest` library
require("rvest")

library(rvest)

# Extract bike sharing systems HTML table from a wiki page
# and convert it into a data frame
url <- "https://en.wikipedia.org/wiki/List_of_bicycle-sharing_systems"

# Get the root HTML node by calling the `read_html()` method with URL
root_node <- read_html(url)

table_nodes <- html_nodes(root_node, "table")
table_nodes

# Convert the bike-sharing system table into a dataframe
df <- html_table(table_nodes[[3]], fill = TRUE)
head(df)

# Summarize the dataframe
summary(df)


# Export the dataframe into a csv file
write.csv(df,"C:\\Users\\Jack's PC\\Documents\\Coursera\\IBM Data Analytics\\Capstone\\raw_bike_sharing_systems.csv", row.names = FALSE)