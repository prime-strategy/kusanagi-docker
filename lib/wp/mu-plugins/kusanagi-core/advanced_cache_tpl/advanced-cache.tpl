<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}
if ( is_admin() ) {
	return;
}

// phpcs:disable WordPress.DB.RestrictedFunctions
class SiteManagerAdvancedCache {
	private $device_regexes = array(
	### DEVICE REGEX ###
	);
	private $sites = array(
	### SITES ARRAY ###
	);
	private $allowed_query_keys;
	private $site_mode               = ### SITE MODE ###;
	private $theme_switcher_disabled = ### THEME SWITCHER DISABLED ###;
	private $replace_class_file;

	public function __construct() {
		global $table_prefix;
		$this->replace_class_file = WP_CONTENT_DIR . '/replace-class.php';
		if ( ! isset( $_SERVER['REQUEST_URI'] ) || ! isset( $_SERVER['HTTP_USER_AGENT'] ) || ! isset( $_SERVER['REQUEST_METHOD'] ) || ! isset( $_SERVER['SCRIPT_NAME'] ) || ! isset( $_SERVER['SERVER_NAME'] ) ) {
			return; }
		if ( ! isset( $_SERVER['REQUEST_METHOD'] ) || 'GET' !== $_SERVER['REQUEST_METHOD'] ) {
			return; }
		if ( defined( 'CACHE_EXCLUDE_IP' ) ) {
			$exclude_ips = explode( '|', CACHE_EXCLUDE_IP );
			foreach ( $exclude_ips as $exclude_ip ) {
				if ( $_SERVER['REMOTE_ADDR'] === $exclude_ip || preg_match( '/' . preg_quote( $exclude_ip, '/' ) . '/', $_SERVER['REMOTE_ADDR'] ) ) {
					return;
				}
			}
		}
		if ( defined( 'CACHE_EXCLUDE_GET' ) && isset( $_GET[ CACHE_EXCLUDE_GET ] ) ) {
			return;
		}
		foreach ( array_keys( $_COOKIE ) as $key ) {
			if ( 0 === strpos( $key, 'wordpress_logged_in_' ) || 0 === strpos( $key, 'comment_author_' ) ) {
				return;
			}
		}
		### QUERY KEYS ###

		switch ( $this->site_mode ) {
			case 'domain':
				$add_prefix               = isset( $this->sites[ $_SERVER['SERVER_NAME'] ] ) && 1 !== $this->sites[ $_SERVER['SERVER_NAME'] ] ? $this->sites[ $_SERVER['SERVER_NAME'] ] . '_' : '';
				$site_id                  = isset( $this->sites[ $_SERVER['SERVER_NAME'] ] ) ? $this->sites[ $_SERVER['SERVER_NAME'] ] : '';
				$table                    = $table_prefix . $add_prefix;
				$this->replace_class_file = WP_CONTENT_DIR . '/replace-class-' . $site_id . '.php';
				break;
			case 'directory':
				$key = '/';
				if ( trim( $_SERVER['REQUEST_URI'], '/' ) ) {
					$dirs = explode( '/', trim( $_SERVER['REQUEST_URI'], '/' ), 2 );
					$key .= array_shift( $dirs ) . '/';
					unset( $dirs );
				}
				$add_prefix               = isset( $this->sites[ $key ] ) && 1 !== $this->sites[ $key ] ? $this->sites[ $key ] . '_' : '';
				$site_id                  = isset( $this->sites[ $key ] ) ? $this->sites[ $key ] : BLOG_ID_CURRENT_SITE;
				$table                    = $table_prefix . $add_prefix;
				$this->replace_class_file = WP_CONTENT_DIR . '/replace-class-' . $site_id . '.php';
				break;
			default:
				$table   = $table_prefix;
				$site_id = '';
		}
		### REGEX INCLUDE ###

		if ( $this->theme_switcher_disabled || ( ! $group = $this->get_device_group() ) ) {
			$group = '';
		}
		if ( ( isset( $_SERVER['HTTPS'] ) && 'on' === $_SERVER['HTTPS'] ) || ( isset( $_SERVER['X-Forwarded-Proto'] ) && 'https' === $_SERVER['X-Forwarded-Proto'] ) ) {
			$protocol = 'https';
		} else {
			$protocol = 'http';
		}

		$requerst_query = '';
		$request_uri    = parse_url( $_SERVER['REQUEST_URI'] );
		if ( isset( $request_uri['query'] ) ) {
			parse_str( $request_uri['query'], $requerst_query );

			foreach ( $requerst_query as $key => $var ) {
				if ( ! in_array( $key, $this->allowed_query_keys, true ) ) {
					unset( $requerst_query[ $key ] );
				}
			}
			ksort( $requerst_query );
			$requerst_query = http_build_query( $requerst_query );
		}

		if ( $requerst_query ) {
			$request_uri = $request_uri['path'] . '?' . $requerst_query;
		} else {
			$request_uri = $request_uri['path'];
		}

		$device_url = array(
			$group,
			$protocol,
			$_SERVER['SERVER_NAME'],
			$request_uri,
		);
		$device_url = implode( '|', $device_url );
		$hash       = md5( $device_url );

		$now    = gmdate( 'Y-m-d H:i:s' );
		$expire = gmdate( 'Y-m-d H:i:s', time() - 30 );

		if ( defined( 'CACHE_DB_NAME' ) && defined( 'CACHE_DB_USER' ) && defined( 'CACHE_DB_PASSWORD' ) && defined( 'CACHE_DB_HOST' ) ) {
			$dbset = array(
				'host' => CACHE_DB_HOST,
				'user' => CACHE_DB_USER,
				'pass' => CACHE_DB_PASSWORD,
				'name' => CACHE_DB_NAME,

			);
		} else {
			$dbset = array(
				'host' => DB_HOST,
				'user' => DB_USER,
				'pass' => DB_PASSWORD,
				'name' => DB_NAME,

			);
		}

		$dbh = mysqli_connect(
			$dbset['host'],
			$dbset['user'],
			$dbset['pass'],
			$dbset['name']
		);
		if ( false === $dbh ) {
			return; }
		if ( function_exists( 'mysqli_set_charset' ) ) {
			mysqli_set_charset( $dbh, DB_CHARSET );
		} else {
			$sql = 'set names ' . DB_CHARSET;
			mysqli_query( $dbh, $sql );
		}
		mysqli_select_db( $dbh, $dbset['name'] );

		$sql = "
SELECT	*
FROM	{$table}site_cache
WHERE	`hash` = '$hash'
AND		`expire_time` >= '$expire'
";
		$ret = mysqli_query( $dbh, $sql );

		if ( $ret ) {
			while ( $row = mysqli_fetch_object( $ret ) ) {
				if ( $device_url === $row->device_url && ( false !== strpos( $row->content, '<!-- page cached by KUSANAGI. ' ) || false !== strpos( $row->content, '<!-- page cached by WP SiteManager. ' ) ) ) {
					if ( $row->expire_time < $now ) {
						if ( ! $row->updating ) {
							$sql = "
UPDATE  {$table}site_cache
SET     `updating` = 1
WHERE   `hash` = '$hash'
AND     `type` = '{$row->type}'
AND     `expire_time` = '{$row->expire_time}'
";
							mysqli_query( $dbh, $sql );
							break;
						}
					}
					$headers = unserialize( $row->headers );
					if ( $headers ) {
						foreach ( $headers as $key => $header ) {
							header( $key . ': ' . $header );
						}
					}
					if ( $row->updating ) {
						header( 'Cache-Control: no-cache' );
						header( 'X-B-Cache: updating' );
					} else {
						header( 'X-B-Cache: cache' );
					}
					if ( is_readable( $this->replace_class_file ) ) {
						require_once $this->replace_class_file;
						$row->content = KUSANAGI_Replace::replace( $row->content );
					}

					if ( 'rest_api' === $row->type ) {
						header( 'X-cache-ID: ' . $row->hash );
						// phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
						echo $row->content;
					} else {
						// phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
						echo $row->content;
						// phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
						echo "\n" . '<!-- CacheID : ' . $row->hash . ' -->';
					}
					exit;
				}
			}
		}
		mysqli_close( $dbh );
	}


	public function get_device_group() {
		$path = preg_replace( '#^' . str_replace( '\\', '/', $_SERVER['DOCUMENT_ROOT'] ) . '#', '', str_replace( '\\', '/', ABSPATH ) );

		if ( isset( $_GET['site-view'] ) ) {
			if ( strtolower( 'pc' === $_GET['site-view'] ) ) {
				setcookie( 'site-view', 'pc', 0, $path );
				return false;
			}
			foreach ( $this->device_regexes as $group => $regex ) {
				if ( strtolower( sanitize_text_field( $_GET['site-view'] ) ) === strtolower( $group ) ) {
					setcookie( 'site-view', $group, 0, $path );
					return $group;
				}
			}
		} elseif ( isset( $_COOKIE['site-view'] ) ) {
			if ( 'pc' === strtolower( $_COOKIE['site-view'] ) ) {
				setcookie( 'site-view', 'pc', 0, $path );
				return false;
			}
			foreach ( $this->device_regexes as $group => $regex ) {
				if ( strtolower( $group ) === strtolower( $_COOKIE['site-view'] ) ) {
					setcookie( 'site-view', $group, 0, $path );
					return $group;
				}
			}
		}

		foreach ( $this->device_regexes as $group => $regex ) {
			if ( preg_match( $regex, $_SERVER['HTTP_USER_AGENT'] ) ) {
				return $group;
			}
		}
		return false;
	}
}
new SiteManagerAdvancedCache();
