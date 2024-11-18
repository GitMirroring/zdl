<?php
# ZigzagDownLoader (ZDL)
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published 
# by the Free Software Foundation; either version 3 of the License, 
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see http://www.gnu.org/licenses/. 
# 
# Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (author)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#

function getLocale () {
    $prefLocales = array_reduce(
        explode(',', $_SERVER['HTTP_ACCEPT_LANGUAGE']), 
        function ($res, $el) { 
            list($l, $q) = array_merge(explode(';q=', $el), [1]); 
            $res[$l] = (float) $q; 
            return $res; 
        }, 
        []);
    arsort($prefLocales);
    foreach($prefLocales as $key => $value) {
        if ($value == 1) {
            $lang = $key;
            break;
        }	
    }
    
    // Set default language if a `$lang` version of site is not available
    if ($lang !== "it" && $lang !== "en")
        $lang = 'en';
    return $lang;
}

function getLocaleReferer () {
    if (array_key_exists('HTTP_ORIGIN', $_SERVER)) {
        $origin = $_SERVER['HTTP_ORIGIN'];
    }
    else if (array_key_exists('HTTP_REFERER', $_SERVER)) {
        $origin = $_SERVER['HTTP_REFERER'];
    } else {
        $origin = $_SERVER['REMOTE_ADDR'];
    }
    $origin = $_SERVER['HTTP_REFERER'];

    return print_r($origin[0]);
    /* preg_match("/\/(it|en)\//", $origin, matches);   $lang = $matches[1]; */
    
    // Set default language if a `$lang` version of site is not available
    /* if ($lang !== "it" && $lang !== "en")        $lang = 'en';    return $lang; */    
}

function getLocaleParam () {
    return $_SERVER['HTTP_GET'];
}

function displayFeed($url){
    $getfile = html_entity_decode(file_get_contents($url));
    $lang = getLocaleReferer();

    $xml = new SimpleXMLElement($getfile);
    //$xml = simplexml_load_file($url);

    $feed_info = array();
    $feed_art = array();

    $feed_info['titolo_feed'] = $xml->title; 
    $feed_info['id_feed'] = $xml->id; 
    $feed_info['updated_feed'] = $xml->updated;

    // $feed_info['id_feed'] è l'url del feed, sostituito dalla pagina html di savannah
    echo "<a href='" . "https://savannah.nongnu.org/news/?group_id=11047" . "' target='_blank'>" . $feed_info['titolo_feed'] . "</a>";

    $i = 0; 
    foreach($xml->entry as $item)
    {
        if (preg_match('/^\[' . $lang . '\]/', $item->title)) {
            $feed_art[$i]['titolo_articolo'] = preg_replace('/^\[' . $lang. '\]\ /','', $item->title);
            $feed_art[$i]['descr_articolo'] = $item->content->asXML();
            $feed_art[$i]['autore_articolo'] = $item->author->name;
            $feed_art[$i]['data_articolo'] = $item->updated;
            $feed_art[$i]['link_articolo'] = $item->id;
            $i++;
        }
        elseif (!preg_match('/^\[[a-z]{2}\]/', $item->title)) {
            $feed_art[$i]['titolo_articolo'] = $item->title;
            $feed_art[$i]['descr_articolo'] = $item->content->asXML();
            $feed_art[$i]['autore_articolo'] = $item->author->name;
            $feed_art[$i]['data_articolo'] = $item->updated;
            $feed_art[$i]['link_articolo'] = $item->id;
            $i++;
        }            
    }

    $total = array_merge($feed_info,$feed_art);
    //print_r($total);

    foreach ($feed_art as $key => $value) {
        echo "<hr />";
        echo "<h3><a href='" . $value['link_articolo'] . "' target='_blank'>" . $value['titolo_articolo']."</a></h3>";
        echo "<p>" . $value['descr_articolo'] . "</p>";
        //echo "<p>by " . $value['autore_articolo'] . "</p>";
        echo "<div class='feed_item_date'>Data: ".$value['data_articolo']."</div>";
    }
}

function displayHead() {
    $header = "<html lang=\"it\">
<head>
<title>ZigzagDownLoader (ZDL)</title>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">
<meta name=\"description\" content=\"ZigzagDownLoader (ZDL)\">
<meta name=\"generator\" content=\"makeinfo 4.13\">
<meta http-equiv=\"Content-Security-Policy\" content=\"upgrade-insecure-requests\">
<link title=\"Top\" rel=\"start\" href=\"index.html#Top\">
<link rel=\"next\" href=\"Il-comando-ZDL.html#Il-comando-ZDL\" title=\"Il comando ZDL\">
<link href=\"https://www.gnu.org/software/texinfo/\" rel=\"generator-home\" title=\"Texinfo Homepage\">
<!--
ZigzagDownLoader (ZDL)

 This program is free software: you can redistribute it and/or modify it
 under the terms of the GNU General Public License as published
 by the Free Software Foundation; either version 3 of the License,
 or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see http://www.gnu.org/licenses/.

 Copyright (C) 2011
 Gianluca Zoni <<zoninoz@inventati.org>>

 For information or to collaborate on the project:
 `https://savannah.nongnu.org/projects/zdl'

 Gianluca Zoni (author)
 `https://inventati.org/zoninoz'
 <zoninoz@inventati.org>-->
<link rel=\"stylesheet\" type=\"text/css\" href=\"https://www.nongnu.org/zdl/zdl_rss_style.css\">
</head>
<body>";
          echo $header;
}

function displayTail() {
    echo "</body></html>";
}

//displayHead();
//displayFeed("https://savannah.nongnu.org/news/atom.php?group=zdl");
echo getLocaleParam();
//displayTail();

?>
