<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class KUSANAGI_Page_Cache {

	private $cache_dir;
	private $advance_cache_tpl;
	private $regex_include_tpl;
	private $headers = array();

	public function __construct() {
		global $cache_db, $wpdb, $table_prefix;
		$this->advance_cache_tpl = plugin_dir_path( dirname( __FILE__ ) ) . 'advanced_cache_tpl/advanced-cache.tpl';
		$this->regex_include_tpl = plugin_dir_path( dirname( __FILE__ ) ) . 'advanced_cache_tpl/regex_include.tpl';
		$this->replace_tpl       = plugin_dir_path( dirname( __FILE__ ) ) . 'advanced_cache_tpl/replace-class.tpl';

		if ( defined( 'CACHE_DB_NAME' ) && defined( 'CACHE_DB_USER' ) && defined( 'CACHE_DB_PASSWORD' ) && defined( 'CACHE_DB_HOST' ) ) {
			$cache_db = new wpdb( CACHE_DB_USER, CACHE_DB_PASSWORD, CACHE_DB_NAME, CACHE_DB_HOST );
			$cache_db->set_prefix( $table_prefix );
		} else {
			$cache_db = $wpdb;
		}
		if ( defined( 'WP_INSTALLING' ) && WP_INSTALLING ) {
			add_action( 'wp_install'                               , array( $this, 'generate_advanced_cache_file' ), 11 );
		} else {
			if ( is_admin() ) {
				add_action( 'theme_switcher/device_updated'        , array( $this, 'generate_advanced_cache_file' ) );
				add_action( 'theme_switcher/device_group_updated'  , array( $this, 'generate_advanced_cache_file' ) );
				add_action( 'theme_switcher/theme_switcher_disable', array( $this, 'generate_advanced_cache_file' ) );

				add_action( 'transition_post_status'               , array( $this, 'post_publish_clear_cache' ), 10, 3 );
				add_action( 'admin_init'                           , array( $this, 'add_tab' ) );
				add_action( 'admin_menu'                           , array( $this, 'add_cache_control_hook' ), 9999 );
			} else {
				add_action( 'init'                                 , array( $this, 'buffer_start' ) );
				add_filter( 'wp_headers'                           , array( $this, 'add_b_cache_header' ) );
			}
			add_action( 'init'                                     , array( $this, 'check_installed' ) );
			add_action( 'wpmu_new_blog'                            , array( $this, 'ms_create_cache_table' ) );
		}
	}


	public function check_installed() {
		$version = get_option( 'site_manager_cache_installed', false );
		if ( ! $version ) {
			$this->create_cache_table();
			$this->generate_advanced_cache_file();
		} elseif ( $version < 2 ) {
			$this->update_cache_table( 2 );
			$this->update_cache_table( 3 );
			$this->update_cache_table( 4 );
		} elseif ( $version < 3 ) {
			$this->update_cache_table( 3 );
			$this->update_cache_table( 4 );
		} elseif ( $version < 4 ) {
			$this->update_cache_table( 4 );
		}
	}


	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'page-cache', __( 'Page Cache', 'wp-kusanagi' ) );
	}


	public function ms_create_cache_table( $blog_id ) {
		switch_to_blog( $blog_id );
		$this->create_cache_table();
		$this->generate_advanced_cache_file();
		restore_current_blog();
	}

	private function create_cache_table() {
		global $cache_db;

		$charset_collate = $cache_db->get_charset_collate();
		$sql = "
CREATE TABLE `{$cache_db->prefix}site_cache` (
 `hash` varchar(32) NOT NULL,
 `content` longtext NOT NULL,
 `device_url` text NOT NULL,
 `type` varchar(20) NOT NULL,
 `post_type` varchar(200) NOT NULL,
 `headers` text NOT NULL,
 `user_agent` text NOT NULL,
 `server` varchar(16) NOT NULL,
 `updating` tinyint(1) NOT NULL DEFAULT '0',
 `create_time` datetime NOT NULL,
 `expire_time` datetime NOT NULL,
 KEY `hash` (`hash`),
 KEY `expire_time` (`expire_time`),
 KEY `type` (`type`,`post_type`),
 KEY `updating` (`updating`)
) $charset_collate";

		$cache_db->query( $sql );

		$sql = "SHOW TABLES FROM `{$cache_db->dbname}` LIKE '{$cache_db->prefix}site_cache'";
		$table_exists = $cache_db->get_var( $sql );
		if ( $table_exists ) {
			update_option( 'site_manager_cache_installed', 3 );
		}
	}


	private function update_cache_table( $db_version ) {
		global $cache_db;
		switch ( $db_version ) {
			case 2 :
				$sql = "
ALTER TABLE `{$cache_db->prefix}site_cache`
ADD			`user_agent` TEXT NOT NULL AFTER `headers` ,
ADD			`server` VARCHAR( 16 ) NOT NULL AFTER `user_agent`";
				$cache_db->query( $sql );
				update_option( 'site_manager_cache_installed', 2 );
				break;
			case 3 :
				$sql = "
ALTER TABLE `{$cache_db->prefix}site_cache`
ADD			 `updating` BOOLEAN NOT NULL DEFAULT '0' AFTER `server` ,
ADD INDEX	( `updating` )";
				$cache_db->query( $sql );
				$sql = "ALTER TABLE `{$cache_db->prefix}site_cache` DROP PRIMARY KEY";
				$cache_db->query( $sql );
				$sql = "ALTER TABLE `{$cache_db->prefix}site_cache` ADD INDEX ( `hash` )";
				$cache_db->query( $sql );
				update_option( 'site_manager_cache_installed', 3 );
				$this->generate_advanced_cache_file();
				break;
			case 4 :
				$sql = "
ALTER TABLE `{$cache_db->prefix}site_cache`
MODIFY		`type` VARCHAR( 20 )";
				$cache_db->query( $sql );
				update_option( 'site_manager_cache_installed', 4 );
				break;
			default :
		}
	}


	public function save_options() {
		global $WP_KUSANAGI;

		$life_time = get_option( 'site_cache_life', array( 'home' => 60, 'archive' => 60, 'singular' => 360, 'exclude' => '', 'allowed_query_keys' => '', 'update' => 'none', 'replaces' => array(), 'replace_login' => 0 ) );

		if ( isset( $_POST['site_cache_life'] ) && is_array( $_POST['site_cache_life'] ) ) {
			$settings = array();
			$post_data = wp_unslash( $_POST );
			foreach ( $post_data['site_cache_life'] as $key => $minutes ) {
				if ( ! in_array( $key, array( 'exclude', 'allowed_query_keys', 'update', 'replaces' ) ) ) {
					if ( function_exists( 'mb_convert_kana' ) ) {
						$minutes = mb_convert_kana( $minutes, 'n', 'UTF-8' );
					}
					$minutes = preg_replace( '/[\D]/', '', $minutes );
					$minutes = absint( $minutes );
				} else {
					$minutes = trim( $minutes );
				}
				$settings[$key] = $minutes;
			}
			$settings['replaces'] = $life_time['replaces'];

			$ret = update_option( 'site_cache_life', $settings );
			if ( $ret ) {
				$this->generate_advanced_cache_file();
				$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
			}
		}
	}


	public function add_cache_control_hook() {
		global $WP_KUSANAGI;
		add_action( 'load-' . $WP_KUSANAGI->menu_slug, array( $this, 'cache_control' ) );
	}


	public function cache_control() {
		if ( isset( $_GET['del_cache'] ) && $_GET['del_cache'] == '1' && apply_filters( 'allow_sitemanager_cache_clear', true ) ) {
			$this->clear_all_cache();
			$redirect = remove_query_arg( 'del_cache' );
			wp_redirect( $redirect );
			exit;
		}

		if ( isset( $_GET['generate_advanced_cache'] ) && $_GET['generate_advanced_cache'] == '1' && apply_filters( 'allow_generate_advanced_cache', true ) ) {
			$this->generate_advanced_cache_file();
			$redirect = remove_query_arg( 'generate_advanced_cache' );
			wp_redirect( $redirect );
			exit;
		}
	}


	public function is_writable_advanced_cache_file() {
		$writable = false;
		if ( file_exists( WP_CONTENT_DIR . '/advanced-cache.php' ) ) {
			if ( is_writable( WP_CONTENT_DIR . '/advanced-cache.php' ) ) {
				$writable = true;
			}
		} else {
			if ( is_writable( WP_CONTENT_DIR ) ) {
				$writable = true;
			}
		}
		return $writable;
	}


	public function check_advanced_cache_file() {
		if ( file_exists( WP_CONTENT_DIR . '/advanced-cache.php' ) ) {
			if ( is_readable( WP_CONTENT_DIR . '/advanced-cache.php' ) ) {
				$file_content = file_get_contents( WP_CONTENT_DIR . '/advanced-cache.php' );
				if ( strpos( $file_content, 'class SiteManagerAdvancedCache {' ) === false ) {
					return new WP_Error( 'cache-file-error', 'advanced-cache.phpは存在していますが、KUSANAGIのものとは異なっています。' );
				}
			} else {
				return new WP_Error( 'cache-file-error', 'advanced-cache.phpに読み込み権限がありません。' );
			}
		} else {
			return new WP_Error( 'cache-file-error', 'advanced-cache.phpが存在していません。' );
		}
		return true;
	}


	public function buffer_start() {
		if ( isset( $_SERVER['REQUEST_URI'] ) && isset( $_SERVER['HTTP_USER_AGENT'] ) && isset( $_SERVER['REQUEST_METHOD'] ) && isset( $_SERVER['SCRIPT_NAME'] ) && isset( $_SERVER['SERVER_NAME'] ) ) {
			ob_start( 'kusanagi_write_page_cache' );
		}
	}


	private function clear_all_cache() {
		global $cache_db;
		$sql = "TRUNCATE TABLE `{$cache_db->prefix}site_cache`";
		$cache_db->query( $sql );
	}


	private function clear_front_cache() {
		global $cache_db;
		$sql = "
DELETE
FROM	`{$cache_db->prefix}site_cache`
WHERE	`type` = 'front'
";
		$cache_db->query( $sql );
	}


	private function clear_single_cache( $post ) {
		global $cache_db;

		$regexes = get_option( 'sitemanager_device_rules', array() );
		$groups = array_keys( $regexes );
		$groups = array_merge( array( '' ), $groups );

		$permalink = get_permalink( $post->ID );
		$permalink = parse_url( $permalink );
		$path = $permalink['path'];
		if ( isset( $permalink['query'] ) && $permalink['query'] ) {
			$path .= '?' . $permalink['query'];
		}

		$hashes = array();
		foreach ( $groups as $group ) {
			$device_url = array(
				$group,
				$permalink['scheme'],
				$permalink['host'],
				$path
			);
			$device_url = implode( '|', $device_url );
			$hashes[] = md5( $device_url );
		}
		$hashes = implode( "', '", $hashes );

		$sql = "
DELETE
FROM	`{$cache_db->prefix}site_cache`
WHERE	`type` = 'single'
AND		`hash` IN ( '{$hashes}' )
";
		$cache_db->query( $sql );
	}


	public function post_publish_clear_cache( $new_status, $old_status, $post ) {
		if ( $new_status == 'publish' ) {
			$life_time = get_option( 'site_cache_life', array( 'update' => 'none' ) );
			switch ( $life_time['update'] ) {
				case 'with-front' :
					$this->clear_front_cache();
				case 'single' :
					$this->clear_single_cache( $post );
					break;
				case 'all' :
					$this->clear_all_cache();
					break;
				case 'none' :
				default :
			}
		}
	}


	private function transition_comment_status( $new_status, $old_status, $comment ) {
		if ( $new_status == 'approved' || $old_status == 'approved' ) {
			$this->clear_all_cache();
		}
	}


	private function new_comment( $comment_ID, $approved ) {
		if ( $approved === 1 ) {
			$this->clear_all_cache();
		}
	}


	public function add_b_cache_header( $headers ) {
		$headers['X-B-Cache'] = 'BYPASS';
		return $headers;
	}


	public function generate_advanced_cache_file() {
		global $wpdb, $wp;

		$advanced_cache_file = WP_CONTENT_DIR . '/advanced-cache.php';

		if ( file_exists( $advanced_cache_file ) && is_writable( $advanced_cache_file ) || is_writable( WP_CONTENT_DIR ) ) {

			if ( file_exists( $this->advance_cache_tpl ) && is_readable( $this->advance_cache_tpl ) ) {
				$life_time = get_option( 'site_cache_life', array( 'home' => 60, 'archive' => 60, 'singular' => 360, 'exclude' => '', 'allowed_query_keys' => '', 'update' => 'none', 'replaces' => array(), 'replace_login' => 0 ) );
				$advanced_cache_data = file_get_contents( $this->advance_cache_tpl );

				$device_regexes = '';
				$regexes = get_option( 'sitemanager_device_rules', array() );
				$theme_switcher_disabled = get_option( 'theme_switcher_disable', 0 ) ? 'true' : 'false';
				foreach ( $regexes as $group => $arr ) {
					$regex = '/' . implode( '|', $arr['regex'] ) . '/';
					$device_regexes .= "\t\t'" . $group . "' => '" . $regex . "',\n";
				}

				$allowed_query_keys = trim( $life_time['allowed_query_keys'] );
				if ( $allowed_query_keys ) {
					$allowed_query_keys = wp_slash( $allowed_query_keys );
					$allowed_query_keys = preg_split( '/[\s]+/', $allowed_query_keys );
					$allowed_query_keys = array_unique( array_merge( $wp->public_query_vars, $allowed_query_keys ) );
				} else {
					$allowed_query_keys = $wp->public_query_vars;
				}
				$allowed_query_keys = "'" . implode( "','", $allowed_query_keys ) . "'";

				if ( is_multisite() ) {
					$sql = "
SELECT	`blog_id`, `domain`, `path`
FROM	`{$wpdb->blogs}`
WHERE	`public` = 1
AND		`spam` = 0
AND		`deleted` = 0
ORDER BY `blog_id` ASC";
					$blogs = $wpdb->get_results( $sql );
					$sites_array = '';

					if ( is_subdomain_install() ) {
						$site_mode = "'domain'";
						$property = 'domain';
					} else {
						$site_mode = "'directory'";
						$property = 'path';
					}
					if ( $blogs ) {
						foreach ( $blogs as $blog ) {
							$sites_array .= "\t\t'" . $blog->$property . "' => '" . $blog->blog_id . "',\n";
						}
					}
					if ( file_exists( $this->regex_include_tpl ) && is_readable( $this->regex_include_tpl ) ) {
						$regex_include_file = WP_CONTENT_DIR . '/regex-include-' . get_current_blog_id() . '.php';
						$regex_include_data = file_get_contents( $this->regex_include_tpl );
						$replaces = array(
							'### DEVICE REGEX ###'            => $device_regexes,
							'### QUERY KEYS ###'              => $allowed_query_keys,
							'### THEME SWITCHER DISABLED ###' => $theme_switcher_disabled,
						);
						$regex_include_data = str_replace( array_keys( $replaces ), $replaces, $regex_include_data );
						@file_put_contents( $regex_include_file, $regex_include_data );
						$regex_include = "
		\$regex_include_file = dirname( __FILE__ ) . '/regex-include-' . \$site_id . '.php';
		if ( file_exists( \$regex_include_file ) ) {
			include( \$regex_include_file );
		} else {
			return;
		}
";
					}

					$device_regexes = '';
					$allowed_query_keys = '';
					$theme_switcher_disabled = 'true';
				} else {
					$site_mode = 'false';
					$sites_array = '';
					$regex_include = '';
					$allowed_query_keys = '$this->allowed_query_keys = array( ' . $allowed_query_keys . ' );';
				}

				$this->generate_replace_class_file();

				$replaces = array(
					'### DEVICE REGEX ###'            => $device_regexes,
					'### SITES ARRAY ###'             => $sites_array,
					'### SITE MODE ###'               => $site_mode,
					'### REGEX INCLUDE ###'           => $regex_include,
					'### QUERY KEYS ###'              => $allowed_query_keys,
					'### THEME SWITCHER DISABLED ###' => $theme_switcher_disabled,
				);
				$advanced_cache_data = str_replace( array_keys( $replaces ), $replaces, $advanced_cache_data );

				@file_put_contents( $advanced_cache_file, $advanced_cache_data );
			}
		}
	}


	public function generate_replace_class_file() {
		$replace_class_file  = WP_CONTENT_DIR . '/replace-class.php';
		$life_time = get_option( 'site_cache_life', array( 'home' => 60, 'archive' => 60, 'singular' => 360, 'exclude' => '', 'allowed_query_keys' => '', 'update' => 'none', 'replaces' => array(), 'replace_login' => 0 ) );

		$replace_array = '';
		if ( isset( $life_time['replaces'] ) && is_array( $life_time['replaces'] ) ) {
			foreach ( $life_time['replaces'] as $key => $values ) {
				$replace_array .= "'" . wp_slash( $values['target'] ) . "' => '" . wp_slash( $values['replace'] ) . "',\n";
			}
		}

		if ( is_multisite() && 1 != get_current_blog_id() ) {
			$replace_class_file = WP_CONTENT_DIR . '/replace-class-' . get_current_blog_id() . '.php';
		}

		$replace_login = $life_time['replace_login'] ? 1 : 0;
		$replace_class_data = file_get_contents( $this->replace_tpl );
		$replace_class_data = str_replace( array( '### REPLACES ARRAY ###', '### REPLACES LOGIN ###' ), array( $replace_array, $replace_login ), $replace_class_data );
		@file_put_contents( $replace_class_file, $replace_class_data );
	}

} // class end
$this->modules['page-cache'] = new KUSANAGI_Page_Cache;

function kusanagi_write_page_cache( $buffer ) {

if ( defined( 'WP_CACHE' ) && true == WP_CACHE ) {

	global $WP_KUSANAGI, $cache_db, $wp;

	foreach ( array_keys( $_COOKIE ) as $key ) {
		if ( strpos( $key, 'comment_author_' ) === 0 ) {
			return $buffer;
		}
	}

	if ( $_SERVER['REQUEST_METHOD'] == 'GET' && ! is_404() && ! is_search() && ! is_user_logged_in() && ! is_admin() && preg_match( '#/index\.php$#', $_SERVER['SCRIPT_NAME'] )  && ! isset( $GLOBALS['http_response_code'] ) ) {
		$life_time = get_option( 'site_cache_life', array( 'home' => 60, 'archive' => 60, 'singular' => 360, 'exclude' => '', 'allowed_query_keys' => '', 'update' => 'none', 'replaces' => array(), 'replace_login' => 0 ) );

		if ( $life_time['exclude'] ) {
			$rules = explode( "\n", $life_time['exclude'] );
			$regex = array();
			foreach ( $rules as $rule ) {
				$regex[] = str_replace( '/', '\/', trim( $rule ) );
			}
			$regex = '/' . implode( '|', $regex ) . '/';
			if ( preg_match( $regex, $_SERVER['REQUEST_URI'] ) ) {
				header( 'X-B-Cache: excluded' );
				return $buffer;
			}
		}


		$ua = $_SERVER['HTTP_USER_AGENT'];
		$regexes = get_option( 'sitemanager_device_rules', array() );

		$group = '';
		foreach ( $regexes as $current_group => $arr ) {
			if ( isset( $_GET['site-view'] ) && strtolower( $_GET['site-view'] ) == strtolower( $_GET['site-view'] ) ) {
				$group = $current_group;
				break;
			} elseif ( isset( $_COOKIE['site-view'] ) && strtolower( $_COOKIE['site-view'] ) == strtolower( $_COOKIE['site-view'] ) ) {
				$group = $current_group;
				break;
			}
			$regex = '/' . implode( '|', $arr['regex'] ) . '/';
			if ( preg_match( $regex, $ua ) ) {
				$group = $current_group;
				break;
			}
		}

		if ( isset( $_GET['site-view'] ) ) {
			if ( strtolower( $_GET['site-view'] ) == 'pc' ) {
				$group = '';
			}
			foreach ( $regexes as $current_group => $arr ) {
				if ( strtolower( $_GET['site-view'] ) == strtolower( $current_group ) ) {
					$group = $current_group;
					break;
				}
			}
		} elseif ( isset( $_COOKIE['site-view'] ) ) {
			if ( strtolower( $_COOKIE['site-view'] ) == 'pc' ) {
				$group = '';
			}
			foreach ( $regexes as $current_group => $arr ) {
				if ( strtolower( $_COOKIE['site-view'] ) == strtolower( $current_group ) ) {
					$group = $current_group;
					break;
				}
			}
		}
		$requerst_query = '';

		if ( ( isset( $_SERVER['HTTPS'] ) && $_SERVER['HTTPS'] == 'on' ) || ( isset( $_SERVER['X-Forwarded-Proto'] ) && $_SERVER['X-Forwarded-Proto'] == 'https' ) ) {
			$protocol = 'https';
		} else {
			$protocol = 'http';
		}
		$request_uri = parse_url( $_SERVER['REQUEST_URI'] );
		if ( isset( $request_uri['query'] ) ) {
			parse_str( $request_uri['query'], $requerst_query );

			$allowed_query_keys = trim( $life_time['allowed_query_keys'] );
			$allowed_query_keys = preg_split( '/[\s]+/', $allowed_query_keys );

			foreach ( $requerst_query as $key => $var ) {
				if ( ! in_array( $key, array_unique( array_merge( $wp->public_query_vars, $allowed_query_keys ) ) ) ) {
					unset( $requerst_query[$key] );
				}
			}
			ksort( $requerst_query );
			$requerst_query = http_build_query( $requerst_query );
		}

		$request_uri = $request_uri['path'];
		if ( $requerst_query ) {
			$request_uri .= '?' . $requerst_query;
		}

		$device_url = array(
			$group,
			$protocol,
			$_SERVER['SERVER_NAME'],
			$request_uri
		);
		$device_url = implode( '|', $device_url );
		$hash = md5( $device_url );
		$sql = "
SELECT	*
FROM	{$cache_db->prefix}site_cache
WHERE	`hash` = '$hash'
";
		$row = false;
		$rows = $cache_db->get_results( $sql );
		if ( $rows ) {
			foreach ( $rows as $r ) {
				if ( $r->device_url == $device_url ) {
					$row = $r;
					break;
				}
			}
		}

		if ( is_front_page() ) {
			$type = 'front';
			$post_type = 'page';
			$life_time_key = 'home';
		} elseif ( is_singular() ) {
			$type = 'single';
			if ( is_single() ) {
				$post_type = 'post';
			} elseif ( is_page() ) {
				$post_type = 'page';
			} else {
				$post_type = get_query_var( 'post_type' );
			}
			$life_time_key = 'singular';
		} elseif ( is_category() ) {
			$type = 'taxonomy';
			$post_type = 'category'. '|' . get_query_var( 'category_name' );
			$life_time_key = 'archive';
		} elseif ( is_tag() ) {
			$type = 'taxonomy';
			$post_type = 'post_tag'. '|' . get_query_var( 'tag_name' );
			$life_time_key = 'archive';
		} elseif ( is_tax() ) {
			$type = 'taxonomy';
			$post_type = get_query_var( 'taxonomy' ) . '|' . get_query_var( 'term' );
			$life_time_key = 'archive';
		} elseif ( is_date() ) {
			$type = 'date';
			if ( get_query_var( 'post_type' ) ) {
				$post_type = get_query_var( 'post_type' );
			} else {
				$post_type = 'post';
			}
			$life_time_key = 'archive';
		} elseif ( is_post_type_archive() ) {
			$type = 'post_type_archive';
			$post_type = get_query_var( 'post_type' );
			$life_time_key = 'archive';
		} elseif ( is_author() ) {
			$type = 'author';
			if ( get_query_var( 'post_type' ) ) {
				$post_type = get_query_var( 'post_type' );
			} else {
				$post_type = 'post';
			}
			$life_time_key = 'archive';
		} elseif ( is_home() ) {
			$type = 'home';
			$post_type = 'post';
			$life_time_key = 'home';
		} elseif ( is_single() ) {
			$post_type = 'post';
			$type = 'single';
			$life_time_key = 'singular';
		} elseif ( defined( 'REST_REQUEST' ) && REST_REQUEST ) {
			$type = 'rest_api';
			$post_type = 'rest_api';
			$life_time_key = 'archive';
		} else {
			header( 'X-B-Cache: none' );
			return $buffer;
		}

		header( 'X-B-Cache: create' );
		$header_arr = array();
		$headers = headers_list();
		foreach ( $headers as $header ) {
			list( $key, $val ) = explode( ': ', $header, 2 );
			if ( 'location' == strtolower( $key ) ) {
				return $buffer;
			}
			if ( $key == 'Vary' && strpos( $val, 'Cookie' ) === false ) {
				$val .= ',Cookie';
			}
			if ( $key != 'Set-Cookie' ) {
				$header_arr[$key] = $val;
			}
		}

		$expire = apply_filters( 'site_cache_expire_time', $life_time[$life_time_key] * 60, $life_time_key );
		if ( defined( 'REST_REQUEST' ) && REST_REQUEST ) {
			$cache = $buffer;
			$cache = json_decode( $cache, true );
//			$cache['x-cached'] = '<!-- page cached by WP SiteManager. ' . date( 'H:i:s' ) . '(GMT). Expire : ' . date( 'H:i:s', time() + $expire ) . '(GMT). -->';
			add_x_cache_key( $cache, $expire );
			$cache = json_encode( $cache );
		} else {
			$cache = $buffer . "\n" . '<!-- page cached by KUSANAGI. Cache created : ' . date( 'H:i:s' ) . '(GMT). Expire : ' . date( 'H:i:s', time() + $expire ) . '(GMT). -->';
		}

		$server = defined( 'CACHE_SERVER' ) ? CACHE_SERVER : '';
		$data = array(
			'hash'        => $hash,
			'content'     => $cache,
			'device_url'  => $device_url,
			'type'        => $type,
			'post_type'   => $post_type,
			'headers'     => serialize( $header_arr ),
			'user_agent'  => $_SERVER['HTTP_USER_AGENT'],
			'server'      => $server,
			'updating'    => 0,
			'create_time' => date( 'Y-m-d H:i:s' ),
			'expire_time' => date( 'Y-m-d H:i:s', time() + $expire ),
		);

		if ( ! $row ) {
			$cache_db->insert( $cache_db->prefix . 'site_cache', $data, array( '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%d', '%s', '%s' ) );
		} elseif ( $row->expire_time < date( 'Y-m-d H:i:s' ) ) {
			$cache_db->update( $cache_db->prefix . 'site_cache', $data, array( 'hash' => $hash, 'type' => $type, 'expire_time' => $row->expire_time ), array( '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%d', '%s', '%s' ), array( '%s', '%s', '%s' ) );
		} elseif ( strpos( $row->content, '<!-- page cached by KUSANAGI. ' ) === false || strpos( $row->content, '<!-- page cached by WP SiteManager. ' ) === false ) {
			$cache_db->update( $cache_db->prefix . 'site_cache', $data, array( 'hash' => $hash, 'type' => $type, 'expire_time' => $row->expire_time ), array( '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%d', '%s', '%s' ), array( '%s', '%s', '%s' ) );
		}
	}

} // WP_CACHE endif

	$replace_class_file  = WP_CONTENT_DIR . '/replace-class.php';
	if ( is_multisite() && 1 != get_current_blog_id() ) {
		$replace_class_file = WP_CONTENT_DIR . '/replace-class-' . get_current_blog_id() . '.php';
	}
	if ( file_exists( $replace_class_file ) ) {

		include_once( $replace_class_file);
		$buffer = KUSANAGI_Replace::replace( $buffer );
	}
	return $buffer;
}


function add_x_cache_key( &$array, $expire ) {
	if ( is_array( $array ) ) {
		foreach ( $array as $key => $val ) {
			if ( ! is_numeric( $key ) ) {
				$array['x_cached'] = '<!-- page cached by WP SiteManager. ' . date( 'H:i:s' ) . '(GMT). Expire : ' . date( 'H:i:s', time() + $expire ) . '(GMT). -->';
				return true;
			} else {
				$ret = add_x_cache_key( $array[$key], $expire );
				if ( $ret ) {
					return true;
				}
			}
		}
	} elseif ( is_object( $array ) ) {
		foreach ( $array as $key => $val ) {
			if ( ! is_numeric( $key ) ) {
				$array->x_cached = '<!-- page cached by WP SiteManager. ' . date( 'H:i:s' ) . '(GMT). Expire : ' . date( 'H:i:s', time() + $expire ) . '(GMT). -->';
				return true;
			} else {
				$ret = add_x_cache_key( $array->$key, $expire );
				if ( $ret ) {
					return true;
				}
			}
		}
	}
	return false;
}
