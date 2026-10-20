plo_temp <- tb_tempLog %>%
    filter(
      dateTime < ymd("2020 07 15"),
      tank %in% c(1:14),
      temp < 25
    ) %>% 
    mutate(day = floor_date(dateTime,unit="days")) %>%
    group_by(day) %>%
    summarise(temp=mean(temp)) %>%
    mutate(period = ifelse( day > ymd("2020 07 03"), "test", "holding")) %>%
    
    ggplot() +
    aes(x=day, y=temp, col=period)+
    geom_path(size=3, aes(group=1))+ 
    scale_color_manual(values=c("holding"="black","test"="#5494CD"))+
    labs(
      x="Month in 2020",
      title="Average daily water temperature",
      y="Temperature (°C)"
    )+
    axis_y(from=4,to=12,ticks=2)+
    scale_x_datetime(
      breaks = as.POSIXct(as.Date(c(
        "2020-03-15","2020-04-01",
        "2020-04-15","2020-05-01",
        "2020-05-15","2020-06-01",
        "2020-06-15","2020-07-01","2020-07-15"
      ))),
      labels = c("March","","April","","May","","June","","July")
    )+
    annotate("rect", 
             fill = "#5494CD", 
             alpha = 0.1, 
             xmin = as.POSIXct(ymd("2020-07-02")),
             xmax = as.POSIXct(ymd("2020-07-18")),
             ymin = -Inf, ymax = Inf
    )+
    annotate("text",
             label="Resp.",
             x = as.POSIXct(ymd("2020-07-01")), 
             y = 4.5,
             hjust=-0.1,
             size=25, 
             col="#5494CD"
    )


ggsave(
  plo_temp + theme_print + theme(
    legend.position="none",
    panel.grid.major.x=element_blank(),
    panel.grid.minor.x=element_blank(),
    axis.ticks.x=element_line(colour=c(NA,"black"))
  ), 
  filename = "plot - temp.png", 
  width=output_width*0.7, 
  height=output_height, 
  units="mm", 
  dpi=200,
  bg = "transparent",
)  

