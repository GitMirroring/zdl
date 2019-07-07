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

function displayFeed($url){
    $getfile = html_entity_decode(file_get_contents($url));

    // echo $getfile;
    // exit;
    
    $xml = new SimpleXMLElement($getfile);
    //$xml = simplexml_load_file($url);

    $feed_info = array();
    $feed_art = array();

    $feed_info['titolo_feed'] = $xml->title; 
    $feed_info['id_feed'] = $xml->id; 
    $feed_info['updated_feed'] = $xml->updated;

    echo "<a href='" . $feed_info['id_feed'] . "' target='_blank'>" . $feed_info['titolo_feed'] . "</a>";

    $i = 0; 
    foreach($xml->entry as $item)
    {
        $feed_art[$i]['titolo_articolo'] = $item->title;
        $feed_art[$i]['descr_articolo'] = $item->content->asXML();
        $feed_art[$i]['autore_articolo'] = $item->author->name;
        $feed_art[$i]['data_articolo'] = $item->updated;
        $feed_art[$i]['link_articolo'] = $item->id;
        $i++;
    }

    $total = array_merge($feed_info,$feed_art);
    //print_r($total);

    foreach ($feed_art as $key => $value) {
        echo "<h3><a href='" . $value['link_articolo'] . "' target='_blank'>" . $value['titolo_articolo']."</a></h3>";
        echo "<p>" . $value['descr_articolo'] . "</p>";
        //echo "<p>by " . $value['autore_articolo'] . "</p>";
        echo "<div class='feed_item_date'>Data: ".$value['data_articolo']."</div>";
        echo "<hr />";
    }
}

function displayHead() {
    $header = "<html lang=\"it\">
<head>
<title>ZigzagDownLoader (ZDL)</title>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">
<meta name=\"description\" content=\"ZigzagDownLoader (ZDL)\">
<meta name=\"generator\" content=\"makeinfo 4.13\">
<link title=\"Top\" rel=\"start\" href=\"index.html#Top\">
<link rel=\"next\" href=\"Il-comando-ZDL.html#Il-comando-ZDL\" title=\"Il comando ZDL\">
<link href=\"http://www.gnu.org/software/texinfo/\" rel=\"generator-home\" title=\"Texinfo Homepage\">
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
 `http://inventati.org/zoninoz'
 <zoninoz@inventati.org>-->
<link rel=\"stylesheet\" type=\"text/css\" href=\"http://nongnu.org/zdl/zdl_rss_style.css\">
</head>
<body>";
          echo $header;
}

function displayTail() {
    echo "</body></html>";
}

displayHead();
displayFeed("https://savannah.nongnu.org/news/atom.php?group=zdl");
displayTail();

?>
