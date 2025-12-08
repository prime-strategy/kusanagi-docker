<?php
$_SERVER['HTTP_HOST'] = 'fqdn';
define( 'SHORTINIT', true );
require_once( dirname( dirname( __FILE__ ) ) . '/DocumentRoot/wp-load.php' );

$url_path = '';
if ( isset($argv[1]) ) {
	$url_path = $argv[1];
}
$mode = '';
if ( isset($argv[2]) ) {
	$mode = $argv[2];
}

if ( defined( 'CACHE_DB_HOST' ) && defined( 'CACHE_DB_USER' ) && defined( 'CACHE_DB_PASSWORD' ) && defined( 'CACHE_DB_NAME' ) ) {
	$cachedb = new wpdb( CACHE_DB_USER, CACHE_DB_PASSWORD, CACHE_DB_NAME, CACHE_DB_HOST );
} else {
	$cachedb = $wpdb;
}

$ret = $cachedb->get_results( 'show tables', ARRAY_N );
foreach ($ret as $row) {
	$t = $row[0];
	if ( preg_match( '/site_cache$/', $t ) ) {
		if ($url_path) {
			if ( preg_match_all('#[^\x00-\x7F]#u', $url_path, $not_ascii_matches ) ) {
				foreach ( $not_ascii_matches[0] as $not_ascii) {
					$url_path = str_replace( $not_ascii, urlencode($not_ascii ), $url_path );
				}
			}
			$hashes = $cachedb->get_results( $cachedb->prepare("SELECT hash, device_url FROM $t WHERE device_url RLIKE %s", $url_path ));
			if ( $hashes ) {
				foreach ( $hashes as $hash ) {
					if ( $mode === '--dryrun' ) {
						echo sprintf( 'INFO: %s cache will be deleted', $hash->device_url ) . PHP_EOL;
					} else {
						if ( ! $mode ) {
							if ( $cachedb->query( $cachedb->prepare("DELETE FROM $t WHERE hash = %s", $hash->hash ) ) ) {
								echo sprintf( 'SUCCESS: %s cache could be deleted', $hash->device_url ) . PHP_EOL;
							} else {
								echo sprintf( 'FAILURE: %s cache could not be deleted', $hash->device_url ) . PHP_EOL;
							}
						} else {
							echo "cache clear path option only '--dryrun'" . PHP_EOL;
							exit(0);
						}
					}
				}
			}
		} else {
			$sql = 'truncate table `' . $cachedb->escape( $t, 'recursive' ) . '`';
			echo $sql ."\n";
			$cachedb->query( $sql );
		}
	}
}
