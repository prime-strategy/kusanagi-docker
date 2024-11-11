<?php

if ( ! defined( 'KUSANAGI_WP_CLEAN_ACTION' ) ) {
	define( 'KUSANAGI_WP_CLEAN_ACTION', 'kusanagi-cache-clear' );
}
if ( ! defined( 'KUSANAGI_WP_CLEAN_NAME' ) ) {
	define( 'KUSANAGI_WP_CLEAN_NAME', 'kusanagi-cache-clear' );
}

/**
 *  class
 */
class KUSANAGI_Theme_Accelerator_Logic {
	// apcu instance
	public static $ApcuInstance;

	public static $RequestUri;

	public static $SiteUri;

	public static $OptionKey;

	public static $render_cache_key = array(
		'core/navigation-link',
		'core/navigation-submenu',
		'core/site-logo',
		'core/site-title',
		'core/rss',
		'core/page-list',
	);

	public static $render_cache_key_need_post_id = array(
		'core/post-date',
		'core/post-title',
		'core/post-terms',
		'core/list-item',
		'core/post-author',
		'core/read-more',
		'core/read-navigation-link',
	);

	const HOOKSEQ1     = -30000000;
	const HOOKSEQ2     = -20000000;
	const HOOKSEQ3     = -10000000;
	const HOOKSEQ_LAST = 10000000;

	public function __construct() {
		if ( ! defined( 'PHP_INT_MAX' ) ) {
			define( 'PHP_INT_MAX', 214748364 );
		}
		if ( ! defined( 'PHP_INT_MIN' ) ) {
			define( 'PHP_INT_MIN', -214748364 );
		}
		// No direct access
		if ( ! function_exists( 'add_action' ) ) {
			http_response_code( 404 );
			exit;
		}
		// plugin dir
		if ( ! defined( 'THIS_PLUGIN_DIR' ) ) {
			define( 'THIS_PLUGIN_DIR', __DIR__ );
		}

		//apcu enable
		if ( ! function_exists( 'apcu_enabled' ) ) {
			return;
		}
		require_once THIS_PLUGIN_DIR . '/class-cache-apcu.php';
		// clear cache
		add_action( 'wp_ajax_clear_cache', array( 'KUSANAGI_Theme_Accelerator_Logic', 'wp_ajax_clear_cache' ) );
		//プラグインダウンロード・アップグレードツールの動作が終了した際に実行する。
		add_action( 'upgrader_process_complete', array( 'KUSANAGI_Theme_Accelerator_Logic', 'clear_cache' ) );
		//プラグインの無効化に成功した際に実行する。
		add_action( 'deactivated_plugin', array( 'KUSANAGI_Theme_Accelerator_Logic', 'clear_cache' ) );
		//プラグインの有効化に成功した際に実行する。
		add_action( 'activate_plugin', array( 'KUSANAGI_Theme_Accelerator_Logic', 'clear_cache' ) );
		//ブログのテーマが変更された際に実行する。
		// phpcs:ignore PHPCompatibility.Constants.NewConstants.php_int_minFound
		add_action( 'switch_theme', array( 'KUSANAGI_Theme_Accelerator_Logic', 'clear_cache' ), PHP_INT_MIN );

		// phpcs:ignore PHPCompatibility.Constants.NewConstants.php_int_minFound
		add_action( 'after_switch_theme', array( 'KUSANAGI_Theme_Accelerator_Logic', 'clear_cache' ), PHP_INT_MIN );
		//update_nav_menu
		add_action( 'wp_update_nav_menu', array( 'KUSANAGI_Theme_Accelerator_Logic', 'clear_cache' ) );
		// wp_posts,input update
		add_action( 'save_post', array( 'KUSANAGI_Theme_Accelerator_Logic', 'clear_cache' ) );

		self::theme_accelerator_start();
	}

	public static function ob_init( $data ) {
		//nothing do、関数名が役割を果たす
		return $data;
	}

	// logic start
	public static function theme_accelerator_start() {
		$url_array        = wp_parse_url( site_url() );
		self::$SiteUri    = isset( $url_array['host'] ) ? $url_array['host'] : '';
		self::$RequestUri = $_SERVER['REQUEST_URI'] . '_' . self::$SiteUri;

		if ( empty( apcu_enabled() ) ) {
			return;
		}

		// not admin page
		if ( is_admin() ) {
			return;
		}
		//installed
		$speed_option = get_option( 'kusanagi-opt-speed-up' );
		if ( empty( $speed_option['enable'] ) ) {
			return;
		}
		self::$ApcuInstance = new KUSANAGI_Cache_Apcu();
		$have_apcu          = self::$ApcuInstance->available();
		if ( ! $have_apcu ) {
			return;
		}
		if (
			! isset( $_SERVER['REQUEST_URI'] ) ||
			! isset( $_SERVER['HTTP_USER_AGENT'] ) ||
			! isset( $_SERVER['REQUEST_METHOD'] ) ||
			! isset( $_SERVER['SCRIPT_NAME'] ) ||
			! isset( $_SERVER['SERVER_NAME'] )
		) {
			return;
		}
		if ( 'GET' !== $_SERVER['REQUEST_METHOD'] ) {
			return;
		}

		// not 200 no cache
		if ( function_exists( 'http_response_code' ) && 200 !== http_response_code() ) {
			return;
		}

		//fse theme 高速化
		if ( self::is_block_templates() ) {
			self::fse_templates_cache();
		}

		$has_cache = self::$ApcuInstance->get( 'need_cache' . self::$SiteUri );
		add_action(
			'init',
			function () {
				ob_start( array( self::class, 'ob_init' ) );
			},
			self::HOOKSEQ_LAST
		);

		add_action( 'plugins_loaded', array( self::class, 'wp_ajax_clear_cache' ), -1 );
		add_action(
			'shutdown',
			function () use ( &$has_cache ) {
				global $wp_filter;
				if ( empty( $has_cache ) ) {
					$need_cache = array();
					foreach ( $wp_filter as $key => $value ) {
						if ( false !== strpos( $key, 'footer' ) && false === strpos( $key, 'admin' ) ) {
							$need_cache[] = $key;
						}
						if ( false !== strpos( $key, 'header' ) && false === strpos( $key, 'admin' ) ) {
							$need_cache[] = $key;
						}

						self::$ApcuInstance->set( 'need_cache' . self::$SiteUri, $need_cache );
					}
				}
			}
		);

		add_action( 'wp_head', array( self::class, 'theme_accelerator_first' ), self::HOOKSEQ3 );
		add_action( 'wp_head', array( self::class, 'theme_accelerator_end' ), self::HOOKSEQ_LAST );
		add_action( 'generate_before_footer', array( self::class, 'theme_accelerator_first' ), self::HOOKSEQ3 );
		add_action( 'generate_before_footer', array( self::class, 'theme_accelerator_end' ), self::HOOKSEQ_LAST );

		if ( ! empty( $has_cache ) ) {
			foreach ( $has_cache as $key => $value ) {
				//  pluginに対してキャシューしない
				if ( 'extra_plugin_headers' === $value ) {
					continue;
				}
				add_action( $value, array( self::class, 'theme_accelerator_first' ), self::HOOKSEQ3 );
				add_action( $value, array( self::class, 'theme_accelerator_end' ), self::HOOKSEQ_LAST );
			}
		}

		add_action( 'wp_head', array( self::class, 'head_not_cache' ), self::HOOKSEQ1 );
	}

	public static function theme_accelerator_first() {
		$current_action = current_action();
		$cacheData      = self::$ApcuInstance->get( $current_action . self::$RequestUri );
		//rss no cache
		if ( ! empty( $cacheData ) && 'generate_footer' !== $current_action ) {
			remove_all_filters( $current_action );
			// phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
			echo $cacheData;
		} else {
			$all_ob = ob_list_handlers();
			if ( false !== strpos( $all_ob[ count( $all_ob ) - 1 ], 'ob_init' ) ) {
				ob_start(
					function ( $data ) use ( &$current_action ) {
						self::$ApcuInstance->set( $current_action . self::$RequestUri, $data );

						return $data;
					}
				);
			} else {
				remove_filter( $current_action, array( self::class, 'theme_accelerator_end' ), self::HOOKSEQ_LAST );
			}
		}
	}

	public static function theme_accelerator_end() {
		ob_end_flush();
	}

	/**
	 * clear cache
	 * @return void
	 */
	public static function wp_ajax_clear_cache() {
		if ( self::is_valid_access() ) {
			return self::$ApcuInstance->flush();
		}
	}

	public static function is_valid_access() {
		return isset( $_GET[ KUSANAGI_WP_CLEAN_NAME ] ) && wp_verify_nonce( sanitize_text_field( $_GET[ KUSANAGI_WP_CLEAN_NAME ] ), KUSANAGI_WP_CLEAN_ACTION );
	}

	public static function head_not_cache() {
		global $wp_filter;
		foreach ( $wp_filter['wp_head']->callbacks as $key => $val ) {
			foreach ( $val as $key2 => $value2 ) {
				if ( false !== strpos( $key2, 'styles' ) || false !== strpos( $key2, 'scripts' ) || false !== strpos( $key2, 'admin' ) ) {
					$wp_filter['wp_head']->callbacks[ self::HOOKSEQ2 ][ $key2 ] = $value2;
					unset( $wp_filter['wp_head']->callbacks[ $key ][ $key2 ] );
				}
			}
		}
		ksort( $wp_filter['wp_head']->callbacks, SORT_NUMERIC );
		remove_action( 'wp_head', array( self::class, 'head_not_cache' ), self::HOOKSEQ1 );
	}

	public static function clear_cache() {
		if ( empty( self::$ApcuInstance ) ) {
			self::$ApcuInstance = new KUSANAGI_Cache_Apcu();
		}

		return self::$ApcuInstance->flush();
	}

	public static function fse_templates_cache() {
		add_filter(
			'pre_get_block_templates',
			function ( $a, $b, $c ) {
				$cache_key = '';
				$result    = array();
				if ( ! empty( $b ) ) {
					array_walk_recursive(
						$b,
						function ( $v, $key ) use ( &$result ) {
							$result[] = $key . $v;
						}
					);
					$cache_key = http_build_query( $result, '', '____' );
				}
				$cache_key = $c . $cache_key;
				$cache     = self::$ApcuInstance->get( KUSANAGI_Theme_Accelerator_Logic::$SiteUri . 'get_block_templates' . $cache_key );
				if ( ! empty( $cache ) ) {
					return $cache;
				}

				return null;
			},
			10,
			3
		);

		add_filter(
			'get_block_templates',
			function ( $a, $b, $c ) {
				$cache_key = '';
				$result    = array();
				if ( ! empty( $b ) ) {
					array_walk_recursive(
						$b,
						function ( $v, $key ) use ( &$result ) {
							$result[] = $key . $v;
						}
					);
					$cache_key = http_build_query( $result, '', '____' );
				}
				$cache_key = $c . $cache_key;
				$cache     = self::$ApcuInstance->set( KUSANAGI_Theme_Accelerator_Logic::$SiteUri . 'get_block_templates' . $cache_key, $a );

				return $a;
			},
			PHP_INT_MAX,
			3
		);

		add_filter(
			'pre_get_block_template',
			function ( $a, $b, $c ) {
				$cache_key = '';
				$result    = array();
				if ( ! empty( $b ) ) {
					array_walk_recursive(
						$b,
						function ( $v, $key ) use ( &$result ) {
							$result[] = $key . $v;
						}
					);
					$cache_key = http_build_query( $result, '', '____' );
				}
				$cache_key = $c . $cache_key;
				$cache     = self::$ApcuInstance->get( KUSANAGI_Theme_Accelerator_Logic::$SiteUri . 'get_block_template' . $cache_key . $cache_key );
				if ( ! empty( $cache ) ) {
					return $cache;
				}

				return null;
			},
			10,
			3
		);

		add_filter(
			'get_block_template',
			function ( $a, $b, $c ) {
				$cache_key = '';
				$result    = array();
				if ( ! empty( $b ) ) {
					array_walk_recursive(
						$b,
						function ( $v, $key ) use ( &$result ) {
							$result[] = $key . $v;
						}
					);
					$cache_key = http_build_query( $result, '', '____' );
				}
				$cache_key = $c . $cache_key;
				$cache     = self::$ApcuInstance->set( KUSANAGI_Theme_Accelerator_Logic::$SiteUri . 'get_block_template' . $cache_key . $cache_key, $a );

				return $a;
			},
			PHP_INT_MAX,
			3
		);

		//render部分
		add_filter(
			'pre_render_block',
			function ( $a, $b, $father ) {
				global $post;
				if ( empty( $father ) ) {
					return null;
				}
				if ( ! in_array( $b['blockName'], self::$render_cache_key, true ) && ! in_array( $b['blockName'], self::$render_cache_key_need_post_id, true ) ) {
					return null;
				}
				if ( in_array( $b['blockName'], self::$render_cache_key_need_post_id, true ) ) {
					$context['postId']   = $post->ID;
					$context['postType'] = $post->post_type;
				}

				$attributes = array();
				if ( isset( $b['attrs'] ) ) {
					$attributes = $b['attrs'];
				}
				if ( 'core/site-logo' === $b['blockName'] ) {
					//bug tame
					if ( empty( $attributes['width'] ) ) {
						return null;
					}
				}
				$cache_key = '';
				$result    = array();
				if ( ! empty( $attributes ) ) {
					array_walk_recursive(
						$attributes,
						function ( $v, $key ) use ( &$result ) {
							$result[] = $key . $v;
						}
					);
					$cache_key = http_build_query( $result, '', '____' );
				}

				if ( ! empty( $context['postId'] ) ) {
					array_walk_recursive(
						$context,
						function ( $v, $key ) use ( &$result ) {
							if ( 'postId' === $key || 'postType' === $key ) {
								$result[] = $key . $v;
							}
						}
					);
					$cache_key = $cache_key . http_build_query( $result, '', '____' );
				}
				$cache = self::$ApcuInstance->get( KUSANAGI_Theme_Accelerator_Logic::$SiteUri . $b['blockName'] . $cache_key );
				if ( ! empty( $cache ) ) {
					return $cache;
				}

				return null;
			},
			PHP_INT_MAX,
			3
		);

		add_filter(
			'render_block',
			function ( $a, $b ) {
				global $post;
				if ( ! in_array( $b['blockName'], self::$render_cache_key, true ) && ! in_array( $b['blockName'], self::$render_cache_key_need_post_id, true ) ) {
					return $a;
				}
				if ( in_array( $b['blockName'], self::$render_cache_key_need_post_id, true ) ) {
					$context['postId']   = $post->ID;
					$context['postType'] = $post->post_type;
				}

				$attributes = array();
				if ( isset( $b['attrs'] ) ) {
					$attributes = $b['attrs'];
				}
				$cache_key = '';
				$result    = array();
				if ( ! empty( $attributes ) ) {
					array_walk_recursive(
						$attributes,
						function ( $v, $key ) use ( &$result ) {
							$result[] = $key . $v;
						}
					);
					$cache_key = http_build_query( $result, '', '____' );
				}
				if ( ! empty( $context['postId'] ) ) {
					array_walk_recursive(
						$context,
						function ( $v, $key ) use ( &$result ) {
							if ( 'postId' === $key || 'postType' === $key ) {
								$result[] = $key . $v;
							}
						}
					);
					$cache_key = $cache_key . http_build_query( $result, '', '____' );
				}

				$cache = self::$ApcuInstance->set( KUSANAGI_Theme_Accelerator_Logic::$SiteUri . $b['blockName'] . $cache_key, $a );

				return $a;
			},
			PHP_INT_MAX,
			3
		);
	}

	public static function is_block_templates() {
		if ( ! function_exists( 'wp_is_block_theme' ) || ! function_exists( 'wp_theme_has_theme_json' ) ) {
			return false;
		}
		if ( wp_is_block_theme() || wp_theme_has_theme_json() ) {
			return true;
		}

		return false;
	}
}

$this->modules['theme_accelerator'] = new KUSANAGI_Theme_Accelerator_Logic();
