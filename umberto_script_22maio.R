## Conexão

library(RPostgreSQL)
library(dplyr)
library(readxl)

pg = dbDriver("PostgreSQL")

con = dbConnect(pg,
                user="read_only_user", password="pandoapps",
                host ="aag6rh5j94aivq.cxbz7geveept.sa-east-1.rds.amazonaws.com",
                port = 5432, dbname="ebdb")

alertas = dbGetQuery(con, "select * from inspections i")

## Quantos alertas recebemos ao longo de todo o período?

status_names <- data.frame("status" = 1:7, situacao = c("pending", "rejected", 
                                                        "accepted", "sent", 
                                                        "answered", "discarded", 
                                                        "concluídos"))

alertas %>%
  filter(created_at > 2017-08-14) %>%
  group_by(status) %>%
  summarise(alertas = n()) %>%
  left_join(status_names) %>%
  select(situacao, alertas)

# Alertas que foram feitos na época da exposição do grupo controle. 
# De acordo com levantamento feitona época, os Ids dos alertas eram 
# **364** e **181** :
  
tbl_alertas_enviados = dbGetQuery(con, "SELECT i.id AS id_alerta, i.status AS status_alerta, i.created_at AS data_envio_alerta, m.contact_id AS id_contato_mensagem, c.name AS orgao_contato, a.content AS conteudo_msg_resposta 
FROM inspections i
LEFT JOIN messages m ON i.id=m.inspection_id
LEFT JOIN contacts c ON m.contact_id=c.id
LEFT JOIN answers a ON m.id=a.message_id;")

tbl_alertas_controle <- tbl_alertas_enviados %>%
  filter(id_alerta == 364 | id_alerta == 181) %>%
  left_join(status_names, by=c("status_alerta" = "status"))

#Desculpa, não consegui resolver o encoding.

## Percurso dos alertas

tbl_alertas_enviados <- tbl_alertas_enviados %>%
  left_join(status_names, by=c("status_alerta" = "status"))
View(tbl_alertas_enviados)

# Nessa tabela, o orgao_contato indica o percurso que cada alerta fez. 
# Tem algum erro na API que eu não estou conseguindo ver o conteúdo de todas
# as respostas.


# Latitude e longitude das obras que estão no app

# Critérios para a obra aparecer no app: ela não pode estar concluída e nem cancelada
# Além disso ela deve ter um dos seguintes tipos de projetos conhecidos: 
# "Espaço Educativo - 12 Salas",
#"Espaço Educativo - 01 Sala",
# "Espaço Educativo - 02 Salas",
# "Espaço Educativo - 04 Salas",
# "Espaço Educativo - 06 Salas",
# "Projeto 1 Convencional",
# "Projeto 2 Convencional"




`%notin%` = function(x,y) !(x %in% y)

filtro_in_situacao <- c(3,9,1,4,7,6,8)
projects_status_names <- data.frame("status" = 1:9, situacao = c("execution",
                                                                 "done",
                                                                 "unfinished",
                                                                 "paralyzed",
                                                                 "work_canceled",
                                                                 "bidding",
                                                                 "hiring",
                                                                 "in_recasting",
                                                                 "planning_by_the_proponent"))
filtro_in_tipodeprojeto <- c(14,8,9,10,11,18,19) 
type_of_projects_names <- data.frame("type_of_projects" = 1:20,
                                     "tipos-de_projetos" = c( "enlargement",
                                                              "construction",
                                                              "school_with_project_prepared_by_grantor",
                                                              "school_with_project_prepared_by_the_proponent",
                                                              "type_a_kindergarten",
                                                              "type_b_kindergarten",
                                                              "type_c_kindergarten",
                                                              "educational_space_1_room",
                                                              "educational_space_2_room",
                                                              "educational_space_4_room",
                                                              "educational_space_6_room",
                                                              "educational_space_8_room",
                                                              "educational_space_10_room",
                                                              "educational_space_12_room",
                                                              "educational_background_high_school_vocational",
                                                              "mi_kindergarten_type_b",
                                                              "mi_kindergarten_type_c",
                                                              "conventional_design_1",
                                                              "conventional_design_2",
                                                              "renovation") )


# Vendo quais projetos estão no app e lat e long de todos
# Estou considerando apenas o filtro como definidor das obras no app, já que 
# os cronogramas começaram a ser inseridos no final de fevereiro de 2018


projects = dbGetQuery(con, "select * from projects;")

projects <- projects %>%
  mutate(visivel_no_app_mais_conluidas = ifelse(visible != "FALSE" & # FALSE == municipios controle
                                                  type_of_project != 5 &
                                   status %in% filtro_in_situacao, 1, 0 ),
         latitude = ifelse(is.na(official_lat), latitude, official_lat),
         longitude = ifelse(is.na(official_long), longitude, official_long)) %>%
  select(id, name, zipcode, city_id, latitude, longitude,
         visivel_no_app_mais_conluidas )
  

setwd("C:\\Users\\jvoig\\OneDrive\\Documentos\\tdp_impact\\arquivos_obras")
save(projects, file="projects.Rdata")

obras_08032018 <- fread("obras_08032018.csv", encoding = 'UTF-8')

# pedido informação para o FNDE:

concluidas_segundo_fnde <- read_excel("C:/Users/jvoig/OneDrive/Documentos/tdp_impact/arquivos_obras/Obrasconcluidas176599_1.xlsx", 
                                      col_types = c("text", "text", "date"))

save(concluidas_segundo_fnde, file= "concluidas_segundo_fnde.Rdata")
