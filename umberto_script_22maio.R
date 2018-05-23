## Conexão

library(RPostgreSQL)
library(dplyr)

pg = dbDriver("PostgreSQL")

con = dbConnect(pg,
                user="read_only_user", password=pass,
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