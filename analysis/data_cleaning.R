# Loading libraries
library(jsonlite)
library(tidyverse)
library(janitor)
library(clipr)

# Reading CSV
df <- read_csv("all_campaigns.csv.gz")

# Parsing JSON
safe_from_json <- function(x) {
  if (is.na(x) || is.null(x) || x == "") return(NULL)
  x <- as.character(x)
  x2 <- str_replace_all(x, "'", '"')
  x2 <- str_replace_all(x2, "\\bNone\\b", "null")
  x2 <- str_replace_all(x2, "\\bTrue\\b",  "true")
  x2 <- str_replace_all(x2, "\\bFalse\\b", "false")
  tryCatch(fromJSON(x2), error = function(e) NULL)
}

df_clean <- df %>%
  
  # Normalizing text in categorical variables
  mutate(across(
    c(
      campaign_name,
      campaign_country,
      campaign_state,
      campaign_type,
      campaign_add_byline,
      campaign_success_story,
      campaign_organization_name,
      campaign_organization_ein,
      campaign_organization_display_ein,
      received_by
    ),
    ~ str_squish(.x)
  )) %>%
  
  # Parsing JSON into lists
  mutate(
    donation_currency_parsed = map(donation_currency, safe_from_json),
    category_parsed = map(category, safe_from_json),
    created_by_parsed = map(created_by, safe_from_json),
    settings_parsed = map(settings, safe_from_json),
    galleryAll_parsed = map(galleryAll, safe_from_json),
    mailing_addresses_parsed = map(mailing_addresses, safe_from_json)
  ) %>%
  
  # Un-nesting JSONs
  unnest_wider(donation_currency_parsed, names_sep = "_") %>%
  unnest_wider(category_parsed, names_sep = "_") %>%
  unnest_wider(created_by_parsed, names_sep = "_") %>%
  unnest_wider(settings_parsed, names_sep = "_") %>%
  unnest_wider(galleryAll_parsed, names_sep = "_") %>%
  unnest_wider(mailing_addresses_parsed, names_sep = "_") %>%

  # fixing dates
  mutate(
    campaign_added_date = suppressWarnings(ymd_hms(campaign_added_date)),
    campaign_updated_date = suppressWarnings(ymd_hms(campaign_updated_date)),
    published_date = suppressWarnings(coalesce(
      ymd_hms(published_date),
      ymd(published_date)
    )),
    last_donation_time = suppressWarnings(ymd_hms(last_donation_time)),
    campaign_start = suppressWarnings(ymd(campaign_start))
  ) %>%
  
  # Binary variables
  mutate(across(
    c(
      campaign_enabled,
      campaign_payment_type,
      monthly_goal,
      is_published,
      allow_captcha,
      show_no_goal,
      campaign_verified,
      isCampaign,
      campaign_organization_display_ein,
      mailing_addresses,
      settings_parsed_hide_total_amount_raised,
      mailing_addresses,
      mailing_addresses_parsed_1,
      campaign_add_byline,
    ),
    ~ as.logical(as.integer(.x))
  )) %>%
  

  # Numeric fields
  mutate(across(
    c(
      campaign_goal_amount,
      campaign_total_amount,
      campaign_raised_value,
      donationProgressBar
    ),
    ~ suppressWarnings(as.numeric(.x))
  )) %>%
  
  # Cleaning HTML
  mutate(
    campaign_description = str_remove_all(campaign_description, "<[^>]+>"),
    plain_description = str_squish(plain_description)
  ) %>%
  
  select(-c(
    "composite_score",
    "campaign_start",
    "isCampaign",
    "is_published",
    "galleryAll_parsed_gallery_order",
    "donation_currency",
    "category",
    "created_by",
    "settings",
    "galleryAll"
  )) %>%
  
  clean_names() %>%
  mutate(
    page_url = paste0("https://www.givesendgo.com/",campaign_urllink),
    details_url = paste0("https://www.givesendgo.com/api/v2/incoming-requests/get-campaign-detail/",campaign_urllink),
    across(where(is.character), ~na_if(str_squish(.), ""))
    ) %>%
  select(
    # Identity
    name = campaign_name,
    url = campaign_urllink,
    page_url = page_url,
    details_url = details_url,
    description = campaign_description,
    description_plain = plain_description,
    success_story = campaign_success_story,
    type = campaign_type,
    category = category_parsed_campaign_category_name,
    category_slug = category_parsed_slug,
    
    # Dates
    date_created = campaign_added_date,
    date_published = published_date,
    date_updated = campaign_updated_date,
    date_last_donation = last_donation_time,
    
    # Location
    country = campaign_country,
    state = campaign_state,
    
    # Creator
    creator_name = created_by_parsed_createdby,
    creator_city = created_by_parsed_city,
    creator_org_name = created_by_parsed_campaign_organization_name,
    creator_org_ein = created_by_parsed_campaign_organization_ein,
    
    # Organization
    org_name = campaign_organization_name,
    org_ein = campaign_organization_ein,
    
    # Financial
    goal_amount = campaign_goal_amount,
    goal_label = campaign_goal_text,
    total_raised = campaign_total_amount,
    total_raised_label = campaign_total_text,
    monthly_raised_label = campaign_monthly_text,
    pct_raised = campaign_raised_value,
    progress_bar = donation_progress_bar,
    currency_code = donation_currency_parsed_currency_code,
    currency_character = donation_currency_parsed_currency_character,
    currency_symbol = donation_currency_parsed_currency_symbol,
    currency_symbol_recipient = donation_currency_parsed_currency_symbol_recipient,
    currency_code_recipient = donation_currency_parsed_currency_code_recipient,
    received_by,
    
    # Description & media
    header_image = campaign_header_image,
    youtube_url = campaign_youtube_url,
    video_type = campaign_video_type,
    gallery_image_url = gallery_all_parsed_image_url,
    gallery_youtube_url = gallery_all_parsed_youtube_url,
    
    # TRUE/FALSE flags
    is_enabled = campaign_enabled,
    is_payment_enabled = campaign_payment_type,
    is_captcha_allowed = allow_captcha,
    is_monthly_goal = monthly_goal,
    is_goal_hidden = show_no_goal,
    is_byline_added = campaign_add_byline,
    is_verified = campaign_verified,
    is_total_hidden = settings_parsed_hide_total_amount_raised,
    org_display_ein = campaign_organization_display_ein,
    mailing_address = mailing_addresses,
    mailing_address_parsed = mailing_addresses_parsed_1
  )
