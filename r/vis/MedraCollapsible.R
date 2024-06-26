#______________________________________________________________________________
# FILE: MeddraCollapsible.R 
# DESC: MedDRA LT to SOC Collapsible tree POC using Stardog PATHS query
# SRC :
# IN  : Stardog graph MedDRA
# OUT : Display
# REQ : Stardog running, graph MedDRA populated with defined predicates
#       hasLT, hasPT, ..etc.
#       PATHS query (Stardog syntax alert!)
# SRC : 
# NOTE: Hard coded LT for this POC code.
#   Color range, lt Purple to Dark Purple
#   #E6E0EC
#   #CCC1DA
#   #B3A2C7
#   #604A7B
#   Docs: Collapsible tree Git Eg page: https://github.com/AdeelK93/collapsibleTree
#         CRAN PDF:  https://cran.r-project.org/web/packages/collapsibleTree/collapsibleTree.pdf
# TODO: 
#______________________________________________________________________________
library(SPARQL)
library(collapsibleTree)
library(dplyr)  # recode

setwd("C:/_github/CTDasRDF/r")
source("Functions.R")  # IRItoPrefix()

# Query StardogTriple Store ----
endpoint <- "http://localhost:5820/MedDRA/query"

query = paste0("PREFIX meddra: <https://w3id.org/phuse/meddra#>
               PATHS ALL
               START ?s = meddra:m10003047
               END ?o 
               VIA ?p   
               LIMIT 100" )

qd <- SPARQL(endpoint, query)
triplesDF <- qd$results

# Post query clean up
triplesDF <- triplesDF[complete.cases(triplesDF), ] # Remove blank rows. 
triplesDF <- triplesDF[, c("s", "p", "o")]          # Remove o.l, s.l artifacts
triplesDF <- unique(triplesDF)                      # Remove duplicates

# Shorten from IRI to qnam
triplesDF <- IRItoPrefix(sourceDF=triplesDF, colsToParse=c("s","p", "o"))

# Remove the prefix for this work.  TODO: Add option to IRItoPrefix() to 
#   provide this functionality.
triplesDF$o <- sub("meddra:|skos:", "", triplesDF$o)
triplesDF$s <- sub("meddra:|skos:", "", triplesDF$s)
triplesDF$p <- sub("meddra:|skos:", "", triplesDF$p)

# Only keep the triples that are relations within the MedDRA hierarchy
triplesRel <- subset(triplesDF, grepl("hasLT|hasPT|hasHLT|hasHLGT|hasSOC", triplesDF$p))
triplesRel$title <- triplesRel$o  # Node title is from 'o'

# Tree graph needs a root node with a missing S value. Note hard code here too.
#   Special case: "predicate" used to define type for 'o' node
rootNodeDF <- data.frame(s=NA,p="hasLT", o="M10003047", title="M10003047",
                         stringsAsFactors=FALSE)

# Add root node to df
triplesRel <- rbind(rootNodeDF, triplesRel)

# Re-order dataframe. The s,o must be the first two columns.
triplesRel<-triplesRel[c("s", "o", "p", "title")]

# Node color
triplesRel <- triplesRel %>%
  mutate(fillColor = recode(p,
  'hasLT'   = 'white' ,                     
  'hasPT'   = '#E6E0EC' ,
  'hasHLT'  = '#CCC1DA' ,
  'hasHLGT' = '#B3A2C7' ,
  'hasSOC'  = '#604A7B'
  ))

# Note type
triplesRel <- triplesRel %>%
  mutate(nodeType = recode(p,
  'hasLT'   = 'LT' ,                     
  'hasPT'   = 'PT' ,
  'hasHLT'  = 'HLT' ,
  'hasHLGT' = 'HLGT' ,
  'hasSOC'  = 'SOC'
))

# Get the prefLabel for each node
nodeLabel<- subset(triplesDF, grepl("prefLabel", triplesDF$p))
nodeLabel <- nodeLabel[,c(1,3)]        # Only the nec. columns
colnames(nodeLabel) <- c('o', 'label') # Rename for merge

# Merge the title back into the triplesRel df
treeDf <- merge(triplesRel, nodeLabel, by.x='o', by.y='o')

# Tooltip contains nodeType and label
treeDf$tooltip <- paste0( 
  '<b>',
  treeDf$nodeType,
  '</b><br>',
  treeDf$label
)

# Order df columns for plotting 
treeDf <- treeDf[c("s", "o", "p", "title", "fillColor", "nodeType", "label", "tooltip")]

# Sort to get the s=NA value at the top (required for tree plot)
treeDf <- treeDf %>% arrange(!is.na(s), s)

collapsibleTreeNetwork(
  treeDf,
  c("s", "o"),
  fill        = "fillColor",
  nodeSize    = NULL,         # All nodes same size
  tooltipHtml = "tooltip",
  width       = "100%",
  collapsed   = FALSE
)