<?php
$_SERVER['HTTP_HOST'] = 'fqdn';
define( 'SHORTINIT', true );
$ROOT_DIR = getenv ( 'ROOT_DIR' );
require_once( "../${ROOT_DIR}/wp-load.php' );

$url_path = '';
if ( isset($argv[1]) ) {
	$url_path = $argv[1];
}
$mode = '';
if ( isset($argv[2]) ) {
	$mode = $argv[2];
}

$ret = $wpdb->get_results( 'show tables', ARRAY_N );
foreach ($ret as $row) {
	$t = $row[0];
	if ( preg_match( '/site_cache$/', $t ) ) {
		if ($url_path) {
			if ( preg_match_all('#[^\x00-\x7F]#u', $url_path, $not_ascii_matches ) ) {
				foreach ( $not_ascii_matches[0] as $not_ascii) {
					$url_path = str_replace( $not_ascii, urlencode($not_ascii ), $url_path );
				}
			}
			$hashes = $wpdb->get_results( $wpdb->prepare("SELECT hash, device_url FROM $t WHERE device_url RLIKE %s", $url_path ));
			if ( $hashes ) {
				foreach ( $hashes as $hash ) {
					if ( $mode === '--dryrun' ) {
						echo sprintf( 'INFO: %s cache will be deleted', $hash->device_url ) . PHP_EOL;
					} else {
						if ( ! $mode ) {
							if ( $wpdb->query( $wpdb->prepare("DELETE FROM $t WHERE hash = %s", $hash->hash ) ) ) {
								echo sprintf( 'SUCCESS: %s cache could be deleted', $hash->device_url ) . PHP_EOL;
							} else {
								echo sprintf( 'FAILURE: %s cache could not be deleted', $hash->device_url ) . PHP_EOL;
							}
						} else {
							echo sprintf( "cache clear path option only '--dryrun'" ) . PHP_EOL;
							exit(0);
						}
					}
				}
			}
		} else {
			$sql = 'truncate table `' . $wpdb->escape( $t, 'recursive' ) . '`';
			echo $sql ."\n";
			$wpdb->query( $sql );
		}
	}
}

