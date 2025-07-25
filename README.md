# GiveSendGo Donations Scraper

A Python scraper designed to collect and consolidate donation data from a public GiveSendGo crowdfunding campaign. This project tracks donations, donor comments, names, timestamps, and amounts to analyze funding patterns, particularly those tied to far-right political fundraising.

## Motivation
On July 21, 2025, a fundraiser titled **“Fired for my Political Beliefs”** was launched by Connor Estelle on GiveSendGo, claiming they had been terminated for expressing political views. The campaign framed itself as an emergency fund to cover living expenses and resist what was termed “cancel culture.” The stated goal was to raise $15,000. Given the ties to broader right-wing movements, this project was created to systematically track and analyze donations to the campaign. The goal is to provide a transparent, data-driven look at the supporters behind this campaign and the nature of their contributions.

**Note**: This code can be used to scrape any all donations on any GiveSendGo campaign.

## Overview
1. Uses a `undetected_chromedriver` to simulate browser requests to GiveSendGo's internal API.
2. Iterates over multiple pages of donations.
3. Saves individual page responses as JSON.
4. Combines and converts all donations into a single CSV for analysis.

## Structure

```
├── donations_data/
│   ├── donations_page1.json
│   ├── ...
│   ├── all_donations.json
│   └── all_donations.csv
├── scraper.py
└── README.md
```
