# ----------------------- IMPORTING LIBRARIES ---------------------------------
import time
import json
import os
import undetected_chromedriver as uc
from bs4 import BeautifulSoup
import glob
import pandas as pd

# ----------------------- DOWNLOADING DATA ------------------------------------
output_folder = "results"
os.makedirs(output_folder, exist_ok=True)

options = uc.ChromeOptions()
driver = uc.Chrome(options=options, version_main=145)

try:
    # --- Step 1: Fetch page 1 to get total pageCount ---
    print("Fetching page 1 to determine total pages...")
    driver.get("https://www.givesendgo.com/api/v2/campaigns?page=1")
    time.sleep(3)

    soup = BeautifulSoup(driver.page_source, "html.parser")
    data = json.loads(soup.find("pre").text.strip())

    total_pages = data["_meta"]["pageCount"]
    print(f"Total pages: {total_pages}")

    # Save page 1
    with open(os.path.join(output_folder, "sitemap_page1.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"  → Saved page 1 ({len(data.get('items', []))} campaigns)")

    # --- Step 2: Scrape pages 2 through total_pages ---
    for page in range(2, total_pages + 1):
        url = f"https://www.givesendgo.com/api/v2/campaigns?page={page}"
        print(f"Fetching page {page}/{total_pages}...")
        driver.get(url)
        time.sleep(0.5)

        soup = BeautifulSoup(driver.page_source, "html.parser")
        pre = soup.find("pre")
        if not pre:
            print(f"No JSON on page {page}, stopping.")
            break

        try:
            data = json.loads(pre.text.strip())
        except json.JSONDecodeError as e:
            print(f"Failed to parse JSON on page {page}: {e}")
            break

        items = data.get("items", [])
        filename = os.path.join(output_folder, f"sitemap_page{page}.json")
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"  → Saved {len(items)} campaigns")

finally:
    driver.quit()

# ----------------------- COMBINING JSONS ------------------------------------
pattern = os.path.join(output_folder, "sitemap_page*.json")
files = sorted(glob.glob(pattern), key=lambda x: int(x.split("page")[1].split(".")[0]))
combined_campaigns = []
for file in files:
    with open(file, "r", encoding="utf-8") as f:
        combined_campaigns.extend(json.load(f).get("items", []))

combined_file = os.path.join(output_folder, "all_campaigns.json")
with open(combined_file, "w", encoding="utf-8") as f:
    json.dump({"items": combined_campaigns}, f, ensure_ascii=False, indent=2)

# ----------------------- SAVING AS CSV ------------------------------------
with open(combined_file, "r", encoding="utf-8") as f:
    df = pd.DataFrame(json.load(f).get("items", []))

csv_file = os.path.join(output_folder, "all_campaigns.csv")
df.to_csv(csv_file, index=False)
