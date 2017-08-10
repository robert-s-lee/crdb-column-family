
require(ggplot2)
require(data.table)

files = list.files(pattern="*.csv")
DT = do.call(rbind, lapply(files, fread))
x <- subset(DT, threadName2 =="tblfam"| threadName2=="tblnofam")
ggplot(x,aes(x=threadName2,y=Latency))+geom_boxplot()+facet_grid (scenario ~ db)
ggsave("crdb-column-family.png")

