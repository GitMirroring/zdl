#!/usr/bin/python3
# -*- coding: utf-8 -*-

print("Access-Control-Allow-Origin: *")
print("Content-Security-Policy: frame-ancestors *")
print("Content-Type: text/html; charset=utf-8\n")

import cgitb
cgitb.enable()

import urllib.request
import re
import sys
import ssl
import html
import os
from urllib.parse import parse_qs

if sys.version_info >= (3, 7):
    sys.stdout.reconfigure(encoding='utf-8')

# --- LOGICA DI SELEZIONE DELLA LINGUA (getLocaleParam) ---
# Legge il parametro ?origin= dall'URL (es. ?origin=http://nongnu.org)
query_string = os.environ.get('QUERY_STRING', '')
params = parse_qs(query_string)
origin_param = params.get('origin', [''])[0]

if "it" in origin_param:
    lang = "it"
else:
    lang = "en"

try:
    # Scarica il feed da Savannah
    FEED_URL = "https://savannah.nongnu.org/news/atom.php?group=zdl"
    req = urllib.request.Request(
        FEED_URL, 
        headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0'}
    )
    
    context_ssl = ssl._create_unverified_context()
    
    with urllib.request.urlopen(req, context=context_ssl, timeout=10) as response:
        raw_data = response.read()
    
    xml_text = raw_data.decode('utf-8', errors='ignore')
    
    # --- DISPLAY HEAD ---
    print(f"""<html lang="{lang}">
<head>
<title>ZigzagDownLoader (ZDL)</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="description" content="ZigzagDownLoader (ZDL)">
<meta http-equiv="Content-Security-Policy" content="upgrade-insecure-requests">
<link rel="stylesheet" type="text/css" href="https://www.nongnu.org/zdl/zdl_rss_style.css">
</head>
<body>""")

    # Link principale al gruppo Savannah
    # print("<a href='https://savannah.nongnu.org/news/?group_id=11047' target='_blank'>ZDL News</a>")

    # Isoliamo tutte le <entry>
    entries = re.findall(r'<entry\b.*?>(.*?)</entry>', xml_text, re.DOTALL)
    
    for entry in entries:
        # 1. Estrazione del Titolo grezzo
        title_match = re.search(r'<title\b.*?>(.*?)</title>', entry, re.DOTALL)
        raw_title = title_match.group(1).strip() if title_match else "Senza titolo"
        raw_title = html.unescape(raw_title)
        
        # 2. Estrazione del Link/ID dell'articolo
        id_match = re.search(r'<id\b.*?>(.*?)</id>', entry, re.DOTALL)
        link_articolo = id_match.group(1).strip() if id_match else "#"
        
        # 3. Estrazione della Data
        updated_match = re.search(r'<updated\b.*?>(.*?)</updated>', entry, re.DOTALL)
        data_articolo = updated_match.group(1).strip() if updated_match else ""
        
        # 4. Estrazione del Contenuto HTML (descr_articolo)
        content_match = re.search(r'<content\b.*?>(.*?)</content>', entry, re.DOTALL)
        descr_articolo = content_match.group(1).strip() if content_match else ""
        
        # --- FILTRO LINGUA (Stessa logica del tuo if/elseif PHP) ---
        mostra_articolo = False
        titolo_filtrato = raw_title
        
        prefix = f"[{lang}]"
        if raw_title.startswith(prefix):
            # Rimuove il prefisso [it] o [en] dal titolo
            titolo_filtrato = raw_title[len(prefix):].strip()
            mostra_articolo = True
        elif not re.match(r'^\[[a-z]{2}\]', raw_title):
            # Mostra l'articolo se non ha alcun prefisso di lingua internazionale
            mostra_articolo = True
            
        # --- PRINT ARTICOLO FORMATTATO ---
        if mostra_articolo:
            print("<hr />")
            print(f"<h3><a href='{link_articolo}' target='_blank'>{titolo_filtrato}</a></h3>")
            print(f"<p>{descr_articolo}</p>")
            print(f"<div class='feed_item_date'>Data: {data_articolo}</div>")
            
    # --- DISPLAY TAIL ---
    print("</body></html>")

except Exception as e:
    print(f"<html><body><p style='color:red;'>Errore: {e}</p></body></html>")
