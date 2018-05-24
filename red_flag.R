# State Capacity

library(readxl)
library(googlesheets)
library(dplyr)
library(janitor)

# 1. Planilha de contatos do TDP (com nomes mudados)

# url_contatos <- "https://docs.google.com/spreadsheets/d/1cxk1KUvncZ8SiavMmGkP4lYXjQ-7KD4corBjqkMjOxA/edit?usp=sharing"
# gs_ls() 
# contatos_sheet <- gs_title("TDP_Contatos_produção_nova")
# contatos_tdp <- contatos_sheet %>%
#   gs_read()
# save(contatos_tdp, file="contatos_tdp.Rdata")

load("contatos_tdp.Rdata")

# 2. Planilha dos contatos originais (retirada em 24/5/2018)

# obras_24052018 <- read.csv(url("http://simec.mec.gov.br/painelObras/download.php"), sep=";")
# save(obras_24052018, file="obras_24052018.Rdata")

load("obras_24052018.Rdata")

obras_24052018 <- obras_24052018 %>%
  clean_names() %>%
  select(municipio, uf, email) %>%
  distinct(email, .keep_all=TRUE) %>%
  rename(email_original = email)

glimpse(obras_24052018)

# Primeiro critério: provedor de email ser oficial 
# Obs: typos acabam aqui sendo considerados como proxy de baixa state capacity

provedores <- obras_24052018 %>%
  mutate(final = gsub(".*@","",email_original),
         final = tolower(final)) %>%
  select(final) %>%
  filter(!grepl("gov.br", final)) %>%
  filter(!grepl("gov.com.br", final)) %>%
  filter(!grepl("-rs.com.br", final)) %>%
  distinct(final, .keep_all=TRUE) # %>%
  # filter(final != "com.br" &
  #          final != ".com.br")

provedores_vector <- unique(provedores$final)

# Outro critério de red_flag é ser email de servidor, ainda que oficial:
# Vou marcar como redflag aqueles que não tem "gabinete", "secretaria" ou "sm"
# "prefeitura", "pm"
# (secretaria municipal)

criterio2 <- c("prefeitura", "secretaria", "gabinete")
criterio3 <- c("pm", "sm")


test <- obras_24052018 %>%
  mutate(inicio = gsub("@[[:graph:]]+","",email_original),
         red_flag2 = ifelse(inicio %in% criterio2, 1, 0),
         red_flag2 = ifelse(red_flag2 == 0 &
                              grepl("(pm|sm)", inicio), 0, 1)) 

test %>%
  group_by(red_flag2) %>%
  summarise( p =n())

result <- obras_24052018 %>%
  mutate(final = gsub(".*@","",email_original),
         final = tolower(final),
         red_flag = ifelse( final %in% provedores_vector, 1, 0),
         inicio = gsub("@[[:graph:]]+","",email_original),
         red_flag = ifelse( red_flag == 0 & 
                              inicio %in% criterio2, 0, 1),
         red_flag = ifelse(red_flag == 1 &
                                     grepl("(pm|sm)", inicio), 0, 1)) %>%
  select(municipio, uf, inicio, final, red_flag)

result %>%
  group_by(red_flag) %>%
  summarise( emails = n())

setwd("C:\\Users\\jvoig\\OneDrive\\Documentos\\tdp_impact")
save(result, file="red_flag_result.Rdata")
