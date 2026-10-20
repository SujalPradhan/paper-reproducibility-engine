# Load and prepare plot ggplot settings 
# NOTE NOTE NOTE: Uncomment and use "font_import()" (below) the first time runnning this code

library(ggplot2)
library(extrafont)
# UNCOMMENT THIS firs time code is run: font_import()
loadfonts(device = "win")

#colour 
library(viridis)
library(colorspace)

# Graphics presets
allCol <- "black"
eeCol  <- "#a669b5"
llCol  <- "#90ba87"
eeFill <- eeCol %>% adjust_transparency(alpha=.50)
llFill <- llCol %>% adjust_transparency(alpha=.50)

output_height <- 600
output_width <- 1000

theme_ygrids =  theme(
  panel.grid.major.y=element_blank(),
  panel.grid.minor.y=element_blank(),
)

theme_xgrids =  theme(
  panel.grid.major.x=element_blank(),
  panel.grid.minor.x=element_blank(),
)

theme_nogrid =  theme(
  panel.grid = element_blank()
)

style_fontsize = 90

theme_print <- theme_bw() + theme(
  text = element_text(family="Roboto", size=style_fontsize),
  panel.grid.major = element_line(size=2),
  panel.grid.minor = element_line(size=2),
  legend.title=element_blank(),
  #legend.position = c(0.03,0.9),
  legend.position = "none",
  legend.background = element_rect(fill = "transparent", colour = "transparent"),
  legend.text = element_text(size=style_fontsize),
  legend.key.size = unit(.8,"cm"),
  legend.key = element_rect(fill = "transparent", colour = "transparent"),
  legend.justification = "left",
  plot.title = element_text(size=style_fontsize, hjust = 0),
  plot.subtitle = element_text(size=style_fontsize*0.85, hjust=0),
  axis.title = element_text(size=style_fontsize*0.85),
  axis.text = element_text(size=style_fontsize*0.85, color=allCol, margin=margin(2,2,2,2)),
  axis.text.x = element_text(margin = margin(t = 5)),
  axis.text.y = element_text(margin = margin(r = 5)),
  axis.ticks = element_line(size=4),
  axis.ticks.length=unit(.6, "cm"),
  panel.border = element_rect(size=5, fill="transparent", color=allCol),
  panel.background = element_rect(fill="transparent",colour=NA),
  plot.background = element_rect(fill="transparent",colour=NA),
  plot.margin=margin(120,120,120,120)
) %>% mdthemes::as_md_theme() + theme(legend.title=element_blank())

