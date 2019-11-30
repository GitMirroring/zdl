<?php
include(__DIR__ . "/autoload.php");
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
$url = "https://predb.me/?search=720p";
$ch = curl_init($url);

// Want to cache clearance cookies ?
//curl_setopt($ch, CURLOPT_COOKIEJAR, "cookies.txt");
//curl_setopt($ch, CURLOPT_COOKIEFILE, "cookies.txt");

curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLINFO_HEADER_OUT, true);
curl_setopt($ch, CURLOPT_HTTPHEADER,
    array(
        "Upgrade-Insecure-Requests: 1",
        "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36",
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3",
        "Accept-Language: en-US,en;q=0.9"
    ));

$cfCurl = new CFCurlImpl();

$cfOptions = new UAMOptions();
$cfOptions->setVerbose(true);
// $cfOptions->setDelay(5);

try {
    $page = $cfCurl->exec($ch, $cfOptions);
    echo $page;
    // Want to get clearance cookies ?
    //$cookies = curl_getinfo($ch, CURLINFO_COOKIELIST);

} catch (ErrorException $ex) {
    echo "Unknown error -> " . $ex->getMessage();
}



// require __DIR__ . '/../cloudflare-bypass-master/src/autoload.php';

// use CloudflareBypass\RequestMethod\CFStream;

// $stream_cf_wrapper = new CFStream(array(
//     'max_retries'   => 5,                       // How many times to try and get clearance?
//     'cache'         => true,                   // Enable caching?
//     'cache_path'    => '/tmp', // __DIR__ . '/cache',      // Where to cache cookies? (Default: system tmp directory)
//     'verbose'       => false                     // Enable verbose? (Good for debugging issues - doesn't effect context)
// ));

// $host = $argv[1];
// $url = $argv[2];
// if ($argv[3] !== '') {
//     $post_data = $argv[3];
// }

// if (isset($post_data)) {
//     $opts = array(
//         'http' => array(
//             'method' => "POST",
//             'header' => array(
//                 'Accept: */*',       // required
//                 'Host: ' . $host,    // required
//                 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Safari/537.36',
//                 "Content-type: application/x-www-form-urlencoded",
//                 "Content-Length: " . strlen($post_data)
//             ),
//             'content' => $post_data
//         )
//     );    
// }
// else {
//     $opts = array(
//         'http' => array(
//             'method' => "GET",
//             'header' => array(
//                 'Accept: */*',       // required
//                 'Host: ' . $host,    // required
//                 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Safari/537.36',
//                 'Upgrade-Insecure-Requests: 1'                
//             )
//         )
//     );
// }

// $ctx = $stream_cf_wrapper->contextCreate( $url, stream_context_create( $opts ) );

// echo file_get_contents( $url, false, $ctx );

?>
