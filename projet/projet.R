library(readr)
library(dplyr)
library(ggplot2)
library(rworldmap)
library(corrplot)

# Chargement des données
countries <- read_csv("C:/Users/joris/OneDrive/Documents/Master/Semestre_2/SEP/projet/countries.csv", locale = locale(decimal_mark = ","))
View(countries)

# Suppression des colonnes les moins informatives
cols.dont.want <- c("Population", "Other (%)", "Climate", "Arable (%)", "Crops (%)", "Phones (per 1000)", "Area (sq. mi.)") 
data <- countries[, ! names(countries) %in% cols.dont.want, drop = F]
data

# Corrélation entre la migration et les autres variables
cor(subset(data, select=-c(1)), data["Net migration"], use="complete.obs")

# Remplacement des Na par la moyenne des colonnes
data[] <- lapply(data, function(x) { 
  x[is.na(x)] <- round(mean(x, na.rm = TRUE), 3)
  x
})
View(data)

# Dictionnaire de données
colnames(data) 

# Pays par région
data %>%
  select(Country, Region) %>%
  group_by(Region) %>%
  summarise(pays = n())


# Solde migratoire moyen par région
net_migration_per_region <- data %>%
  select(Country, Region, `Net migration`) %>%
  group_by(Region) %>%
  dplyr::summarize(Moyenne_migratoire=round(mean(`Net migration`), 2))

# histogramme
net_migration_per_region %>%
  collect() %>%
  ggplot(aes(x=reorder(Region, desc(Moyenne_migratoire)))) +
  scale_fill_gradient2(low="purple", high="green") +
  theme_dark() +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  geom_col(aes(x=Region, y=Moyenne_migratoire, fill=Moyenne_migratoire)) 
  
# Boîte à moustache
data %>%
  ggplot(aes(Region, `Net migration`)) +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  geom_boxplot() +
  stat_summary(fun.y=mean, colour="darkred", geom="point", 
               shape=18, size=3) + 
  geom_text(data = net_migration_per_region, 
            aes(label = Moyenne_migratoire, y = Moyenne_migratoire))


# world map
gtdMap <- joinCountryData2Map(data, nameJoinColumn="Country", 
                               joinCode="NAME")
mapDevice('x11')
mapParams <- mapCountryData(gtdMap, 
               nameColumnToPlot="Net migration", 
               catMethod=c(-30,-2,0,2,30), 
               colourPalette = brewer.pal(9, 'Spectral'),
               missingCountryCol = 'dark grey',
               numCats=9,
               oceanCol = 'light blue',
               addLegend = FALSE)
do.call( addMapLegend, c( mapParams
                          , legendLabels='all'
                          , legendWidth=0.5 ))
mtext("Gris: aucune donnée", 
      side = 1, 
      line = -1)

# Corrélation entre la migration et les autres vairables
correlation <- cor(data[,c(-1,-2,-5)], data[,5])
correlation
corrplot(correlation, type = 'full', cl.length = 9, cl.ratio = 1)


# Moyenne des variables (ordonnées par solde migratoire)
variables_mean <- data %>%
  select(-Country) %>%
  group_by(Region) %>%
  summarise_all(funs(mean)) %>%
  arrange(desc(`Net migration`))

View(variables_mean)

# Test d'indépendance
chisq.test(data$Region, data$`Net migration`)

# Test de Bartlett pour la migration par région
bartlett.test(data$`Net migration` ~ data$Region)

# Test ANOVA
oneway.test(data$`Net migration` ~ data$Region, var.equal = FALSE) 
