#Origem Downloads

library(dplyr)
library(data.table)

setwd("C:\\Users\\jvoig\\Downloads")

tdp_origens <- fread("Analytics Tá de Pé - App Origens 20170814-20180522.csv")

colnames(tdp_origens) <- c("origem_midia", "cidade",
                           "usuarios", "novos_usuarios",
                           "sessoes", "duracao_media_sessao")

tdp_origens <- tdp_origens %>%
  filter(!is.na(origem_midia)) %>%
  mutate(novos_usuarios = round(novos_usuarios, 0),
         usuarios = round(usuarios, 0),
         sessoes = round(sessoes, 0))

glimpse(tdp_origens)

setwd("C:\\Users\\jvoig\\OneDrive\\Documentos\\tdp_impact")
save(tdp_origens, file= "tdp_origens.Rdata")
