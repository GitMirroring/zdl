<?php
// List of available localized versions as 'lang code' => 'url' map
$sites = array(
    "en" => "http://nongnu.org/zdl/en",
    "it" => "http://nongnu.org/zdl/it",
);

// Get 2 char lang code:
// $lang = substr($_SERVER['HTTP_ACCEPT_LANGUAGE'], 0, 2);

// Best parser:
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
if (!in_array($lang, array_keys($sites)))
    $lang = 'en';

// Finally redirect to desired location
header('Location: ' . $sites[$lang]);
?>
