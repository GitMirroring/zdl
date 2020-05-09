<?php
include(__DIR__ . "/../php-composer/vendor/autoload.php");
use CloudflareBypass\CFCurlImpl;
use CloudflareBypass\Model\UAMOptions;

/*
 * Prerequisites
 *
 * Set the following request headers:
 *
 * - Upgrade-Insecure-Requests
 * - User-Agent
 * - Accept
 * - Accept-Language
 *
 * Set the following options:
 *
 * - CURLINFO_HEADER_OUT    true
 * - CURLOPT_VERBOSE        false
 *
 */
$url = $argv[1];
if ($argv[2] !== '') {
    $post_data = $argv[2];
}
$ch = curl_init($url);

// Want to cache clearance cookies ?
curl_setopt($ch, CURLOPT_COOKIEJAR, "/tmp/cookies.txt");
curl_setopt($ch, CURLOPT_COOKIEFILE, "/tmp/cookies.txt");

curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLINFO_HEADER_OUT, true);
// curl_setopt($ch, CURLOPT_HTTPHEADER,
//             array(
//                 "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36",
//                 "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3",
//                 "Accept-Language: en-US,en;q=0.9",
//                 "Connection: keep-alive",
//                 "Upgrade-Insecure-Requests: 1",
//                 "TE: Trailers"
//             ));
curl_setopt($ch, CURLOPT_HTTPHEADER,
            array(
                "Upgrade-Insecure-Requests: 1",
                "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36",
                "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3",
                "Accept-Language: en-US,en;q=0.9"
            ));
if (isset($post_data)) {
    // curl_setopt($curlHandle, CURLOPT_CUSTOMREQUEST, "POST");
    // curl_setopt($curlHandle, CURLOPT_POSTFIELDS, $post_data);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
    curl_setopt($ch, CURLOPT_POSTFIELDS, $post_data);
}

$cfCurl = new CFCurlImpl();

$cfOptions = new UAMOptions();
$cfOptions->setVerbose(true);
// $cfOptions->setDelay(5);

try {
    // Want to get clearance cookies ?
    print_r ( curl_getinfo($ch, CURLINFO_COOKIELIST) );

    echo $cfCurl->exec($ch, $cfOptions); 
    echo curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
    
} catch (ErrorException $ex) {
    echo "Unknown error -> " . $ex->getMessage();
}

?>
