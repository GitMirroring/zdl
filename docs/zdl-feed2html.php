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

    // foreach ($feed_info as $key => $value) {
    //     echo "<p>".$key." - ".$value."</p>";
    // }
    // echo "<hr />";
    // echo "<br />";echo "<br />";

    foreach ($feed_art as $key => $value) {
        echo "<p>Titolo: ".$value['titolo_articolo']."</p>";
        echo "<p>Descrizione: ".$value['descr_articolo']."</p>";
        echo "<p>Autore: ".$value['autore_articolo']."</p>";
        echo "<p>Data: ".$value['data_articolo']."</p>";
        echo "<p>Link: ".$value['link_articolo']."</p>";
        echo "<hr />";
    }

}

displayFeed("https://savannah.nongnu.org/news/atom.php?group=zdl");

?>
