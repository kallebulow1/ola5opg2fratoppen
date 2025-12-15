library(httr)
library(jsonlite)
library(dplyr)
library(RMariaDB)
library(purrr)
library(DBI)

###### KONFIG #######
zip_code        <- "4000"
target_store_id <- c("769204f1-d8e4-41fb-8b9c-0b8b8f885376",
                     "4d99a744-8087-44ff-b576-4bb0f6bb6ff4",
                     "e98ce884-e2fa-47d7-9cf9-d78d0fc2aa88")
api_token       <- "SG_APIM_C353C47PX656P7RDXYJJBP5458RB7AHY93RFNEJ7G8N6NC70V27G"

url <- paste0("https://api.sallinggroup.com/v1/food-waste/?zip=", zip_code)

res <- GET(
  url,
  add_headers(Authorization = paste("Bearer", api_token))
)
stopifnot(status_code(res) == 200)

raw <- content(res, "text", encoding = "UTF-8")

####### HENT OG FLET DATA #######

df  <- fromJSON(raw, flatten = TRUE)

# liste med tilbud pr. butik
offers <- df$clearances

# brug store.id som navn på hvert liste-element
names(offers) <- df$`store.id`

# skriv store_id ind som kolonne i hver offers-tabel
for (i in seq_along(offers)) {
  offers[[i]]$store_id <- names(offers)[i]
}

# bind alle tilbud sammen til én dataframe
df_offer <- dplyr::bind_rows(offers)
rownames(df_offer) <- NULL

# kun tilbud fra én butik
netto_roskilde <- df_offer %>%
  filter(store_id == target_store_id)

####### SQL CONNECTION #######

con_salling <- dbConnect(
  MariaDB(),
  host     = "13.53.212.244",
  dbname   = "Salling_store",
  user     = "dalremote",
  password = "Benja#1998"
)

####### SG_STORE – 1 række for butikken #######

df_stores <- df %>%
  filter(`store.id` %in% target_store_id) %>%
  transmute(
    store_id = `store.id`,
    brand    = store.brand,
    name     = store.name,
    type     = store.type,
    city     = store.address.city,
    country  = store.address.country,
    street   = store.address.street,
    zip      = store.address.zip
  ) %>%
  distinct()

dbWriteTable(
  con_salling,
  name      = "sg_store",
  value     = df_stores,
  overwrite = TRUE,
  row.names = FALSE
)

####### CLEARANCE_DATAFRAME – MED store_id + product_desc #######

clearance_df <- netto_roskilde %>%
  distinct() %>%
  mutate(
    across(
      where(is.list),
      ~ map_chr(.x, ~ jsonlite::toJSON(.x, auto_unbox = TRUE))
    ),
    offer_start = as.POSIXct(
      offer.startTime,
      format = "%Y-%m-%dT%H:%M:%OSZ",
      tz = "UTC"
    ),
    offer_end = as.POSIXct(
      offer.endTime,
      format = "%Y-%m-%dT%H:%M:%OSZ",
      tz = "UTC"
    ),
    last_update = as.POSIXct(
      offer.lastUpdate,
      format = "%Y-%m-%dT%H:%M:%OSZ",
      tz = "UTC"
    )
  ) %>%
  transmute(
    store_id,                       
    ean              = product.ean,
    currency         = offer.currency,
    new_price        = offer.newPrice,
    original_price   = offer.originalPrice,
    percent_discount = offer.percentDiscount,
    stock            = offer.stock,
    stock_unit       = offer.stockUnit,
    product_desc     = product.description,  # ← UDEN punktum
    offer_start,
    offer_end,
    last_update
  )

dbWriteTable(
  con_salling,
  name      = "clearance_offer",
  value     = clearance_df,
  append    = TRUE,
  row.names = FALSE
)