#______________________________________________________________________________
# FILE: r/vis/MedDRALTtoSOCVis-app/ui.R
# DESC: MedDRA visualization from LT to SOC 
# SRC :
# IN  : 
# OUT : 
# REQ : 
# SRC : 
# NOTE: 
# REF:  
# TODO: 
#______________________________________________________________________________
fluidPage(

  # Node selection
  fluidRow(
    column(6, 
      h4("MedDRA Tracing from Lowest Level Term (LLT) to System Organ Class(SOC)"),
      # textInput('rootNode', "LT value", value = "M10003047")
      selectInput("rootNode", "LLT :",
                  c("m10003047" = "m10003047",
                    "m10003058" = "m10003058",
                    "m10003851" = "m10003851",
                    "m10012727" = "m10012727"),
                  selected = "m10003047")
    )
  ),
  # Tree Diagram
  fluidRow(
    column(12, 
      wellPanel(
        collapsibleTreeOutput("medTree", width="100%", height="400px")
      )
    )
  )
)