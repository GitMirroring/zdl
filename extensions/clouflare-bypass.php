<?php
require __DIR__ . '/../cloudflare-bypass-master/src/autoload.php';

use CloudflareBypass\RequestMethod\CFStream;

$stream_cf_wrapper = new CFStream(array(
    'max_retries'   => 5,                       // How many times to try and get clearance?
    'cache'         => true,                   // Enable caching?
    'cache_path'    => '/tmp', // __DIR__ . '/cache',      // Where to cache cookies? (Default: system tmp directory)
    'verbose'       => true                     // Enable verbose? (Good for debugging issues - doesn't effect context)
));

// Get Example: 1
$opts = array(
    'http' => array(
        'method' => "GET",
        'header' => array(
            'accept: */*',       // required
            'host: ' . $argv[1], //'host: predb.me',    // required
            'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Safari/537.36'
        )
    )
);

//$url = "http://rockfile.co/0im6itoplnnn.html";
$url = $argv[2];

$ctx = $stream_cf_wrapper->contextCreate( $url, stream_context_create( $opts ) );

echo file_get_contents( $url, false, $ctx );
