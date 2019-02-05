<?php
/*
Plugin Name: WP KUSANAGI
Plugin URI: http://en.kusanagi.tokyo/
Description: Page Cache, Translate Cache and Device Theme Switch for KUSANAGI.
Version: 1.0.25
Author: Prime Strategy Co.,LTD.
Author URI: http://www.prime-strategy.co.jp/
License: GPLv2 or later
English Translation: Odyssey Romanian Web Geeks
*/

require_once ( __DIR__ . '/kusanagi-core/core.php' );
$WP_KUSANAGI = new WP_KUSANAGI( __FILE__ );
