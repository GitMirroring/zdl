<?php
$op = $_POST['op'];
//$op = $argv[1];
$filename = "./total_zdl_users.txt";

is_writable($filename) or die ("Il file " . $filename . " non è scrivibile");

if (!empty($op)) {
    $file = fopen($filename, "r") or die ("Fallimento apertura in lettura del file " . $filename);
    $total = fgets($file);
    if ($total == NULL) {
        $total = 0;
    }
    fclose($file);

    $file = fopen($filename, "w") or die ("Fallimento apertura in scrittura del file " . $filename);

    switch ($op) {
    case "set":
        $text = strval($total + 1);
        mail ("zoninoz@inventati.org", "zdl: " . $text, "Nuovo aggiornamento ZDL: gli utenti sono " . $text);
        break;
        
    case "get":
        $text = strval($total);
    }

    fwrite($file, $text) or die ("Fallimento scrittura del file " . $filename);    
    echo $text ."\n";
    
    fclose($file);
}

?>
